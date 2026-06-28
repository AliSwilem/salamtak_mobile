import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/patient_appointment_model.dart';
import '../data/models/patient_availability_slot_model.dart';
import '../../video/presentation/providers/video_providers.dart';
import 'patient_appointments_screen.dart';
import 'providers/patient_providers.dart';

class AppointmentDetailsScreen extends ConsumerWidget {
  final int appointmentId;

  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointment = ref.watch(appointmentDetailsProvider(appointmentId));

    return Scaffold(
      appBar: AppBar(title: Text('Appointment #$appointmentId')),
      body: appointment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _DetailsError(
          onRetry: () =>
              ref.invalidate(appointmentDetailsProvider(appointmentId)),
        ),
        data: (item) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(appointmentDetailsProvider(appointmentId));
            await ref.read(appointmentDetailsProvider(appointmentId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _StatusBanner(appointment: item),
              const SizedBox(height: 12),
              _InfoCard(appointment: item),
              const SizedBox(height: 12),
              _PaymentCard(appointment: item),
              const SizedBox(height: 12),
              _VideoStatusCard(appointment: item),
              const SizedBox(height: 12),
              _ActionCard(appointment: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoStatusCard extends ConsumerWidget {
  final PatientAppointmentModel appointment;

  const _VideoStatusCard({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(videoSessionProvider(appointment.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: session.when(
          loading: () => const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Checking video session...'),
            ],
          ),
          error: (_, _) => _VideoSummary(
            title: 'Video unavailable',
            message: 'Video status could not be loaded.',
            buttonLabel: 'Open video',
            onPressed: () =>
                context.push('/patient/appointments/${appointment.id}/video'),
          ),
          data: (item) {
            if (item == null) {
              return _VideoSummary(
                title: 'Video consultation',
                message: 'The doctor has not started a video session yet.',
                buttonLabel: 'Open waiting room',
                onPressed: () => context.push(
                  '/patient/appointments/${appointment.id}/video',
                ),
              );
            }

            return _VideoSummary(
              title: 'Video ${item.displayStatus}',
              message: item.canJoin
                  ? 'You can join this video consultation.'
                  : item.noticeMessage ??
                        'Video session exists, but joining is not available yet.',
              buttonLabel: item.canJoin ? 'Join video' : 'View video status',
              onPressed: () =>
                  context.push('/patient/appointments/${appointment.id}/video'),
            );
          },
        ),
      ),
    );
  }
}

class _VideoSummary extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _VideoSummary({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.videocam_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(message),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.video_call_outlined),
          label: Text(buttonLabel),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final PatientAppointmentModel appointment;

  const _StatusBanner({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              appointment.isCancelled
                  ? Icons.cancel_outlined
                  : Icons.event_available_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  StatusChip(status: appointment.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final PatientAppointmentModel appointment;

  const _InfoCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Doctor',
              value: appointment.displayDoctorName,
            ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: appointment.date.isEmpty ? '-' : appointment.date,
            ),
            _DetailRow(
              icon: Icons.schedule,
              label: 'Time',
              value: appointment.time.length >= 5
                  ? appointment.time.substring(0, 5)
                  : appointment.time,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PatientAppointmentModel appointment;

  const _PaymentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (appointment.paymentStatus.isNotEmpty)
        _DetailRow(
          icon: Icons.payments_outlined,
          label: 'Payment',
          value: appointment.paymentStatus,
        ),
      if (appointment.refundLogged)
        const _DetailRow(
          icon: Icons.currency_exchange,
          label: 'Refund',
          value: 'Refund logged',
        ),
      if (appointment.emailStatus.isNotEmpty)
        _DetailRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: appointment.emailStatus,
        ),
      if (appointment.emailError.isNotEmpty)
        _DetailRow(
          icon: Icons.error_outline,
          label: 'Email error',
          value: appointment.emailError,
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment & notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends ConsumerWidget {
  final PatientAppointmentModel appointment;

  const _ActionCard({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(appointmentActionProvider).isLoading;
    final canModify = appointment.isActive && _isUpcoming(appointment);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (appointment.doctorId > 0)
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/patient/doctors/${appointment.doctorId}'),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Doctor profile'),
              ),
            if (canModify) ...[
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            _RescheduleSheet(appointment: appointment),
                      ),
                icon: const Icon(Icons.update),
                label: const Text('Reschedule'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: isLoading
                    ? null
                    : () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _CancelSheet(appointment: appointment),
                      ),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel appointment'),
              ),
            ],
            if (appointment.canReview)
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _ReviewSheet(appointment: appointment),
                      ),
                icon: const Icon(Icons.star_outline),
                label: const Text('Review doctor'),
              ),
            if (!canModify && !appointment.canReview)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No actions are available for this appointment.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CancelSheet extends ConsumerStatefulWidget {
  final PatientAppointmentModel appointment;

  const _CancelSheet({required this.appointment});

  @override
  ConsumerState<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends ConsumerState<_CancelSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(appointmentActionProvider).isLoading;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cancel appointment',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Cancelled by patient',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text('Confirm cancellation'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(appointmentActionProvider.notifier)
        .cancel(
          appointmentId: widget.appointment.id,
          reason: _controller.text.trim().isEmpty
              ? 'Cancelled by patient'
              : _controller.text.trim(),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Appointment cancelled.' : 'Cancel failed.')),
    );
  }
}

class _RescheduleSheet extends ConsumerStatefulWidget {
  final PatientAppointmentModel appointment;

  const _RescheduleSheet({required this.appointment});

  @override
  ConsumerState<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends ConsumerState<_RescheduleSheet> {
  String? _date;
  PatientAvailabilitySlotModel? _slot;

  @override
  void initState() {
    super.initState();
    _date = widget.appointment.date.isEmpty ? null : widget.appointment.date;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(appointmentActionProvider).isLoading;
    final availability = _date == null || widget.appointment.doctorId <= 0
        ? null
        : ref.watch(
            doctorAvailabilityProvider((
              doctorId: widget.appointment.doctorId,
              date: _date!,
            )),
          );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reschedule appointment',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 120)),
                initialDate: DateTime.tryParse(_date ?? '') ?? DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _date = _yyyyMmDd(date);
                  _slot = null;
                });
              }
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_date ?? 'Select date'),
          ),
          const SizedBox(height: 12),
          if (availability != null)
            availability.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Availability could not be loaded.'),
              data: (slots) {
                if (slots.isEmpty) return const Text('No slots available.');
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slots.map((slot) {
                    return ChoiceChip(
                      label: Text(slot.displayTime),
                      selected: _slot?.time == slot.time,
                      onSelected: slot.available
                          ? (_) => setState(() => _slot = slot)
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isLoading || _date == null || _slot == null
                ? null
                : _submit,
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text('Confirm reschedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(appointmentActionProvider.notifier)
        .reschedule(
          appointmentId: widget.appointment.id,
          request: AppointmentRescheduleRequest(
            newDate: _date!,
            newTime: _slot!.time,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Appointment rescheduled.' : 'Reschedule failed.'),
      ),
    );
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  final PatientAppointmentModel appointment;

  const _ReviewSheet({required this.appointment});

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(appointmentActionProvider).isLoading;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Review doctor', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = value),
                icon: Icon(
                  value <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comment',
              hintText: 'Share your experience',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text('Submit review'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(appointmentActionProvider.notifier)
        .submitReview(
          appointmentId: widget.appointment.id,
          request: DoctorReviewRequest(
            rating: _rating,
            comment: _commentController.text,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Review submitted.' : 'Review failed.')),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).hintColor),
          const SizedBox(width: 10),
          Text(label),
          const Spacer(),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DetailsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('Appointment could not be loaded.'),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

bool _isUpcoming(PatientAppointmentModel appointment) {
  final date = DateTime.tryParse(appointment.date);
  if (date == null) return false;
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  return !date.isBefore(todayOnly);
}

String _yyyyMmDd(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
