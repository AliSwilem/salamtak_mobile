import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/patient_appointment_model.dart';
import '../data/models/patient_availability_slot_model.dart';
import '../data/models/patient_doctor_model.dart';
import 'providers/patient_providers.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final int? preselectedDoctorId;

  const BookAppointmentScreen({super.key, this.preselectedDoctorId});

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  int _step = 0;
  int? _hospitalId;
  String? _specialization;
  DoctorSearchFilter? _doctorFilter;
  PatientDoctorModel? _selectedDoctor;
  String? _selectedDate;
  PatientAvailabilitySlotModel? _selectedSlot;
  PatientAppointmentModel? _createdAppointment;

  static const _specializations = [
    'General Practice',
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'Gastroenterology',
    'Neurology',
    'Oncology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Radiology',
    'Surgery',
    'Urology',
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen(appointmentActionProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyError(next.error))));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Stepper(
        currentStep: _step,
        controlsBuilder: _buildControls,
        onStepTapped: (step) {
          if (step <= _step) setState(() => _step = step);
        },
        steps: [
          Step(
            title: const Text('Find doctor'),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: _FindDoctorStep(
              hospitalId: _hospitalId,
              specialization: _specialization,
              specializations: _specializations,
              doctorFilter: _doctorFilter,
              onHospitalChanged: (value) => setState(() {
                _hospitalId = value;
                _doctorFilter = null;
                _selectedDoctor = null;
                _selectedDate = null;
                _selectedSlot = null;
              }),
              onSpecializationChanged: (value) => setState(() {
                _specialization = value;
                _doctorFilter = null;
                _selectedDoctor = null;
                _selectedDate = null;
                _selectedSlot = null;
              }),
              onSearch: _searchDoctors,
              onDoctorSelected: (doctor) => setState(() {
                _selectedDoctor = doctor;
                _selectedDate = null;
                _selectedSlot = null;
                _step = 1;
              }),
            ),
          ),
          Step(
            title: const Text('Pick time'),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
            content: _PickTimeStep(
              doctor: _selectedDoctor,
              selectedDate: _selectedDate,
              selectedSlot: _selectedSlot,
              onDateChanged: (date) => setState(() {
                _selectedDate = date;
                _selectedSlot = null;
              }),
              onSlotSelected: (slot) => setState(() {
                _selectedSlot = slot;
                _step = 2;
              }),
            ),
          ),
          Step(
            title: const Text('Confirm'),
            isActive: _step >= 2,
            state: _step > 2 ? StepState.complete : StepState.indexed,
            content: _ConfirmStep(
              doctor: _selectedDoctor,
              date: _selectedDate,
              slot: _selectedSlot,
              createdAppointment: _createdAppointment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    final action = ref.watch(appointmentActionProvider);
    final isLoading = action.isLoading;

    if (_createdAppointment != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => context.go(
                '/patient/appointments/${_createdAppointment!.id}',
              ),
              child: const Text('View details'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/patient/appointments'),
              child: const Text('Appointments'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(
              onPressed: isLoading
                  ? null
                  : () =>
                        setState(() => _step = (_step - 1).clamp(0, 2).toInt()),
              child: const Text('Back'),
            ),
          const Spacer(),
          FilledButton(
            onPressed: isLoading ? null : _primaryAction,
            child: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_step == 2 ? 'Confirm booking' : 'Continue'),
          ),
        ],
      ),
    );
  }

  void _searchDoctors() {
    if (_hospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a hospital first.')),
      );
      return;
    }
    setState(() {
      _doctorFilter = (
        specialization: _specialization,
        hospitalId: _hospitalId,
      );
    });
  }

  Future<void> _primaryAction() async {
    if (_step == 0) {
      if (_selectedDoctor == null) {
        _searchDoctors();
        return;
      }
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      if (_selectedDate == null || _selectedSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date and time.')),
        );
        return;
      }
      setState(() => _step = 2);
      return;
    }

    final doctor = _selectedDoctor;
    final date = _selectedDate;
    final slot = _selectedSlot;
    if (doctor == null || date == null || slot == null) return;

    final appointment = await ref
        .read(appointmentActionProvider.notifier)
        .book(
          BookAppointmentRequest(
            doctorId: doctor.id,
            hospitalId: _hospitalId,
            date: date,
            time: slot.time,
          ),
        );

    if (!mounted || appointment == null) return;
    setState(() => _createdAppointment = appointment);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appointment.isCancelled
              ? 'Booking was cancelled because payment failed.'
              : 'Appointment booked successfully.',
        ),
      ),
    );
  }
}

class _FindDoctorStep extends ConsumerWidget {
  final int? hospitalId;
  final String? specialization;
  final List<String> specializations;
  final DoctorSearchFilter? doctorFilter;
  final ValueChanged<int?> onHospitalChanged;
  final ValueChanged<String?> onSpecializationChanged;
  final VoidCallback onSearch;
  final ValueChanged<PatientDoctorModel> onDoctorSelected;

