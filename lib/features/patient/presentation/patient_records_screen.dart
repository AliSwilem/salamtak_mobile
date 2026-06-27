import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/patient_records_model.dart';
import 'providers/patient_providers.dart';

class PatientRecordsScreen extends ConsumerWidget {
  const PatientRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(patientRecordsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Records'),
          actions: [
            IconButton(
              tooltip: 'Test results',
              onPressed: () => context.push('/patient/test-results'),
              icon: const Icon(Icons.science_outlined),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Diagnoses'),
              Tab(text: 'Treatments'),
              Tab(text: 'Medications'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
        body: records.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            message: 'Health records could not be loaded.',
            onRetry: () => ref.invalidate(patientRecordsProvider),
          ),
          data: (bundle) => TabBarView(
            children: [
              _DiagnosesList(items: bundle.diagnoses),
              _TreatmentsList(items: bundle.treatments),
              _MedicationsList(items: bundle.medications),
              _DocumentsList(items: bundle.documents),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosesList extends StatelessWidget {
  final List<PatientDiagnosisModel> items;

  const _DiagnosesList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.medical_information_outlined,
        title: 'No diagnoses yet',
        message: 'Diagnoses added by your doctors will appear here.',
      );
    }
    return _RefreshableList(
      children: items
          .map(
            (item) => _RecordCard(
              icon: Icons.medical_information_outlined,
              title: item.diagnosisName.isEmpty
                  ? 'Diagnosis #${item.id}'
                  : item.diagnosisName,
              subtitle: _join([item.date, item.doctorName]),
              body: item.notes,
              footer: item.doctorSpecialization,
            ),
          )
          .toList(),
    );
  }
}

class _TreatmentsList extends StatelessWidget {
  final List<PatientTreatmentModel> items;

  const _TreatmentsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.healing_outlined,
        title: 'No treatments yet',
        message: 'Treatment plans will appear here after doctor visits.',
      );
    }
    return _RefreshableList(
      children: items
          .map(
            (item) => _RecordCard(
              icon: Icons.healing_outlined,
              title: item.type.isEmpty ? 'Treatment #${item.id}' : item.type,
              subtitle: _join([item.startDate, item.endDate]),
              body: item.description,
              footer: _join([item.doctorName, item.doctorSpecialization]),
            ),
          )
          .toList(),
    );
  }
}

class _MedicationsList extends StatelessWidget {
  final List<PatientMedicationModel> items;

  const _MedicationsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.medication_outlined,
        title: 'No medications yet',
        message: 'Prescribed medications will appear here.',
      );
    }
    return _RefreshableList(
      children: items
          .map(
            (item) => _RecordCard(
              icon: Icons.medication_outlined,
              title: item.name.isEmpty ? 'Medication #${item.id}' : item.name,
              subtitle: _join([item.dosage, item.form]),
              body: item.description,
              footer: _join([item.diagnosisName, item.doctorName]),
            ),
          )
          .toList(),
    );
  }
}

class _DocumentsList extends StatelessWidget {
  final List<PatientDocumentModel> items;

  const _DocumentsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'No documents yet',
        message: 'Uploaded medical documents will appear here.',
      );
    }
    return _RefreshableList(
      children: items
          .map(
            (item) => _RecordCard(
              icon: Icons.description_outlined,
              title: item.fileType.isEmpty
                  ? 'Document #${item.id}'
                  : item.fileType,
              subtitle: _join([item.uploadedAt, item.accessLevel]),
              body: item.fileLocation,
              footer: item.isProbablyDownloadable
                  ? 'Download available from Test Results'
                  : 'Preview only',
            ),
          )
          .toList(),
    );
  }
}

class _RefreshableList extends ConsumerWidget {
  final List<Widget> children;

  const _RefreshableList({required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(patientRecordsProvider);
        await ref.read(patientRecordsProvider.future);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, index) => children[index],
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemCount: children.length,
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final String footer;

  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                  if (footer.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(footer, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 60, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _join(List<String> values) {
  return values.where((value) => value.trim().isNotEmpty).join(' • ');
}
