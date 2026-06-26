import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/doctor_appointment_model.dart';
import 'providers/doctor_providers.dart';

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends ConsumerState<DoctorAppointmentsScreen> {
  final _searchController = TextEditingController();
  DoctorAppointmentFilter _filter = DoctorAppointmentFilter.today;
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = (filter: _filter, search: _search);
    final appointments = ref.watch(doctorAppointmentsProvider(query));

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(doctorAppointmentsProvider(query));
          await ref.read(doctorAppointmentsProvider(query).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _SearchField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _search = value.trim());
              },
              onClear: () {
                _searchController.clear();
                setState(() => _search = '');
              },
            ),
            const SizedBox(height: 12),
            _FilterChips(
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 16),
            appointments.when(
              loading: () => const _LoadingAppointments(),
              error: (error, _) => _ErrorAppointments(
                message: _friendlyError(error),
                onRetry: () =>
                    ref.invalidate(doctorAppointmentsProvider(query)),
              ),
              data: (items) => _AppointmentsList(
                appointments: items,
                isSearching: _search.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: 'Search appointments',
        hintText: 'Search by patient name',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
      ),
      onChanged: onChanged,
    );
  }
}

class _FilterChips extends StatelessWidget {
  final DoctorAppointmentFilter selected;
  final ValueChanged<DoctorAppointmentFilter> onSelected;

  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DoctorAppointmentFilter.values
            .map(
              (filter) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(filter.label),
                  selected: selected == filter,
                  onSelected: (_) => onSelected(filter),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AppointmentsList extends StatelessWidget {
  final List<DoctorAppointmentModel> appointments;
  final bool isSearching;

  const _AppointmentsList({
    required this.appointments,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return _EmptyAppointments(isSearching: isSearching);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${appointments.length} appointment${appointments.length == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...appointments.map(
          (appointment) => _AppointmentCard(appointment: appointment),
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final DoctorAppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push(
          '/doctor/appointments/${appointment.id}',
          extra: appointment,
        ),
        leading: CircleAvatar(
          child: Text(
            appointment.id == 0 ? '?' : appointment.id.toString(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        title: Text(appointment.displayPatientName),
        subtitle: Text(_joinParts([appointment.date, appointment.time])),
        trailing: _StatusChip(status: appointment.parsedStatus),
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
    return Chip(
      label: Text(status.label),
      side: BorderSide(color: color.withValues(alpha: 0.45)),
      backgroundColor: color.withValues(alpha: 0.10),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}

class _EmptyAppointments extends StatelessWidget {
  final bool isSearching;

  const _EmptyAppointments({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(
            isSearching
                ? Icons.search_off_outlined
                : Icons.event_available_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'No appointments match this search.'
                : 'No appointments found.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _LoadingAppointments extends StatelessWidget {
  const _LoadingAppointments();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorAppointments extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorAppointments({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _friendlyError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return 'Your doctor session has expired. Please log in again.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'The server could not load appointments right now.';
    }
  }
  return 'We could not load appointments. Pull to refresh or try again.';
}

String _joinParts(List<String> parts) {
  final joined = parts.where((part) => part.trim().isNotEmpty).join(' • ');
  return joined.isEmpty ? 'No date or time available' : joined;
}
