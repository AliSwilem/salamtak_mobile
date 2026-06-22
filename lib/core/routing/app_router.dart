import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
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
      final isPublicRoute = location == '/splash' || location == '/login';

      if (authState.status == AuthStatus.initial) {
        return location == '/splash' ? null : '/splash';
      }

      if (authState.isLoading) {
        return isPublicRoute ? null : '/splash';
      }

      if (!authState.isAuthenticated) {
        return location == '/login' ? null : '/login';
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
