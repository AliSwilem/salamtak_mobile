import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/doctor_register_screen.dart';
import '../../features/auth/presentation/patient_register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/register_role_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/doctor/presentation/doctor_home_screen.dart';
import '../../features/patient/presentation/appointment_details_screen.dart';
import '../../features/patient/presentation/book_appointment_screen.dart';
import '../../features/patient/presentation/doctor_profile_screen.dart';
import '../../features/patient/presentation/patient_appointments_screen.dart';
import '../../features/patient/presentation/patient_doctors_screen.dart';
import '../../features/patient/presentation/patient_home_screen.dart';
import '../../features/patient/presentation/patient_more_screen.dart';
import '../../features/patient/presentation/patient_placeholder_screen.dart';
import '../../features/patient/presentation/patient_profile_screen.dart';
import '../../features/patient/presentation/patient_shell.dart';

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
        return location == '/doctor' ? null : '/doctor';
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
                builder: (context, state) => const PatientPlaceholderScreen(
                  title: 'Records',
                  message:
                      'Health record browsing is planned for the next patient sprint.',
                  icon: Icons.folder_outlined,
                ),
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
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/doctor',
        builder: (context, state) => const DoctorHomeScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
