import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/patient_profile_model.dart';
import 'providers/patient_providers.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  final _medicalHistory = TextEditingController();
  String _bloodType = '';
  bool _editing = false;
  int? _loadedPatientId;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _fullName.dispose();
    _contact.dispose();
    _address.dispose();
    _medicalHistory.dispose();
    super.dispose();
  }

  void _loadForm(PatientProfileModel profile) {
    if (_loadedPatientId == profile.patientId) return;
    _loadedPatientId = profile.patientId;
    _fullName.text = profile.fullName;
    _contact.text = profile.contactNumber;
    _address.text = profile.address;
    _medicalHistory.text = profile.medicalHistory;
    _bloodType = profile.bloodType;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(patientProfileProvider.notifier)
        .save(
          PatientProfileUpdate(
            fullName: _fullName.text,
            contactNumber: _contact.text,
            address: _address.text,
            bloodType: _bloodType,
            medicalHistory: _medicalHistory.text,
          ),
        );
    if (!mounted) return;
    if (success) {
      setState(() {
        _editing = false;
        _loadedPatientId = null;
      });
      ref.invalidate(patientHomeProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (state.hasValue && !_editing)
            IconButton(
              tooltip: 'Edit profile',
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ProfileError(
          onRetry: () => ref.invalidate(patientProfileProvider),
        ),
        data: (profile) {
          _loadForm(profile);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: const Icon(Icons.person_outline, size: 46),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _Field(
                  controller: _fullName,
                  label: 'Full name',
                  enabled: _editing,
                  validator: _required('Please enter your full name.'),
                ),
                _Field(
                  controller: _contact,
                  label: 'Contact number',
                  enabled: _editing,
                  keyboardType: TextInputType.phone,
                  validator: _required('Please enter your contact number.'),
                ),
                _Field(
                  controller: _address,
                  label: 'Address',
                  enabled: _editing,
                  maxLines: 2,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _bloodType.isEmpty ? null : _bloodType,
                    decoration: const InputDecoration(labelText: 'Blood type'),
                    items: _bloodTypes
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: _editing
                        ? (value) => setState(() => _bloodType = value ?? '')
                        : null,
                  ),
                ),
                _Field(
                  controller: _medicalHistory,
                  label: 'Medical history',
                  enabled: _editing,
                  maxLines: 4,
                ),
                _ReadOnlyField(label: 'Email', value: profile.email),
                _ReadOnlyField(label: 'Username', value: profile.username),
                _ReadOnlyField(
                  label: 'Gender',
                  value: _genderLabel(profile.gender),
                ),
                _ReadOnlyField(
                  label: 'Date of birth',
                  value: profile.dateOfBirth,
                ),
                if (_editing) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _loadedPatientId = null;
                              _editing = false;
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: state.isLoading ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String? Function(String?) _required(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  String _genderLabel(String value) {
    if (value.isEmpty) return 'Not set';
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value.isEmpty ? 'Not set' : value,
        enabled: false,
        decoration: InputDecoration(labelText: label),
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
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Your profile could not be loaded.'),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
