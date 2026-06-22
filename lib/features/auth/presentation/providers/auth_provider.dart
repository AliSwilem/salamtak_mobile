import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/login_request.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    storageService: ref.watch(secureStorageProvider),
  );
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? role;
  final String? errorMessage;

  const AuthState._({
    required this.status,
    this.user,
    this.role,
    this.errorMessage,
  });

  const AuthState.initial() : this._(status: AuthStatus.initial);

  const AuthState.loading() : this._(status: AuthStatus.loading);

  const AuthState.authenticated({
    required UserModel? user,
    required String role,
  }) : this._(status: AuthStatus.authenticated, user: user, role: role);

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  const AuthState.failure(String message)
    : this._(status: AuthStatus.failure, errorMessage: message);

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasError => status == AuthStatus.failure;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  static const Set<String> _supportedRoles = {'patient', 'doctor'};

  @override
  AuthState build() => const AuthState.initial();

  Future<AuthState> login({
    required String username,
    required String password,
  }) async {
    state = const AuthState.loading();

    try {
      final response = await ref
          .read(authRepositoryProvider)
          .login(LoginRequest(username: username, password: password));
      final role = _normalizeRole(response.role, response.user?.role);

      if (!_supportedRoles.contains(role)) {
        await ref.read(authRepositoryProvider).logout();
        state = const AuthState.failure(
          'This account role is not supported in the mobile app.',
        );
        return state;
      }

      state = AuthState.authenticated(user: response.user, role: role);
    } catch (error) {
      state = AuthState.failure(_friendlyLoginError(error));
    }

    return state;
  }

  Future<AuthState> getCurrentUser() async {
    state = const AuthState.loading();
    final repository = ref.read(authRepositoryProvider);

    try {
      if (!await repository.hasToken()) {
        state = const AuthState.unauthenticated();
        return state;
      }

      final user = await repository.getCurrentUser();
      final role = _normalizeRole(user.role, null);

      if (!_supportedRoles.contains(role)) {
        await repository.logout();
        state = const AuthState.failure(
          'This account role is not supported in the mobile app.',
        );
        return state;
      }

      state = AuthState.authenticated(user: user, role: role);
    } catch (error) {
      if (_isUnauthorized(error)) {
        await repository.logout();
      }
      state = AuthState.failure(_friendlySessionError(error));
    }

    return state;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState.unauthenticated();
  }

  String _normalizeRole(String? primary, String? fallback) {
    return (primary?.trim().isNotEmpty == true ? primary : fallback)
            ?.trim()
            .toLowerCase() ??
        '';
  }

  bool _isUnauthorized(Object error) {
    if (error is! DioException) {
      return false;
    }
    final statusCode = error.response?.statusCode;
    return statusCode == 401 || statusCode == 403;
  }

  String _friendlyLoginError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
        return 'Invalid username or password.';
      }
      if (_isConnectionProblem(error)) {
        return 'Unable to reach the server. Check your connection and try again.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'The server is unavailable right now. Please try again shortly.';
      }
    }
    if (error is FormatException) {
      return 'The server returned an unexpected response. Please try again.';
    }
    return 'Login failed. Please try again.';
  }

  String _friendlySessionError(Object error) {
    if (_isUnauthorized(error)) {
      return 'Your session has expired. Please log in again.';
    }
    if (error is DioException && _isConnectionProblem(error)) {
      return 'Unable to verify your session. Please log in or try again later.';
    }
    return 'We could not restore your session. Please log in again.';
  }

  bool _isConnectionProblem(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}
