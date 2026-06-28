import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../chat/presentation/providers/chat_providers.dart';

class DoctorMoreScreen extends ConsumerWidget {
  const DoctorMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatUnread = ref.watch(chatUnreadCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profile'),
                  subtitle: const Text(
                    'View and edit your public doctor profile.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/doctor/profile'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Chat'),
                  subtitle: const Text('Message your patients securely.'),
                  trailing: _ChatTrailing(unread: chatUnread),
                  onTap: () => context.push('/chat'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Logout'),
              subtitle: const Text('Sign out of this doctor session.'),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTrailing extends StatelessWidget {
  final AsyncValue<int> unread;

  const _ChatTrailing({required this.unread});

  @override
  Widget build(BuildContext context) {
    return unread.maybeWhen(
      data: (count) {
        if (count <= 0) return const Icon(Icons.chevron_right);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UnreadBadge(count: count),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        );
      },
      orElse: () => const Icon(Icons.chevron_right),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onError,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
