import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/patient_appointment_model.dart';
import 'providers/patient_providers.dart';

class PatientAppointmentsScreen extends ConsumerStatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  ConsumerState<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState
    extends ConsumerState<PatientAppointmentsScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = _tabIndex == 0
        ? upcomingAppointmentsProvider
        : pastAppointmentsProvider;
    final appointments = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            tooltip: 'Book appointment',
            onPressed: () => context.push('/patient/book'),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Upcoming'),
                  icon: Icon(Icons.event_available_outlined),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('History'),
                  icon: Icon(Icons.history),
                ),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (value) {
                setState(() => _tabIndex = value.first);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(provider);
                await ref.read(provider.future);
              },
              child: appointments.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    _AppointmentError(onRetry: () => ref.invalidate(provider)),
                data: (items) => _AppointmentList(
                  appointments: items,
                  isHistory: _tabIndex == 1,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/patient/book'),
        icon: const Icon(Icons.calendar_month_outlined),
        label: const Text('Book'),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<PatientAppointmentModel> appointments;
  final bool isHistory;

  const _AppointmentList({required this.appointments, required this.isHistory});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          Icon(
            isHistory ? Icons.history_toggle_off : Icons.event_busy_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            isHistory
                ? 'No appointment history yet'
                : 'No upcoming appointments',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isHistory
                ? 'Completed, cancelled, and no-show appointments will appear here.'
                : 'Book an appointment with a doctor to see it here.',
            textAlign: TextAlign.center,
          ),
          if (!isHistory) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/patient/book'),
              icon: const Icon(Icons.add),
              label: const Text('Book appointment'),
            ),
          ],
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemBuilder: (context, index) =>
          AppointmentCard(appointment: appointments[index]),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: appointments.length,
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final PatientAppointmentModel appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/patient/appointments/${appointment.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: const Icon(Icons.person_outline),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.displayDoctorName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        _MetaLine(
                          icon: Icons.calendar_today_outlined,
                          text: _formatDate(appointment.date),
                        ),
                        _MetaLine(
                          icon: Icons.schedule,
                          text: _formatTime(appointment.time),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: appointment.status),
                ],
              ),
              if (appointment.canReview) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        context.push('/patient/appointments/${appointment.id}'),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Rate doctor'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final colorScheme = Theme.of(context).colorScheme;
    final Color background;
    final Color foreground;
    final String label;

    switch (normalized) {
      case 'scheduled':
        background = colorScheme.primaryContainer;
        foreground = colorScheme.onPrimaryContainer;
        label = 'Scheduled';
      case 'rescheduled':
        background = Colors.amber.shade100;
        foreground = Colors.amber.shade900;
        label = 'Rescheduled';
      case 'completed':
        background = Colors.green.shade100;
        foreground = Colors.green.shade900;
        label = 'Completed';
      case 'cancelled':
      case 'canceled':
        background = Colors.red.shade100;
        foreground = Colors.red.shade900;
        label = 'Cancelled';
      case 'no_show':
        background = Colors.grey.shade300;
        foreground = Colors.grey.shade900;
        label = 'No show';
      default:
        background = colorScheme.surfaceContainerHighest;
        foreground = colorScheme.onSurfaceVariant;
        label = status.isEmpty ? 'Unknown' : status;
    }

    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: background,
      labelStyle: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      side: BorderSide.none,
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Theme.of(context).hintColor),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AppointmentError extends StatelessWidget {
  final VoidCallback onRetry;

  const _AppointmentError({required this.onRetry});

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
          'Appointments could not be loaded.',
          textAlign: TextAlign.center,
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

String _formatDate(String value) {
  if (value.isEmpty) return 'Date not set';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
}

String _formatTime(String value) {
  if (value.isEmpty) return 'Time not set';
  return value.length >= 5 ? value.substring(0, 5) : value;
}
