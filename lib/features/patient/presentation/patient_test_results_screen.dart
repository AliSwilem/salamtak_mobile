import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/patient_records_model.dart';
import 'providers/patient_providers.dart';

class PatientTestResultsScreen extends ConsumerWidget {
  const PatientTestResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(patientTestResultsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test Results'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Laboratory'),
              Tab(text: 'Imaging'),
              Tab(text: 'Other'),
            ],
          ),
        ),
        body: results.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            onRetry: () => ref.invalidate(patientTestResultsProvider),
          ),
          data: (items) {
            final laboratory = items
                .where(
                  (item) => item.category == PatientDocumentCategory.laboratory,
                )
                .toList();
            final imaging = items
                .where(
                  (item) => item.category == PatientDocumentCategory.imaging,
                )
                .toList();
            final other = items
                .where((item) => item.category == PatientDocumentCategory.other)
                .toList();
            return TabBarView(
              children: [
                _ResultsList(
                  items: laboratory,
                  emptyTitle: 'No laboratory results',
                ),
                _ResultsList(items: imaging, emptyTitle: 'No imaging results'),
                _ResultsList(items: other, emptyTitle: 'No other documents'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<PatientDocumentModel> items;
  final String emptyTitle;

  const _ResultsList({required this.items, required this.emptyTitle});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.science_outlined,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            emptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Results shared by your care team will appear here.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _ResultCard(result: items[index]),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: items.length,
    );
  }
}

class _ResultCard extends StatelessWidget {
  final PatientDocumentModel result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final title = result.fileType.isEmpty
        ? 'Result #${result.id}'
        : result.fileType;
    final date = result.uploadedAt.isNotEmpty
        ? result.uploadedAt
        : result.dateCreated;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.description_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (date.isNotEmpty) Text(date),
                    ],
                  ),
                ),
              ],
            ),
            if (result.fileLocation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                result.fileLocation,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.download_outlined),
              label: Text(
                result.isProbablyDownloadable
                    ? 'Download coming soon'
                    : 'Download not available',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Test results could not be loaded.'),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
