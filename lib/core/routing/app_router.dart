import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/doctor_register_screen.dart';
import '../../features/auth/presentation/patient_register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/register_role_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/doctor/presentation/doctor_home_screen.dart';
import '../../features/patient/presentation/patient_home_screen.dart';

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

      final homeRoute = authState.role == 'doctor' ? '/doctor' : '/patient';

      if (isPublicRoute || location != homeRoute) {
        return homeRoute;
      }

      return null;
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
      GoRoute(
        path: '/patient',
        builder: (context, state) => const PatientHomeScreen(),
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
