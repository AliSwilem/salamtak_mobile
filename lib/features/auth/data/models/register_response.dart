import 'user_model.dart';

class RegisterResponse {
  final String? accessToken;
  final String? tokenType;
  final String? role;
  final UserModel? user;
  final int? userId;
  final int? patientId;
  final int? doctorId;

  const RegisterResponse({
    this.accessToken,
    this.tokenType,
    this.role,
    this.user,
    this.userId,
    this.patientId,
    this.doctorId,
  });

  bool get hasToken => accessToken?.trim().isNotEmpty == true;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final nestedData = _asMap(json['data']);
    final payload = nestedData ?? json;
    final userJson = _asMap(payload['user']);
    final user = userJson == null ? null : UserModel.fromJson(userJson);

    return RegisterResponse(
      accessToken: _parseString(
        payload['access_token'] ?? payload['accessToken'],
      ),
      tokenType: _parseString(payload['token_type'] ?? payload['tokenType']),
      role: _parseString(payload['role'] ?? user?.role),
      user: user,
      userId: _parseInt(payload['UserID'] ?? payload['user_id'] ?? user?.id),
      patientId: _parseInt(payload['PatientID'] ?? payload['patient_id']),
      doctorId: _parseInt(payload['DoctorID'] ?? payload['doctor_id']),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) {
      return null;
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _parseString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
