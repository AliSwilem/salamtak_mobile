class UserModel {
  final int? id;
  final String? username;
  final String? email;
  final String? fullName;
  final String? role;

  const UserModel({
    this.id,
    this.username,
    this.email,
    this.fullName,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseInt(json['id'] ?? json['UserID'] ?? json['UserId']),
      username: _parseString(json['username'] ?? json['Username']),
      email: _parseString(json['email'] ?? json['Email']),
      fullName: _parseString(
        json['full_name'] ?? json['FullName'] ?? json['name'],
      ),
      role: _parseString(json['role'] ?? json['Role']),
    );
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
    final parsed = value?.toString().trim();
    return parsed == null || parsed.isEmpty ? null : parsed;
  }
}
