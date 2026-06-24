import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/patient_doctor_profile_model.dart';
import 'providers/patient_providers.dart';

class DoctorProfileScreen extends ConsumerWidget {
  final int doctorId;

  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(doctorProfileProvider(doctorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ProfileError(
          onRetry: () => ref.invalidate(doctorProfileProvider(doctorId)),
        ),
        data: (doctor) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(doctorProfileProvider(doctorId));
            await ref.read(doctorProfileProvider(doctorId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _HeaderCard(doctor: doctor),
              const SizedBox(height: 12),
              _AboutCard(doctor: doctor),
              const SizedBox(height: 12),
              _AchievementsCard(doctor: doctor),
              const SizedBox(height: 12),
              _ReviewsCard(reviews: doctor.recentReviews),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push('/patient/book'),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Book appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PatientDoctorProfileModel doctor;

  const _HeaderCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.person_outline, size: 44),
            ),
            const SizedBox(height: 12),
            Text(
              doctor.fullName.isEmpty ? 'Doctor' : doctor.fullName,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              doctor.specialization.isEmpty
                  ? 'General Practice'
                  : doctor.specialization,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.star, size: 18),
                  label: Text(
                    '${doctor.averageRating.toStringAsFixed(1)} (${doctor.reviewsCount} reviews)',
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.work_outline, size: 18),
                  label: Text('${doctor.yearsOfExperience} years'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final PatientDoctorProfileModel doctor;

  const _AboutCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(
              doctor.bio.isEmpty
                  ? 'Profile details will be added soon.'
                  : doctor.bio,
            ),
            const Divider(height: 24),
            if (doctor.languages.isNotEmpty)
              _InfoLine(
                icon: Icons.language,
                label: 'Languages',
                value: doctor.languages,
              ),
            if (doctor.clinicName.isNotEmpty)
              _InfoLine(
                icon: Icons.local_hospital_outlined,
                label: 'Clinic',
                value: doctor.clinicName,
              ),
            if (doctor.phone.isNotEmpty)
              _InfoLine(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: doctor.phone,
              ),
          ],
        ),
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  final PatientDoctorProfileModel doctor;

  const _AchievementsCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final items = doctor.achievementItems;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Text('No achievements have been published yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) => Chip(label: Text(item))).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  final List<PatientDoctorReviewModel> reviews;

  const _ReviewsCard({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent reviews',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (reviews.isEmpty)
              const Text('No reviews available yet.')
            else
              ...reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  review.patientName.isEmpty
                                      ? 'Patient'
                                      : review.patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.star,
                                color: Colors.amber.shade700,
                                size: 18,
                              ),
                              Text('${review.rating}/5'),
                            ],
                          ),
                          if (review.comment.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(review.comment),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).hintColor),
          const SizedBox(width: 8),
          Text('$label: '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('Doctor profile could not be loaded.'),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
