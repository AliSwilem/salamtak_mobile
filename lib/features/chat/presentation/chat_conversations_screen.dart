import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/chat_models.dart';
import 'chat_text_direction.dart';
import 'providers/chat_providers.dart';

class ChatConversationsScreen extends ConsumerStatefulWidget {
  const ChatConversationsScreen({super.key});

  @override
  ConsumerState<ChatConversationsScreen> createState() =>
      _ChatConversationsScreenState();
}

class _ChatConversationsScreenState
    extends ConsumerState<ChatConversationsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authControllerProvider).role;
    final conversations = ref.watch(chatConversationsProvider);
    final searchResults = ref.watch(chatSearchProvider(_query));
    final isDoctor = role == 'doctor';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _leaveChat(context, role),
        ),
        title: const Text('Chat'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(chatConversationsProvider);
          await ref.read(chatConversationsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SearchCard(
              controller: _searchController,
              hint: isDoctor ? 'Search patients' : 'Search doctors',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            if (_query.trim().isNotEmpty) ...[
              Text(
                isDoctor ? 'Start a patient chat' : 'Start a doctor chat',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              searchResults.when(
                loading: () => const _LoadingCard(message: 'Searching...'),
                error: (error, _) => _ErrorCard(
                  message: _friendlyError(error),
                  onRetry: () => ref.invalidate(chatSearchProvider(_query)),
                ),
                data: (results) => _SearchResults(
                  results: results,
                  onStart: _startConversation,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Conversations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            conversations.when(
              loading: () =>
                  const _LoadingCard(message: 'Loading conversations...'),
              error: (error, _) => _ErrorCard(
                message: _friendlyError(error),
                onRetry: () => ref.invalidate(chatConversationsProvider),
              ),
              data: (items) => _ConversationList(
                conversations: items,
                role: role,
                onOpen: _openConversation,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startConversation(ChatSearchResultModel result) async {
    final role = ref.read(authControllerProvider).role;
    final conversation = await ref
        .read(chatActionProvider.notifier)
        .startConversation(
          patientId: role == 'doctor' ? result.id : null,
          doctorId: role == 'patient' ? result.id : null,
        );

    if (!mounted) return;
    final error = ref.read(chatActionProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      return;
    }
    if (conversation != null) {
      await _openConversation(conversation);
    }
  }

  Future<void> _openConversation(ChatConversationModel conversation) async {
    await context.push('/chat/${conversation.id}', extra: conversation);
    if (!mounted) return;
    ref.invalidate(chatConversationsProvider);
  }
}

class _SearchCard extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchCard({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: const Icon(Icons.search),
            hintText: hint,
          ),
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<ChatSearchResultModel> results;
  final ValueChanged<ChatSearchResultModel> onStart;

  const _SearchResults({required this.results, required this.onStart});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const _EmptyCard(
        icon: Icons.person_search_outlined,
        title: 'No matches found',
        message: 'You can only chat with contacts linked to appointments.',
      );
    }

    return Card(
      child: Column(
        children: [
          for (final result in results) ...[
            ListTile(
              leading: CircleAvatar(child: Text(_initials(result.fullName))),
              title: Text(result.fullName),
              subtitle: result.specialization == null
                  ? null
                  : Directionality(
                      textDirection: textDirectionFor(result.specialization!),
                      child: Text(
                        result.specialization!,
                        textAlign: textAlignFor(result.specialization!),
                      ),
                    ),
              trailing: const Icon(Icons.chat_bubble_outline),
              onTap: () => onStart(result),
            ),
            if (result != results.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  final List<ChatConversationModel> conversations;
  final String? role;
  final Future<void> Function(ChatConversationModel conversation) onOpen;

  const _ConversationList({
    required this.conversations,
    required this.role,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return const _EmptyCard(
        icon: Icons.forum_outlined,
        title: 'No conversations yet',
        message: 'Search a linked doctor or patient to start chatting.',
      );
    }

    return Card(
      child: Column(
        children: [
          for (final conversation in conversations) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(_initials(conversation.titleForRole(role))),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Directionality(
                      textDirection: textDirectionFor(
                        conversation.titleForRole(role),
                      ),
                      child: Text(
                        conversation.titleForRole(role),
                        textAlign: textAlignFor(
                          conversation.titleForRole(role),
                        ),
                      ),
                    ),
                  ),
                  if (conversation.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${conversation.unreadCount}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Directionality(
                textDirection: textDirectionFor(
                  conversation.subtitleForRole(role),
                ),
                child: Text(
                  conversation.subtitleForRole(role),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: textAlignFor(conversation.subtitleForRole(role)),
                ),
              ),
              trailing: Text(
                _formatTime(
                  conversation.lastMessageAt ?? conversation.createdAt,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () {
                onOpen(conversation);
              },
            ),
            if (conversation != conversations.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String message;

  const _LoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _formatTime(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day} $hour:$minute';
}

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('403')) {
    return 'Chat is only available for linked doctor-patient appointments.';
  }
  if (text.contains('401')) {
    return 'Your session expired. Please log in again.';
  }
  return 'We could not load chat right now. Please try again.';
}

void _leaveChat(BuildContext context, String? role) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  context.go(role == 'doctor' ? '/doctor/more' : '/patient/more');
}
