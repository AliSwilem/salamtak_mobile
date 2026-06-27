import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/doctor_dashboard_model.dart';
import '../data/models/doctor_profile_model.dart';
import 'providers/doctor_providers.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _bioController = TextEditingController();
  final _achievementsController = TextEditingController();
  final _languagesController = TextEditingController();
  final _clinicController = TextEditingController();
  int? _loadedProfileId;

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _hospitalController.dispose();
    _bioController.dispose();
    _achievementsController.dispose();
    _languagesController.dispose();
    _clinicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(doctorProfileProvider);
    final action = ref.watch(doctorProfileActionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(doctorProfileProvider);
          await ref.read(doctorProfileProvider.future);
        },
        child: data.when(
          loading: () => const _LoadingProfile(),
          error: (error, _) => _ErrorProfile(
            message: _friendlyError(error),
            onRetry: () => ref.invalidate(doctorProfileProvider),
          ),
          data: (profileData) {
            _fillControllers(profileData.profile);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileHeader(data: profileData),
                const SizedBox(height: 16),
                _StatsRow(stats: profileData.stats),
                const SizedBox(height: 16),
                _ProfileForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  specializationController: _specializationController,
                  phoneController: _phoneController,
                  experienceController: _experienceController,
                  hospitalController: _hospitalController,
                  bioController: _bioController,
                  achievementsController: _achievementsController,
                  languagesController: _languagesController,
                  clinicController: _clinicController,
                  isSaving: action.isLoading,
                  onSave: _saveProfile,
                ),
                const SizedBox(height: 16),
                _ActivityCard(activity: profileData.activity),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Profile photo upload is deferred until file picking/upload UX is added.',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _fillControllers(DoctorProfileModel profile) {
    if (_loadedProfileId == profile.id) return;
    _loadedProfileId = profile.id;
    _nameController.text = profile.fullName;
    _specializationController.text = profile.specialization;
    _phoneController.text = profile.phone;
    _experienceController.text = profile.yearsOfExperience == 0
        ? ''
        : '${profile.yearsOfExperience}';
    _hospitalController.text = profile.hospitalId?.toString() ?? '';
    _bioController.text = profile.bio;
    _achievementsController.text = profile.achievements;
    _languagesController.text = profile.languages;
    _clinicController.text = profile.clinicName;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref
        .read(doctorProfileActionProvider.notifier)
        .save(
          DoctorProfileUpdateRequest(
            fullName: _nameController.text,
            specialization: _specializationController.text,
            phone: _phoneController.text,
            yearsOfExperience: int.tryParse(_experienceController.text.trim()),
            hospitalId: int.tryParse(_hospitalController.text.trim()),
            bio: _bioController.text,
            achievements: _achievementsController.text,
            languages: _languagesController.text,
            clinicName: _clinicController.text,
          ),
        );
    if (!mounted) return;
    if (result == null) {
      _showSnack(_actionError(), isError: true);
      return;
    }
    _loadedProfileId = null;
    _showSnack('Profile saved.');
  }

  String _actionError() {
    final error = ref.read(doctorProfileActionProvider).error;
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 422) return 'Please check profile fields.';
      if (statusCode == 401 || statusCode == 403) {
        return 'Your doctor session has expired.';
      }
    }
    return 'Could not save profile. Please try again.';
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final DoctorProfileData data;

  const _ProfileHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final profile = data.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.person_outline)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName.isEmpty ? 'Doctor' : profile.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(profile.specialization),
                  if (profile.email.isNotEmpty) Text(profile.email),
                  Text(
                    '${profile.averageRating.toStringAsFixed(1)} ★ • ${profile.reviewsCount} reviews',
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

class _StatsRow extends StatelessWidget {
  final DoctorProfileStatsModel stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Patients', value: '${stats.patients}'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Appointments',
            value: '${stats.appointments}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(label: 'Reviews', value: '${stats.reviews}'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController specializationController;
  final TextEditingController phoneController;
  final TextEditingController experienceController;
  final TextEditingController hospitalController;
  final TextEditingController bioController;
  final TextEditingController achievementsController;
  final TextEditingController languagesController;
  final TextEditingController clinicController;
  final bool isSaving;
  final VoidCallback onSave;

  const _ProfileForm({
    required this.formKey,
    required this.nameController,
    required this.specializationController,
    required this.phoneController,
    required this.experienceController,
    required this.hospitalController,
    required this.bioController,
    required this.achievementsController,
    required this.languagesController,
    required this.clinicController,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Public details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _requiredField(nameController, 'Full name'),
              const SizedBox(height: 12),
              _requiredField(specializationController, 'Specialization'),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: experienceController,
                decoration: const InputDecoration(
                  labelText: 'Years of experience',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: hospitalController,
                decoration: const InputDecoration(labelText: 'Hospital ID'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: clinicController,
                decoration: const InputDecoration(labelText: 'Clinic name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: languagesController,
                decoration: const InputDecoration(labelText: 'Languages'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bioController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: achievementsController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Achievements'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Saving...' : 'Save profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requiredField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Required';
        return null;
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<DoctorActivityModel> activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (activity.isEmpty)
              const Text('No recent activity.')
            else
              ...activity
                  .take(5)
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_none),
                      title: Text(item.title.isEmpty ? 'Activity' : item.title),
                      subtitle: Text(item.message),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _LoadingProfile extends StatelessWidget {
  const _LoadingProfile();

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

class _ErrorProfile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorProfile({required this.message, required this.onRetry});

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
  return 'We could not load your profile. Pull to refresh or try again.';
}
