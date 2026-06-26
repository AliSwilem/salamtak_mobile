import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/doctor_patient_model.dart';
import 'providers/doctor_providers.dart';

class DoctorPatientMedicalFileScreen extends ConsumerWidget {
  final int patientId;

  const DoctorPatientMedicalFileScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(doctorPatientFileProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Medical File')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(doctorPatientFileProvider(patientId));
          await ref.read(doctorPatientFileProvider(patientId).future);
        },
        child: file.when(
          loading: () => const _LoadingFile(),
          error: (error, _) => _ErrorFile(
            message: _friendlyError(error),
            onRetry: () => ref.invalidate(doctorPatientFileProvider(patientId)),
          ),
          data: (data) => _MedicalFileBody(patientId: patientId, data: data),
        ),
      ),
    );
  }
}

class _MedicalFileBody extends StatelessWidget {
  final int patientId;
  final DoctorPatientFileData data;

  const _MedicalFileBody({required this.patientId, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _PatientInfoCard(patientId: patientId, patient: data.patient),
        const SizedBox(height: 16),
        _SummaryGrid(summary: data.summary, statistics: data.statistics),
        const SizedBox(height: 20),
        Text(
          'Consultation history',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _HistorySection(history: data.history),
      ],
    );
  }
}

class _PatientInfoCard extends StatelessWidget {
  final int patientId;
  final DoctorPatientModel? patient;

  const _PatientInfoCard({required this.patientId, required this.patient});

  @override
  Widget build(BuildContext context) {
    final item = patient;
    final age = item?.age;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(patientId > 0 ? '$patientId' : '?'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item?.displayName ?? 'Patient #$patientId',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        _joinParts([
                          item?.gender ?? '',
                          item?.bloodType.isNotEmpty == true
                              ? 'Blood: ${item!.bloodType}'
                              : '',
                        ]),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _InfoRow(label: 'Date of birth', value: _dobText(item, age)),
            _InfoRow(label: 'Contact', value: item?.contactInfo ?? ''),
            _InfoRow(label: 'Address', value: item?.address ?? ''),
            _InfoRow(
              label: 'Medical history',
              value: item?.medicalHistory ?? '',
            ),
          ],
        ),
      ),
    );
  }

  String _dobText(DoctorPatientModel? item, int? age) {
    if (item == null || item.dateOfBirth.isEmpty) return 'Not available';
    if (age == null) return item.dateOfBirth;
    return '${item.dateOfBirth} ($age years)';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.trim().isEmpty ? 'Not available' : value)),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final DoctorPatientSummaryModel summary;
  final DoctorPatientStatisticsModel statistics;

  const _SummaryGrid({required this.summary, required this.statistics});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _MetricCard(
          icon: Icons.assignment_outlined,
          label: 'Diagnoses',
          value: '${summary.diagnoses}',
        ),
        _MetricCard(
          icon: Icons.healing_outlined,
          label: 'Treatments',
          value: '${summary.treatments}',
        ),
        _MetricCard(
          icon: Icons.folder_outlined,
          label: 'EHR files',
          value: '${summary.ehrFiles}',
        ),
        _MetricCard(
          icon: Icons.medication_outlined,
          label: 'Active treatments',
          value: '${statistics.activeTreatments}',
          footer: statistics.lastDiagnosisDate.isEmpty
              ? null
              : 'Last diagnosis: ${statistics.lastDiagnosisDate}',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? footer;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.footer,
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
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label),
            if (footer != null)
              Text(
                footer!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final DoctorConsultationHistoryModel history;

  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.diagnoses.isEmpty && history.treatments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No consultation history for this patient yet.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (history.diagnoses.isNotEmpty) ...[
          Text('Diagnoses', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...history.diagnoses.map((item) => _DiagnosisCard(item: item)),
          const SizedBox(height: 12),
        ],
        if (history.treatments.isNotEmpty) ...[
          Text('Treatments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...history.treatments.map((item) => _TreatmentCard(item: item)),
        ],
      ],
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  final DoctorDiagnosisModel item;

  const _DiagnosisCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.assignment_outlined),
        title: Text(item.notes.isEmpty ? 'Diagnosis #${item.id}' : item.notes),
        subtitle: Text(
          _joinParts([
            item.date,
            item.confidenceLevel == null
                ? ''
                : 'Confidence ${item.confidenceLevel}',
          ]),
        ),
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final DoctorTreatmentModel item;

  const _TreatmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.healing_outlined),
        title: Text(
          item.description.isEmpty ? 'Treatment #${item.id}' : item.description,
        ),
        subtitle: Text(
          _joinParts([
            item.result,
            item.startDate.isEmpty ? '' : 'Start ${item.startDate}',
            item.endDate.isEmpty ? 'Active' : 'End ${item.endDate}',
          ]),
        ),
      ),
    );
  }
}

class _LoadingFile extends StatelessWidget {
  const _LoadingFile();

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

class _ErrorFile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorFile({required this.message, required this.onRetry});

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
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 403) {
      return 'You are not allowed to view this patient medical file.';
    }
    if (statusCode == 404) {
      return 'This patient medical file was not found.';
    }
  }
  return 'We could not load the patient medical file. Pull to refresh or try again.';
}

String _joinParts(List<String> parts) {
  final joined = parts.where((part) => part.trim().isNotEmpty).join(' • ');
  return joined.isEmpty ? 'Not available' : joined;
}
