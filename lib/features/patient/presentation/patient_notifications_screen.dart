import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/patient_notification_model.dart';
import 'providers/patient_providers.dart';

enum _NotificationFilter { all, unread, read }

class PatientNotificationsScreen extends ConsumerStatefulWidget {
  const PatientNotificationsScreen({super.key});

  @override
  ConsumerState<PatientNotificationsScreen> createState() =>
      _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState
    extends ConsumerState<PatientNotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(patientNotificationsProvider);
    final unread = ref.watch(patientUnreadNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(child: Badge(label: Text('$unread'))),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SegmentedButton<_NotificationFilter>(
              segments: const [
                ButtonSegment(
                  value: _NotificationFilter.all,
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: _NotificationFilter.unread,
                  label: Text('Unread'),
                ),
                ButtonSegment(
                  value: _NotificationFilter.read,
                  label: Text('Read'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (value) {
                setState(() => _filter = value.first);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(patientNotificationsProvider);
                await ref.read(patientNotificationsProvider.future);
              },
              child: notifications.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _NotificationError(
                  onRetry: () => ref.invalidate(patientNotificationsProvider),
                ),
                data: (items) => _NotificationList(
                  notifications: _applyFilter(items),
                  filter: _filter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PatientFullNotificationModel> _applyFilter(
    List<PatientFullNotificationModel> items,
  ) {
    switch (_filter) {
      case _NotificationFilter.unread:
        return items.where((item) => !item.isRead).toList();
      case _NotificationFilter.read:
        return items.where((item) => item.isRead).toList();
      case _NotificationFilter.all:
        return items;
    }
  }
}

class _NotificationList extends StatelessWidget {
  final List<PatientFullNotificationModel> notifications;
  final _NotificationFilter filter;

  const _NotificationList({required this.notifications, required this.filter});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.notifications_none,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            switch (filter) {
              _NotificationFilter.unread => 'No unread notifications',
              _NotificationFilter.read => 'No read notifications',
              _NotificationFilter.all => 'No notifications yet',
            },
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Updates about appointments and your care journey will appear here.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemBuilder: (context, index) =>
          _NotificationCard(notification: notifications[index]),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: notifications.length,
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final PatientFullNotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(notificationActionProvider).isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: notification.isRead
          ? null
          : colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  notification.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.displayTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(notification.message),
                      const SizedBox(height: 8),
                      Text(
                        [
                          notification.displayFrom,
                          notification.dateCreated,
                        ].where((item) => item.trim().isNotEmpty).join(' • '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (!notification.isRead)
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => _markRead(context, ref, notification.id),
                    icon: const Icon(Icons.done),
                    label: const Text('Mark read'),
                  ),
                TextButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => _delete(context, ref, notification.id),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markRead(
    BuildContext context,
    WidgetRef ref,
    int notificationId,
  ) async {
    final ok = await ref
        .read(notificationActionProvider.notifier)
        .markRead(notificationId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Notification marked as read.'
              : 'Could not update notification.',
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    int notificationId,
  ) async {
    final ok = await ref
        .read(notificationActionProvider.notifier)
        .delete(notificationId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Notification deleted.' : 'Could not delete notification.',
        ),
      ),
    );
  }
}

class _NotificationError extends StatelessWidget {
  final VoidCallback onRetry;

  const _NotificationError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off_outlined, size: 56),
        const SizedBox(height: 12),
        const Text(
          'Notifications could not be loaded.',
          textAlign: TextAlign.center,
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
