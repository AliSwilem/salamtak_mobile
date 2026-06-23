import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/patient_doctor_model.dart';
import 'providers/patient_providers.dart';

class PatientDoctorsScreen extends ConsumerStatefulWidget {
  const PatientDoctorsScreen({super.key});

  @override
  ConsumerState<PatientDoctorsScreen> createState() =>
      _PatientDoctorsScreenState();
}

class _PatientDoctorsScreenState extends ConsumerState<PatientDoctorsScreen> {
  int? _hospitalId;
  String? _specialization;

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
    final hospitals = ref.watch(patientHospitalsProvider);
    final filter = (specialization: _specialization, hospitalId: _hospitalId);
    final doctors = ref.watch(patientDoctorsProvider(filter));
    final selectedHospital = hospitals.value?.where(
      (hospital) => hospital.id == _hospitalId,
    );
    final selectedHospitalName =
        selectedHospital == null || selectedHospital.isEmpty
        ? null
        : selectedHospital.first.name;

    return Scaffold(
      appBar: AppBar(title: const Text('Doctors')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(patientHospitalsProvider);
          ref.invalidate(patientDoctorsProvider(filter));
          await ref.read(patientDoctorsProvider(filter).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Find the right doctor',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Filter by hospital and specialization.'),
            const SizedBox(height: 20),
            hospitals.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => _HospitalError(
                onRetry: () => ref.invalidate(patientHospitalsProvider),
              ),
              data: (items) => DropdownButtonFormField<int?>(
                initialValue: _hospitalId,
                decoration: const InputDecoration(
                  labelText: 'Hospital',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All hospitals'),
                  ),
                  ...items.map(
                    (hospital) => DropdownMenuItem<int?>(
                      value: hospital.id,
                      child: Text(hospital.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _hospitalId = value),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _specialization,
              decoration: const InputDecoration(
                labelText: 'Specialization',
                prefixIcon: Icon(Icons.medical_information_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All specializations'),
                ),
                ..._specializations.map(
                  (item) =>
                      DropdownMenuItem<String?>(value: item, child: Text(item)),
                ),
              ],
              onChanged: (value) => setState(() => _specialization = value),
            ),
            const SizedBox(height: 20),
            doctors.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _DoctorsError(
                onRetry: () => ref.invalidate(patientDoctorsProvider(filter)),
              ),
              data: (items) => _DoctorResults(
                doctors: items,
                hospitalName: selectedHospitalName,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorResults extends StatelessWidget {
  final List<PatientDoctorModel> doctors;
  final String? hospitalName;

  const _DoctorResults({required this.doctors, this.hospitalName});

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48),
            SizedBox(height: 12),
            Text('No doctors match these filters.'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${doctors.length} doctor${doctors.length == 1 ? '' : 's'} found',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        ...doctors.map(
          (doctor) => _DoctorCard(doctor: doctor, hospitalName: hospitalName),
        ),
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final PatientDoctorModel doctor;
  final String? hospitalName;

  const _DoctorCard({required this.doctor, this.hospitalName});

  @override
  Widget build(BuildContext context) {
    final displayedHospital = hospitalName?.trim().isNotEmpty == true
        ? hospitalName!
        : doctor.clinicName.isNotEmpty
        ? doctor.clinicName
        : 'Hospital not provided';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doctor details are planned for Sprint 2.'),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.person_outline, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.fullName.isEmpty ? 'Doctor' : doctor.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      doctor.specialization.isEmpty
                          ? 'General Practice'
                          : doctor.specialization,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DoctorMeta(
                      icon: Icons.work_outline,
                      text: '${doctor.yearsOfExperience} years experience',
                    ),
                    _DoctorMeta(
                      icon: Icons.star_outline,
                      text:
                          '${doctor.averageRating.toStringAsFixed(1)} '
                          '(${doctor.reviewsCount} reviews)',
                    ),
                    _DoctorMeta(
                      icon: Icons.local_hospital_outlined,
                      text: displayedHospital,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DoctorMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).hintColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _HospitalError extends StatelessWidget {
  final VoidCallback onRetry;

  const _HospitalError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.error_outline),
      title: const Text('Hospitals could not be loaded.'),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    );
  }
}

class _DoctorsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DoctorsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Doctors could not be loaded.'),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
