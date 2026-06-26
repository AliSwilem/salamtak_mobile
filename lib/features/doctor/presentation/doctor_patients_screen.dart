import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/doctor_patient_model.dart';
import 'providers/doctor_providers.dart';

class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  ConsumerState<DoctorPatientsScreen> createState() =>
      _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(doctorPatientsProvider(_search));

    return Scaffold(
      appBar: AppBar(title: const Text('Patients')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(doctorPatientsProvider(_search));
          await ref.read(doctorPatientsProvider(_search).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Search patients',
                hintText: 'Search by patient name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (value) => setState(() => _search = value.trim()),
            ),
            const SizedBox(height: 16),
            patients.when(
              loading: () => const _LoadingPatients(),
              error: (error, _) => _ErrorPatients(
                message: _friendlyError(error),
                onRetry: () => ref.invalidate(doctorPatientsProvider(_search)),
              ),
              data: (items) => _PatientsList(
                patients: items,
                isSearching: _search.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientsList extends StatelessWidget {
  final List<DoctorPatientModel> patients;
  final bool isSearching;

  const _PatientsList({required this.patients, required this.isSearching});

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return _EmptyPatients(isSearching: isSearching);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${patients.length} patient${patients.length == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...patients.map((patient) => _PatientCard(patient: patient)),
      ],
    );
  }
}

class _PatientCard extends StatelessWidget {
  final DoctorPatientModel patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final age = patient.age;
    return Card(
      child: ListTile(
        onTap: () => context.push('/doctor/patients/${patient.id}'),
        leading: CircleAvatar(
          child: Text(patient.id > 0 ? '${patient.id}' : '?'),
        ),
        title: Text(patient.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _joinParts([
                patient.gender,
                patient.dateOfBirth.isEmpty
                    ? ''
                    : age == null
                    ? patient.dateOfBirth
                    : '${patient.dateOfBirth} ($age years)',
              ]),
            ),
            if (patient.contactInfo.isNotEmpty) Text(patient.contactInfo),
          ],
        ),
        trailing: patient.bloodType.isEmpty
            ? const Icon(Icons.chevron_right)
            : Chip(label: Text(patient.bloodType)),
      ),
    );
  }
}

class _EmptyPatients extends StatelessWidget {
  final bool isSearching;

  const _EmptyPatients({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          Icon(
            isSearching ? Icons.person_search_outlined : Icons.groups_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching ? 'No patients match this search.' : 'No patients yet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _LoadingPatients extends StatelessWidget {
  const _LoadingPatients();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorPatients extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPatients({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
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
  }
  return 'We could not load patients. Pull to refresh or try again.';
}

String _joinParts(List<String> parts) {
  final joined = parts.where((part) => part.trim().isNotEmpty).join(' • ');
  return joined.isEmpty ? 'No basic details available' : joined;
}
