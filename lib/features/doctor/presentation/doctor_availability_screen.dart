import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/doctor_availability_model.dart';
import 'providers/doctor_providers.dart';

const List<String> _dayLabels = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

class DoctorAvailabilityScreen extends ConsumerWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(doctorAvailabilityProvider);
    final action = ref.watch(doctorAvailabilityActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability'),
        actions: [
          IconButton(
            tooltip: 'Sync calendar',
            onPressed: action.isLoading
                ? null
                : () => _syncCalendar(context: context, ref: ref),
            icon: const Icon(Icons.sync_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: action.isLoading
            ? null
            : () => _openSlotDialog(context: context, ref: ref),
        icon: const Icon(Icons.add),
        label: const Text('Add slot'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(doctorAvailabilityProvider);
          await ref.read(doctorAvailabilityProvider.future);
        },
        child: availability.when(
          loading: () => const _LoadingAvailability(),
          error: (error, _) => _ErrorAvailability(
            message: _friendlyError(error),
            onRetry: () => ref.invalidate(doctorAvailabilityProvider),
          ),
          data: (data) => _AvailabilityBody(data: data),
        ),
      ),
    );
  }

  Future<void> _openSlotDialog({
    required BuildContext context,
    required WidgetRef ref,
    DoctorAvailabilitySlotModel? slot,
  }) async {
    final current = await ref.read(doctorAvailabilityProvider.future);
    if (!context.mounted) return;

    final result = await showDialog<DoctorAvailabilitySlotModel>(
      context: context,
      builder: (context) => _SlotDialog(slot: slot),
    );
    if (result == null) return;

    final nextSlots = [...current.availability.slots];
    if (slot == null) {
      nextSlots.add(result);
    } else {
      final index = nextSlots.indexWhere(
        (item) =>
            item.dayOfWeek == slot.dayOfWeek &&
            item.startTime == slot.startTime &&
            item.endTime == slot.endTime,
      );
      if (index >= 0) {
        nextSlots[index] = result;
      } else {
        nextSlots.add(result);
      }
    }

    final saved = await ref
        .read(doctorAvailabilityActionProvider.notifier)
        .save(_sortSlots(nextSlots));
    if (!context.mounted) return;
    _showSnack(
      context,
      saved == null ? _actionError(ref) : 'Availability saved.',
      isError: saved == null,
    );
  }

  Future<void> _syncCalendar({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final result = await ref
        .read(doctorAvailabilityActionProvider.notifier)
        .syncCalendar();
    if (!context.mounted) return;
    if (result == null) {
      _showSnack(context, _actionError(ref), isError: true);
      return;
    }
    _showSnack(
      context,
      result.message.isEmpty
          ? (result.synced ? 'Calendar synced.' : 'Calendar sync is not ready.')
          : result.message,
    );
  }
}

class _AvailabilityBody extends ConsumerWidget {
  final DoctorAvailabilityData data;

  const _AvailabilityBody({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = <int, List<DoctorAvailabilitySlotModel>>{
      for (var day = 0; day < _dayLabels.length; day++) day: [],
    };
    for (final slot in data.availability.slots) {
      if (slot.dayOfWeek >= 0 && slot.dayOfWeek < _dayLabels.length) {
        grouped[slot.dayOfWeek]!.add(slot);
      }
    }
    for (final slots in grouped.values) {
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _StatsCard(data: data),
        const SizedBox(height: 16),
        Text(
          'Weekly availability',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (data.availability.slots.isEmpty)
          const _EmptyAvailability()
        else
          ...grouped.entries.map(
            (entry) => _DayAvailabilityCard(
              day: entry.key,
              slots: entry.value,
              onEdit: (slot) => DoctorAvailabilityScreen()._openSlotDialog(
                context: context,
                ref: ref,
                slot: slot,
              ),
              onDeleteDay: () =>
                  _confirmDeleteDay(context: context, ref: ref, day: entry.key),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDeleteDay({
    required BuildContext context,
    required WidgetRef ref,
    required int day,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_dayLabels[day]} availability?'),
        content: const Text(
          'This removes all slots for this day. Existing appointments are not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final success = await ref
        .read(doctorAvailabilityActionProvider.notifier)
        .deleteDay(day);
    if (!context.mounted) return;
    _showSnack(
      context,
      success ? '${_dayLabels[day]} availability deleted.' : _actionError(ref),
      isError: !success,
    );
  }
}

class _StatsCard extends StatelessWidget {
  final DoctorAvailabilityData data;

  const _StatsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.stats.entries} active slot${data.stats.entries == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Doctor ID ${data.availability.doctorId}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayAvailabilityCard extends StatelessWidget {
  final int day;
  final List<DoctorAvailabilitySlotModel> slots;
  final ValueChanged<DoctorAvailabilitySlotModel> onEdit;
  final VoidCallback onDeleteDay;

  const _DayAvailabilityCard({
    required this.day,
    required this.slots,
    required this.onEdit,
    required this.onDeleteDay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dayLabels[day],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (slots.isNotEmpty)
                  IconButton(
                    tooltip: 'Delete day',
                    onPressed: onDeleteDay,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            if (slots.isEmpty)
              Text(
                'No slots',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...slots.map(
                (slot) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    '${slot.displayStartTime} - ${slot.displayEndTime}',
                  ),
                  subtitle: const Text('30-minute patient booking slots'),
                  trailing: IconButton(
                    tooltip: 'Edit slot',
                    onPressed: () => onEdit(slot),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlotDialog extends StatefulWidget {
  final DoctorAvailabilitySlotModel? slot;

  const _SlotDialog({this.slot});

  @override
  State<_SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends State<_SlotDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _day;
  late final TextEditingController _startController;
  late final TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    _day = widget.slot?.dayOfWeek ?? 1;
    _startController = TextEditingController(
      text: _displayEditorTime(widget.slot?.startTime ?? '09:00:00'),
    );
    _endController = TextEditingController(
      text: _displayEditorTime(widget.slot?.endTime ?? '17:00:00'),
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.slot == null ? 'Add availability slot' : 'Edit slot'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _day,
              decoration: const InputDecoration(labelText: 'Day'),
              items: [
                for (var day = 0; day < _dayLabels.length; day++)
                  DropdownMenuItem(value: day, child: Text(_dayLabels[day])),
              ],
              onChanged: (value) => setState(() => _day = value ?? _day),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _startController,
              decoration: const InputDecoration(
                labelText: 'Start time',
                hintText: '09:00',
              ),
              keyboardType: TextInputType.datetime,
              validator: _timeValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _endController,
              decoration: const InputDecoration(
                labelText: 'End time',
                hintText: '17:00',
              ),
              keyboardType: TextInputType.datetime,
              validator: _timeValidator,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final start = _normalizeTime(_startController.text);
    final end = _normalizeTime(_endController.text);
    if (_timeToMinutes(start) >= _timeToMinutes(end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be before end time.')),
      );
      return;
    }
    Navigator.of(context).pop(
      DoctorAvailabilitySlotModel(
        dayOfWeek: _day,
        startTime: start,
        endTime: end,
      ),
    );
  }

  String? _timeValidator(String? value) {
    final normalized = _normalizeTime(value ?? '');
    final parts = normalized.split(':');
    if (parts.length != 3) return 'Enter time as HH:mm.';
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = int.tryParse(parts[2]);
    if (hour == null ||
        minute == null ||
        second == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      return 'Enter a valid time.';
    }
    return null;
  }
}

class _EmptyAvailability extends StatelessWidget {
  const _EmptyAvailability();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            const Text(
              'No availability slots yet. Add one so patients can book appointments.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingAvailability extends StatelessWidget {
  const _LoadingAvailability();

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

class _ErrorAvailability extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorAvailability({required this.message, required this.onRetry});

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

List<DoctorAvailabilitySlotModel> _sortSlots(
  List<DoctorAvailabilitySlotModel> slots,
) {
  return [...slots]..sort((a, b) {
    final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
    if (dayCompare != 0) return dayCompare;
    return a.startTime.compareTo(b.startTime);
  });
}

String _friendlyError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return 'Your doctor session has expired. Please log in again.';
    }
  }
  return 'We could not load availability. Pull to refresh or try again.';
}

String _actionError(WidgetRef ref) {
  final error = ref.read(doctorAvailabilityActionProvider).error;
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 404) return 'No availability exists for that day.';
    if (statusCode == 422) return 'Please check the slot times and try again.';
  }
  return 'Could not update availability. Please try again.';
}

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

String _normalizeTime(String value) {
  final text = value.trim();
  if (text.length == 5) return '$text:00';
  return text;
}

String _displayEditorTime(String value) {
  if (value.length >= 5) return value.substring(0, 5);
  return value;
}

int _timeToMinutes(String value) {
  final parts = value.split(':');
  final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return hour * 60 + minute;
}
