import 'user_model.dart';

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final String role;
  final UserModel? user;

  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.role,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = _asStringKeyedMap(json['user']);
    final user = userJson == null ? null : UserModel.fromJson(userJson);

    return LoginResponse(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      role: (json['role']?.toString() ?? user?.role ?? '').trim(),
      user: user,
    );
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is! Map) {
      return null;
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
