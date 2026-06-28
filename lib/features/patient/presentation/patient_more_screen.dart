import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../chat/presentation/providers/chat_providers.dart';

class PatientMoreScreen extends ConsumerWidget {
  const PatientMoreScreen({super.key});

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
                  subtitle: const Text('View and update your information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/patient/profile'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Notifications'),
                  subtitle: const Text('Read care and appointment updates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/patient/notifications'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Chat'),
                  subtitle: const Text('Message your doctors securely'),
                  trailing: _ChatTrailing(unread: chatUnread),
                  onTap: () => context.push('/chat'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: const Text('Test Results'),
                  subtitle: const Text('Lab, imaging, and document results'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/patient/test-results'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: const Text('AI Assistant'),
                  subtitle: const Text('Personal health assistant'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/patient/coming-soon/assistant'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.document_scanner_outlined),
                  title: const Text('OCR'),
                  subtitle: const Text('Medical document extraction'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/patient/coming-soon/ocr'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.biotech_outlined),
                  title: const Text('Kidney Stone Analysis'),
                  subtitle: const Text('AI image analysis placeholder'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/patient/coming-soon/kidney-stone'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Disease Prediction'),
                  subtitle: const Text('Predictive models placeholder'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/patient/coming-soon/prediction'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
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
