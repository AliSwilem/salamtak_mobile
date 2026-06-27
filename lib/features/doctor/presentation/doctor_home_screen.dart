import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/doctor_dashboard_model.dart';
import 'providers/doctor_providers.dart';

class DoctorHomeScreen extends ConsumerWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(doctorHomeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Home')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(doctorHomeProvider.future),
        child: home.when(
          loading: () => const _LoadingBody(),
          error: (error, _) => _ErrorBody(
            message: _friendlyError(error),
            onRetry: () => ref.invalidate(doctorHomeProvider),
          ),
          data: (data) => _DoctorHomeBody(data: data),
        ),
      ),
    );
  }
}

class _DoctorHomeBody extends StatelessWidget {
  final DoctorHomeData data;

  const _DoctorHomeBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final todayAppointments = data.todaySummary.appointments;
    final doctorName = data.doctorName.trim();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          doctorName.isEmpty ? 'Hello, Doctor' : 'Hello, Dr. $doctorName',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Here is your clinical overview for today.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _StatsGrid(stats: data.stats, todayCount: data.todaySummary.count),
        const SizedBox(height: 24),
        Text(
          'Today\'s appointments',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (todayAppointments.isEmpty)
          const _EmptyCard(
            icon: Icons.event_available_outlined,
            message: 'No appointments scheduled for today.',
          )
        else
          ...todayAppointments
              .take(3)
              .map((appointment) => _AppointmentCard(appointment: appointment)),
        const SizedBox(height: 24),
        Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (data.activity.isEmpty)
          const _EmptyCard(
            icon: Icons.notifications_none,
            message: 'No recent activity yet.',
          )
        else
          ...data.activity.take(3).map((activity) => _ActivityTile(activity)),
        const SizedBox(height: 24),
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _QuickAction(
              icon: Icons.calendar_month_outlined,
              label: 'Appointments',
              onTap: () => context.go('/doctor/appointments'),
            ),
            _QuickAction(
              icon: Icons.groups_outlined,
              label: 'Patients',
              onTap: () => context.go('/doctor/patients'),
            ),
            _QuickAction(
              icon: Icons.schedule_outlined,
              label: 'Availability',
              onTap: () => context.go('/doctor/availability'),
            ),
            _QuickAction(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => context.go('/doctor/profile'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DoctorStatsModel stats;
  final int todayCount;

  const _StatsGrid({required this.stats, required this.todayCount});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: Icons.today_outlined,
          label: 'Today',
          value: todayCount > 0 ? todayCount : stats.today,
        ),
        _StatCard(
          icon: Icons.check_circle_outline,
          label: 'Completed',
          value: stats.completed,
        ),
        _StatCard(
          icon: Icons.cancel_outlined,
          label: 'Cancelled',
          value: stats.cancelled,
        ),
        _StatCard(
          icon: Icons.person_off_outlined,
          label: 'No-show',
          value: stats.noShow,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final DoctorAppointmentPreview appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event_note_outlined)),
        title: Text(
          appointment.patientName.isEmpty
              ? 'Patient #${appointment.patientId ?? '-'}'
              : appointment.patientName,
        ),
        subtitle: Text(_joinParts([appointment.date, appointment.time])),
        trailing: Chip(
          label: Text(
            appointment.status.isEmpty ? 'scheduled' : appointment.status,
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final DoctorActivityModel activity;

  const _ActivityTile(this.activity);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          activity.isRead
              ? Icons.notifications_none
              : Icons.notifications_active_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(activity.title.isEmpty ? 'Activity' : activity.title),
        subtitle: Text(activity.message),
        trailing: activity.dateCreated.isEmpty
            ? null
            : Text(
                activity.dateCreated.split('T').first,
                style: Theme.of(context).textTheme.bodySmall,
              ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 260),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cloud_off_outlined, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}

String _friendlyError(Object error) {
  return 'We could not load the doctor dashboard. Pull to refresh or try again.';
}

String _joinParts(List<String> parts) {
  return parts.where((part) => part.trim().isNotEmpty).join(' • ');
}
