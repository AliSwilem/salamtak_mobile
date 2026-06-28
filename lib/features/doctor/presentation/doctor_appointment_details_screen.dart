import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/doctor_appointment_model.dart';
import '../../video/presentation/providers/video_providers.dart';
import 'providers/doctor_providers.dart';

class DoctorAppointmentDetailsScreen extends ConsumerStatefulWidget {
  final DoctorAppointmentModel appointment;

  const DoctorAppointmentDetailsScreen({super.key, required this.appointment});

  @override
  ConsumerState<DoctorAppointmentDetailsScreen> createState() =>
      _DoctorAppointmentDetailsScreenState();
}

class _DoctorAppointmentDetailsScreenState
    extends ConsumerState<DoctorAppointmentDetailsScreen> {
  late DoctorAppointmentModel _appointment;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(doctorAppointmentActionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(appointment: _appointment),
          const SizedBox(height: 16),
          _DetailsCard(appointment: _appointment),
          const SizedBox(height: 16),
          _VideoStatusCard(appointment: _appointment),
          const SizedBox(height: 16),
          Text('Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_appointment.patientId > 0) ...[
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/doctor/patients/${_appointment.patientId}'),
              icon: const Icon(Icons.folder_shared_outlined),
              label: const Text('Open patient medical file'),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: _appointment.patientId <= 0
                ? null
                : () => context.push(
                    '/doctor/consultation/${_appointment.id}',
                    extra: _appointment,
                  ),
            icon: const Icon(Icons.medical_information_outlined),
            label: const Text('Start / open consultation'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _appointment.patientId <= 0
                ? null
                : () => context.push(
                    '/doctor/appointments/${_appointment.id}/video',
                  ),
            icon: const Icon(Icons.video_call_outlined),
            label: const Text('Open video session'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: action.isLoading ? null : _showStatusSheet,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Update status'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: action.isLoading ? null : _showCancelDialog,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel appointment'),
          ),
          if (action.isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Future<void> _showStatusSheet() async {
    final selected = await showModalBottomSheet<DoctorAppointmentStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Update appointment status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...DoctorAppointmentStatus.values.map(
              (status) => ListTile(
                title: Text(status.label),
                trailing: status == _appointment.parsedStatus
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(status),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected == null || selected.apiValue == _appointment.status) return;
    await _updateStatus(selected);
  }

  Future<void> _updateStatus(DoctorAppointmentStatus status) async {
    final updated = await ref
        .read(doctorAppointmentActionProvider.notifier)
        .updateStatus(appointmentId: _appointment.id, status: status);
    if (!mounted) return;

    if (updated == null) {
      _showSnack(_actionError(), isError: true);
      return;
    }

    setState(() => _appointment = updated);
    _showSnack('Appointment status updated.');
  }

  Future<void> _showCancelDialog() async {
    final controller = TextEditingController(text: 'Cancelled by doctor');
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel appointment'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Cancelled by doctor',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (reason == null) return;
    await _cancel(reason);
  }

  Future<void> _cancel(String reason) async {
    final updated = await ref
        .read(doctorAppointmentActionProvider.notifier)
        .cancel(appointmentId: _appointment.id, reason: reason);
    if (!mounted) return;

    if (updated == null) {
      _showSnack(_actionError(), isError: true);
      return;
    }

    setState(() => _appointment = updated);
    _showSnack('Appointment cancelled.');
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  String _actionError() {
    final error = ref.read(doctorAppointmentActionProvider).error;
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) return 'This appointment was not found.';
      if (statusCode == 401 || statusCode == 403) {
        return 'You are not allowed to update this appointment.';
      }
      if (statusCode == 422) {
        return 'The appointment update was not accepted by the server.';
      }
    }
    return 'Could not update the appointment. Please try again.';
  }
}

class _HeaderCard extends StatelessWidget {
  final DoctorAppointmentModel appointment;

  const _HeaderCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                appointment.patientId > 0 ? '${appointment.patientId}' : '?',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.displayPatientName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  _StatusChip(status: appointment.parsedStatus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final DoctorAppointmentModel appointment;

  const _DetailsCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _DetailRow(label: 'Appointment ID', value: '${appointment.id}'),
            _DetailRow(label: 'Patient ID', value: '${appointment.patientId}'),
            _DetailRow(label: 'Doctor ID', value: '${appointment.doctorId}'),
            _DetailRow(
              label: 'Hospital ID',
              value: appointment.hospitalId?.toString() ?? 'Not assigned',
            ),
            _DetailRow(
              label: 'Date',
              value: appointment.date.isEmpty
                  ? 'Not available'
                  : appointment.date,
            ),
            _DetailRow(
              label: 'Time',
              value: appointment.time.isEmpty
                  ? 'Not available'
                  : appointment.time,
            ),
            _DetailRow(label: 'Status', value: appointment.displayStatus),
          ],
        ),
      ),
    );
  }
}

class _VideoStatusCard extends ConsumerWidget {
  final DoctorAppointmentModel appointment;

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
                context.push('/doctor/appointments/${appointment.id}/video'),
          ),
          data: (item) {
            if (item == null) {
              return _VideoSummary(
                title: 'Video consultation',
                message: 'No video session has been started yet.',
                buttonLabel: 'Start / open video',
                onPressed: () => context.push(
                  '/doctor/appointments/${appointment.id}/video',
                ),
              );
            }

            return _VideoSummary(
              title: 'Video ${item.displayStatus}',
              message: item.canJoin
                  ? 'This video session is ready to join.'
                  : item.noticeMessage ??
                        'Video session exists, but joining is not available.',
              buttonLabel: item.canJoin ? 'Join video' : 'View video status',
              onPressed: () =>
                  context.push('/doctor/appointments/${appointment.id}/video'),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final DoctorAppointmentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (status) {
      DoctorAppointmentStatus.completed => Colors.green,
      DoctorAppointmentStatus.cancelled => colors.error,
      DoctorAppointmentStatus.noShow => Colors.orange,
      DoctorAppointmentStatus.rescheduled => Colors.blueGrey,
      DoctorAppointmentStatus.scheduled => colors.primary,
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Chip(
        label: Text(status.label),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
        backgroundColor: color.withValues(alpha: 0.10),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
