class PatientProfileModel {
  final int? patientId;
  final String fullName;
  final String contactNumber;
  final String address;
  final String bloodType;
  final String medicalHistory;
  final String email;
  final String username;
  final String gender;
  final String dateOfBirth;

  const PatientProfileModel({
    this.patientId,
    required this.fullName,
    required this.contactNumber,
    required this.address,
    required this.bloodType,
    required this.medicalHistory,
    required this.email,
    required this.username,
    required this.gender,
    required this.dateOfBirth,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      patientId: _int(json['PatientID'] ?? json['patient_id']),
      fullName: _text(json['full_name'] ?? json['FullName']),
      contactNumber: _text(json['contact_number'] ?? json['ContactInfo']),
      address: _text(json['address'] ?? json['Address']),
      bloodType: _text(json['blood_type'] ?? json['BloodType']),
      medicalHistory: _text(json['medical_history'] ?? json['MedicalHistory']),
      email: _text(json['email'] ?? json['Email']),
      username: _text(json['username'] ?? json['Username']),
      gender: _text(json['gender'] ?? json['Gender']),
      dateOfBirth: _text(json['date_of_birth'] ?? json['DateOfBirth']),
    );
  }
}

class PatientProfileUpdate {
  final String fullName;
  final String contactNumber;
  final String address;
  final String bloodType;
  final String medicalHistory;

  const PatientProfileUpdate({
    required this.fullName,
    required this.contactNumber,
    required this.address,
    required this.bloodType,
    required this.medicalHistory,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName.trim(),
    'contact_number': contactNumber.trim(),
    'address': address.trim(),
    'blood_type': bloodType.trim(),
    'medical_history': medicalHistory.trim(),
  };
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _text(dynamic value) => value?.toString().trim() ?? '';
