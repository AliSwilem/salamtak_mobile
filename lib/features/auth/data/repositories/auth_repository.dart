import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  AuthRepository({required this.apiClient, required this.storageService});

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await apiClient.dio.post<dynamic>(
      ApiConstants.login,
      data: request.toFormData(),
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final loginResponse = LoginResponse.fromJson(_asJsonMap(response.data));
    if (loginResponse.accessToken.isEmpty) {
      throw const FormatException('Login response did not include a token.');
    }

    await storageService.saveToken(loginResponse.accessToken);

    return loginResponse;
  }

  Future<UserModel> getCurrentUser() async {
    final response = await apiClient.dio.get<dynamic>(ApiConstants.authMe);
    final responseJson = _asJsonMap(response.data);
    final nestedUser =
        _tryJsonMap(responseJson['user']) ?? _tryJsonMap(responseJson['data']);
    final userJson = <String, dynamic>{
      ...?nestedUser,
      if (nestedUser == null) ...responseJson,
    };

    final topLevelRole = responseJson['role'];
    if (userJson['role'] == null && topLevelRole != null) {
      userJson['role'] = topLevelRole;
    }

    return UserModel.fromJson(userJson);
  }

  Future<bool> hasToken() async {
    final token = await storageService.getToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> logout() async {
    await storageService.clearToken();
  }

  Map<String, dynamic> _asJsonMap(dynamic value) {
    final parsed = _tryJsonMap(value);
    if (parsed == null) {
      throw const FormatException('The server returned an invalid response.');
    }
    return parsed;
  }

  Map<String, dynamic>? _tryJsonMap(dynamic value) {
    if (value is! Map) {
      return null;
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
