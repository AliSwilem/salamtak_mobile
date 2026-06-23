import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/doctor_register_request.dart';
import '../data/models/hospital_model.dart';
import 'providers/auth_provider.dart';

class DoctorRegisterScreen extends ConsumerStatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  ConsumerState<DoctorRegisterScreen> createState() =>
      _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends ConsumerState<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _yearsController = TextEditingController();

  String? _specialization;
  int? _hospitalId;
  bool _acceptedTerms = false;

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
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _yearsController.dispose();
    super.dispose();
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
        .registerDoctor(
          DoctorRegisterRequest(
            username: email.split('@').first,
            email: email,
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            specialization: _specialization!,
            phone: _phoneController.text.trim(),
            medicalLicenseNumber: _licenseController.text.trim(),
            yearsOfExperience: int.parse(_yearsController.text.trim()),
            hospitalId: _hospitalId!,
          ),
        );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      return;
    }

    if (result.authenticated) {
      context.go('/doctor');
      return;
    }

    context.go(
      '/login',
      extra: 'Doctor account created successfully. Please log in.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final hospitalsState = ref.watch(hospitalsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/register'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Register as Doctor'),
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
                  Text(
                    'Create your professional healthcare account.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Account information',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _fullNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                              ),
                              validator: _required(
                                'Please enter your full name.',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: const InputDecoration(
                                labelText: 'Password',
                              ),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                              ),
                              validator: _required(
                                'Please enter your phone number.',
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Professional information',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _specialization,
                              decoration: const InputDecoration(
                                labelText: 'Specialization',
                              ),
                              items: _specializations
                                  .map(
                                    (specialization) => DropdownMenuItem(
                                      value: specialization,
                                      child: Text(specialization),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _specialization = value);
                              },
                              validator: (value) => value == null
                                  ? 'Please select your specialization.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _HospitalField(
                              state: hospitalsState,
                              selectedId: _hospitalId,
                              onChanged: (value) {
                                setState(() => _hospitalId = value);
                              },
                              onRetry: () => ref.invalidate(hospitalsProvider),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _licenseController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Medical license number',
                              ),
                              validator: _required(
                                'Please enter your medical license number.',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _yearsController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Years of experience',
                              ),
                              validator: (value) {
                                final years = int.tryParse(value?.trim() ?? '');
                                if (years == null) {
                                  return 'Please enter years of experience.';
                                }
                                if (years < 0 || years > 60) {
                                  return 'Enter a value between 0 and 60.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _acceptedTerms,
                              onChanged: (value) {
                                setState(() => _acceptedTerms = value ?? false);
                              },
                              title: const Text(
                                'I agree to the terms and privacy policy.',
                              ),
                            ),
                            if (authState.hasError &&
                                authState.errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                authState.errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : _register,
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Create Doctor Account'),
                              ),
                            ),
                            TextButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () => context.go('/login'),
                              child: const Text(
                                'Already have an account? Sign in',
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class _HospitalField extends StatelessWidget {
  final AsyncValue<List<HospitalModel>> state;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final VoidCallback onRetry;

  const _HospitalField({
    required this.state,
    required this.selectedId,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (hospitals) {
        if (hospitals.isEmpty) {
          return Row(
            children: [
              const Expanded(child: Text('No hospitals are available.')),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          );
        }

        return DropdownButtonFormField<int>(
          initialValue: selectedId,
          decoration: const InputDecoration(labelText: 'Hospital'),
          isExpanded: true,
          items: hospitals
              .map(
                (hospital) => DropdownMenuItem(
                  value: hospital.id,
                  child: Text(
                    hospital.location == null
                        ? hospital.name
                        : '${hospital.name} — ${hospital.location}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (value) =>
              value == null ? 'Please select a hospital.' : null,
        );
      },
      loading: () => const InputDecorator(
        decoration: InputDecoration(labelText: 'Hospital'),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Row(
        children: [
          const Expanded(child: Text('Unable to load hospitals.')),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
