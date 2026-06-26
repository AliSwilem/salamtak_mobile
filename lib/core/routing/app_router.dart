import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/doctor_register_screen.dart';
import '../../features/auth/presentation/patient_register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/register_role_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/doctor/data/models/doctor_appointment_model.dart';
import '../../features/doctor/presentation/doctor_appointment_details_screen.dart';
import '../../features/doctor/presentation/doctor_appointments_screen.dart';
import '../../features/doctor/presentation/doctor_availability_screen.dart';
import '../../features/doctor/presentation/doctor_home_screen.dart';
import '../../features/doctor/presentation/doctor_more_screen.dart';
import '../../features/doctor/presentation/doctor_patient_medical_file_screen.dart';
import '../../features/doctor/presentation/doctor_patients_screen.dart';
import '../../features/doctor/presentation/doctor_placeholder_screen.dart';
import '../../features/doctor/presentation/doctor_shell.dart';
import '../../features/patient/presentation/appointment_details_screen.dart';
import '../../features/patient/presentation/book_appointment_screen.dart';
import '../../features/patient/presentation/doctor_profile_screen.dart';
import '../../features/patient/presentation/patient_appointments_screen.dart';
import '../../features/patient/presentation/patient_coming_soon_screen.dart';
import '../../features/patient/presentation/patient_doctors_screen.dart';
import '../../features/patient/presentation/patient_home_screen.dart';
import '../../features/patient/presentation/patient_more_screen.dart';
import '../../features/patient/presentation/patient_notifications_screen.dart';
import '../../features/patient/presentation/patient_placeholder_screen.dart';
import '../../features/patient/presentation/patient_profile_screen.dart';
import '../../features/patient/presentation/patient_records_screen.dart';
import '../../features/patient/presentation/patient_shell.dart';
import '../../features/patient/presentation/patient_test_results_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  ref.listen<AuthState>(
    authControllerProvider,
    (_, _) => refreshNotifier.refresh(),
  );
  ref.onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isPublicRoute =
          location == '/splash' ||
          location == '/login' ||
          location == '/register' ||
          location.startsWith('/register/');

      if (authState.status == AuthStatus.initial) {
        return location == '/splash' ? null : '/splash';
      }

      if (authState.isLoading) {
        return isPublicRoute ? null : '/splash';
      }

      if (!authState.isAuthenticated) {
        final isAuthEntryRoute =
            location == '/login' ||
            location == '/register' ||
            location.startsWith('/register/');
        return isAuthEntryRoute ? null : '/login';
      }

      if (authState.role == 'doctor') {
        return location.startsWith('/doctor') ? null : '/doctor';
      }

      if (authState.role == 'patient') {
        return location.startsWith('/patient') ? null : '/patient';
      }

      return '/login';
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(message: state.extra as String?),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterRoleScreen(),
      ),
      GoRoute(
        path: '/register/patient',
        builder: (context, state) => const PatientRegisterScreen(),
      ),
      GoRoute(
        path: '/register/doctor',
        builder: (context, state) => const DoctorRegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            PatientShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient',
                builder: (context, state) => const PatientHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/appointments',
                builder: (context, state) => const PatientAppointmentsScreen(),
              ),
              GoRoute(
                path: '/patient/book',
                builder: (context, state) => const BookAppointmentScreen(),
              ),
              GoRoute(
                path: '/patient/appointments/:appointmentId',
                builder: (context, state) {
                  final appointmentId = int.tryParse(
                    state.pathParameters['appointmentId'] ?? '',
                  );
                  if (appointmentId == null) {
                    return const PatientPlaceholderScreen(
                      title: 'Appointment not found',
                      message: 'The appointment id is invalid.',
                      icon: Icons.error_outline,
                    );
                  }
                  return AppointmentDetailsScreen(appointmentId: appointmentId);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/doctors',
                builder: (context, state) => const PatientDoctorsScreen(),
              ),
              GoRoute(
                path: '/patient/doctors/:doctorId',
                builder: (context, state) {
                  final doctorId = int.tryParse(
                    state.pathParameters['doctorId'] ?? '',
                  );
                  if (doctorId == null) {
                    return const PatientPlaceholderScreen(
                      title: 'Doctor not found',
                      message: 'The doctor id is invalid.',
                      icon: Icons.error_outline,
                    );
                  }
                  return DoctorProfileScreen(doctorId: doctorId);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/records',
                builder: (context, state) => const PatientRecordsScreen(),
              ),
              GoRoute(
                path: '/patient/test-results',
                builder: (context, state) => const PatientTestResultsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patient/more',
                builder: (context, state) => const PatientMoreScreen(),
              ),
              GoRoute(
                path: '/patient/profile',
                builder: (context, state) => const PatientProfileScreen(),
              ),
              GoRoute(
                path: '/patient/notifications',
                builder: (context, state) => const PatientNotificationsScreen(),
              ),
              GoRoute(
                path: '/patient/coming-soon/:feature',
                builder: (context, state) {
                  final feature = state.pathParameters['feature'] ?? '';
                  final config = _comingSoonConfig(feature);
                  return PatientComingSoonScreen(
                    title: config.title,
                    message: config.message,
                    icon: config.icon,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DoctorShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/doctor',
                builder: (context, state) => const DoctorHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/doctor/appointments',
                builder: (context, state) => const DoctorAppointmentsScreen(),
              ),
              GoRoute(
                path: '/doctor/appointments/:appointmentId',
                builder: (context, state) {
                  final appointment = state.extra;
                  if (appointment is DoctorAppointmentModel) {
                    return DoctorAppointmentDetailsScreen(
                      appointment: appointment,
                    );
                  }
                  return const DoctorPlaceholderScreen(
                    title: 'Appointment not loaded',
                    message:
                        'Open appointment details from the appointments list because the backend does not provide a direct doctor details endpoint yet.',
                    icon: Icons.event_busy_outlined,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/doctor/patients',
                builder: (context, state) => const DoctorPatientsScreen(),
              ),
              GoRoute(
                path: '/doctor/patients/:patientId',
                builder: (context, state) {
                  final patientId = int.tryParse(
                    state.pathParameters['patientId'] ?? '',
                  );
                  if (patientId == null) {
                    return const DoctorPlaceholderScreen(
                      title: 'Patient not found',
                      message: 'The patient id is invalid.',
                      icon: Icons.error_outline,
                    );
                  }
                  return DoctorPatientMedicalFileScreen(patientId: patientId);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/doctor/availability',
                builder: (context, state) => const DoctorAvailabilityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/doctor/more',
                builder: (context, state) => const DoctorMoreScreen(),
              ),
              GoRoute(
                path: '/doctor/profile',
                builder: (context, state) => const DoctorPlaceholderScreen(
                  title: 'Profile',
                  message:
                      'Doctor profile editing will be implemented in a later sprint.',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

({String title, String message, IconData icon}) _comingSoonConfig(
  String feature,
) {
  switch (feature) {
    case 'assistant':
      return (
        title: 'AI Assistant',
        message:
            'The AI assistant experience is planned for a future sprint and does not call the backend yet.',
        icon: Icons.smart_toy_outlined,
      );
    case 'ocr':
      return (
        title: 'OCR',
        message:
            'Medical document OCR will be added later. No files are uploaded from this placeholder.',
        icon: Icons.document_scanner_outlined,
      );
    case 'kidney-stone':
      return (
        title: 'Kidney Stone Analysis',
        message:
            'Kidney stone image analysis is coming soon and is intentionally disabled for now.',
        icon: Icons.biotech_outlined,
      );
    case 'prediction':
      return (
        title: 'Disease Prediction',
        message:
            'Disease prediction models are planned for a later sprint and are not connected yet.',
        icon: Icons.analytics_outlined,
      );
    default:
      return (
        title: 'Coming Soon',
        message: 'This patient feature is planned for a future sprint.',
        icon: Icons.hourglass_empty,
      );
  }
}
