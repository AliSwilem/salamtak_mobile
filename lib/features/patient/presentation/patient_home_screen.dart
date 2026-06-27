import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/patient_dashboard_model.dart';
import 'providers/patient_providers.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(patientHomeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(patientHomeProvider.future),
        child: home.when(
          loading: () => const _LoadingBody(),
          error: (error, _) => _ErrorBody(
            message: _friendlyError(error),
            onRetry: () => ref.invalidate(patientHomeProvider),
          ),
          data: (data) => _HomeBody(data: data),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final PatientHomeData data;

  const _HomeBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final appointments = data.dashboard.upcomingAppointments;
    final unread = data.dashboard.notifications
        .where((item) => !item.isRead)
        .length;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Hello, ${data.patientName.isEmpty ? 'Patient' : data.patientName}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Here is your health overview.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today_outlined,
                label: 'Upcoming',
                value: appointments.length,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.notifications_none,
                label: 'Unread',
                value: unread,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.folder_outlined,
                label: 'Records',
                value: data.healthRecordCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Next appointment', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (appointments.isEmpty)
          const _EmptyAppointment()
        else
          _AppointmentCard(appointment: appointments.first),
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
              icon: Icons.add_circle_outline,
              label: 'Book Appointment',
              onTap: () => context.go('/patient/book'),
            ),
            _QuickAction(
              icon: Icons.medical_services_outlined,
              label: 'Doctors',
              onTap: () => context.go('/patient/doctors'),
            ),
            _QuickAction(
              icon: Icons.folder_outlined,
              label: 'Records',
              onTap: () => context.go('/patient/records'),
            ),
            _QuickAction(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => context.go('/patient/profile'),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final PatientAppointmentPreview appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/patient/appointments/${appointment.id}'),
        leading: const CircleAvatar(child: Icon(Icons.event_available)),
        title: Text(
          appointment.doctorName.isEmpty
              ? 'Doctor appointment'
              : appointment.doctorName,
        ),
        subtitle: Text('${appointment.date} • ${appointment.time}'),
        trailing: Chip(label: Text(appointment.status)),
      ),
    );
  }
}

class _EmptyAppointment extends StatelessWidget {
  const _EmptyAppointment();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            const Text('No upcoming appointments.'),
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
  return 'We could not load your dashboard. Pull to refresh or try again.';
}
