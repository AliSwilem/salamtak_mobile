import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/patient_register_request.dart';
import 'providers/auth_provider.dart';

class PatientRegisterScreen extends ConsumerStatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  ConsumerState<PatientRegisterScreen> createState() =>
      _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends ConsumerState<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  String? _bloodType;
  bool _acceptedTerms = false;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _dateOfBirth = selected;
      _dateOfBirthController.text = _formatDate(selected);
    });
  }

  Future<void> _register() async {
    if (ref.read(authControllerProvider).isLoading ||
        !_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and privacy policy.'),
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final result = await ref
        .read(authControllerProvider.notifier)
        .registerPatient(
          PatientRegisterRequest(
            username: _usernameFromEmail(email),
            email: email,
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            gender: _gender!,
            dateOfBirth: _formatDate(_dateOfBirth!),
            contactNumber: _phoneController.text.trim(),
            address: _addressController.text,
            bloodType: _bloodType,
            medicalHistory: _medicalHistoryController.text,
          ),
        );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      return;
    }

    if (result.authenticated) {
      context.go('/patient');
      return;
    }

    context.go(
      '/login',
      extra: 'Patient account created successfully. Please log in.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return _RegistrationPage(
      title: 'Register as Patient',
      subtitle: 'Create your patient account and health profile.',
      onBack: () => context.go('/register'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle('Account information'),
            TextFormField(
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: _required('Please enter your full name.'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Password'),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle('Personal information'),
            TextFormField(
              controller: _dateOfBirthController,
              readOnly: true,
              onTap: _pickDateOfBirth,
              decoration: const InputDecoration(
                labelText: 'Date of birth',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (_) => _dateOfBirth == null
                  ? 'Please select your date of birth.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _gender = value),
              validator: (value) =>
                  value == null ? 'Please select your gender.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Contact number'),
              validator: _required('Please enter your contact number.'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('Medical information'),
            DropdownButtonFormField<String>(
              initialValue: _bloodType,
              decoration: const InputDecoration(
                labelText: 'Blood type (optional)',
              ),
              items: _bloodTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _bloodType = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _medicalHistoryController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Medical history (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _acceptedTerms,
              onChanged: (value) {
                setState(() => _acceptedTerms = value ?? false);
              },
              title: const Text('I agree to the terms and privacy policy.'),
            ),
            if (authState.hasError && authState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                authState.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: authState.isLoading ? null : _register,
                child: authState.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Patient Account'),
              ),
            ),
            TextButton(
              onPressed: authState.isLoading
                  ? null
                  : () => context.go('/login'),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }

  String? Function(String?) _required(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _usernameFromEmail(String email) => email.split('@').first;
}

class _RegistrationPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget child;

  const _RegistrationPage({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(title),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