  const _FindDoctorStep({
    required this.hospitalId,
    required this.specialization,
    required this.specializations,
    required this.doctorFilter,
    required this.onHospitalChanged,
    required this.onSpecializationChanged,
    required this.onSearch,
    required this.onDoctorSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitals = ref.watch(patientHospitalsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hospitals.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.error_outline),
            title: const Text('Hospitals could not be loaded.'),
            trailing: TextButton(
              onPressed: () => ref.invalidate(patientHospitalsProvider),
              child: const Text('Retry'),
            ),
          ),
          data: (items) => DropdownButtonFormField<int?>(
            initialValue: hospitalId,
            decoration: const InputDecoration(
              labelText: 'Hospital',
              prefixIcon: Icon(Icons.local_hospital_outlined),
            ),
            items: items
                .map(
                  (hospital) => DropdownMenuItem<int?>(
                    value: hospital.id,
                    child: Text(hospital.name),
                  ),
                )
                .toList(),
            onChanged: onHospitalChanged,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: specialization,
          decoration: const InputDecoration(
            labelText: 'Specialization',
            prefixIcon: Icon(Icons.medical_information_outlined),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Any specialization'),
            ),
            ...specializations.map(
              (item) =>
                  DropdownMenuItem<String?>(value: item, child: Text(item)),
            ),
          ],
          onChanged: onSpecializationChanged,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onSearch,
          icon: const Icon(Icons.search),
          label: const Text('Search doctors'),
        ),
        if (doctorFilter != null) ...[
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, _) {
              final doctors = ref.watch(patientDoctorsProvider(doctorFilter!));
              return doctors.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Doctors could not be loaded.'),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No doctors match these filters.'),
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (doctor) => Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(
                                doctor.fullName.isEmpty
                                    ? 'Doctor'
                                    : doctor.fullName,
                              ),
                              subtitle: Text(
                                [
                                      doctor.specialization,
                                      '${doctor.yearsOfExperience} years',
                                      '${doctor.averageRating.toStringAsFixed(1)} ★',
                                    ]
                                    .where((item) => item.trim().isNotEmpty)
                                    .join(' • '),
                              ),
                              trailing: IconButton(
                                tooltip: 'Profile',
                                icon: const Icon(Icons.info_outline),
                                onPressed: () => context.push(
                                  '/patient/doctors/${doctor.id}',
                                ),
                              ),
                              onTap: () => onDoctorSelected(doctor),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }
}

class _PickTimeStep extends ConsumerWidget {
  final PatientDoctorModel? doctor;
  final String? selectedDate;
  final PatientAvailabilitySlotModel? selectedSlot;
  final ValueChanged<String> onDateChanged;
  final ValueChanged<PatientAvailabilitySlotModel> onSlotSelected;

  const _PickTimeStep({
    required this.doctor,
    required this.selectedDate,
    required this.selectedSlot,
    required this.onDateChanged,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (doctor == null) {
      return const Text('Select a doctor first.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(doctor!.fullName),
          subtitle: Text(doctor!.specialization),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 120)),
              initialDate:
                  DateTime.tryParse(selectedDate ?? '') ?? DateTime.now(),
            );
            if (date != null) onDateChanged(_yyyyMmDd(date));
            if (date != null) {
              ref.invalidate(
                doctorAvailabilityProvider((
                  doctorId: doctor!.id,
                  date: _yyyyMmDd(date),
                )),
              );
            }
          },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(selectedDate ?? 'Select date'),
        ),
        if (selectedDate != null) ...[
          const SizedBox(height: 16),
          ref
              .watch(
                doctorAvailabilityProvider((
                  doctorId: doctor!.id,
                  date: selectedDate!,
                )),
              )
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text('Failed to load availability.'),
                data: (slots) {
                  final availableSlots = slots
                      .where((slot) => slot.available && slot.time.isNotEmpty)
                      .toList();
                  if (availableSlots.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No available slots for this date.'),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => ref.invalidate(
                              doctorAvailabilityProvider((
                                doctorId: doctor!.id,
                                date: selectedDate!,
                              )),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh availability'),
                          ),
                        ],
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSlots.map((slot) {
                      final selected = selectedSlot?.time == slot.time;
                      return ChoiceChip(
                        label: Text(slot.displayTime),
                        selected: selected,
                        onSelected: (_) => onSlotSelected(slot),
                      );
                    }).toList(),
                  );
                },
              ),
        ],
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  final PatientDoctorModel? doctor;
  final String? date;
  final PatientAvailabilitySlotModel? slot;
  final PatientAppointmentModel? createdAppointment;

  const _ConfirmStep({
    required this.doctor,
    required this.date,
    required this.slot,
    required this.createdAppointment,
  });

  @override
  Widget build(BuildContext context) {
    if (createdAppointment != null) {
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 8),
              Text(
                'Appointment created',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('Appointment #${createdAppointment!.id}'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryLine(label: 'Doctor', value: doctor?.fullName ?? '-'),
            _SummaryLine(
              label: 'Specialization',
              value: doctor?.specialization ?? '-',
            ),
            _SummaryLine(label: 'Date', value: date ?? '-'),
            _SummaryLine(label: 'Time', value: slot?.displayTime ?? '-'),
            const Divider(),
            const Text('Payment will be submitted as successful demo payment.'),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _yyyyMmDd(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _friendlyError(Object? error) {
  final text = error?.toString() ?? '';
  if (text.contains('422')) {
    return 'Please check the selected appointment data.';
  }
  if (text.contains('404')) {
    return 'The selected doctor or appointment was not found.';
  }
  return 'The appointment action could not be completed.';
}
