class PatientRegisterRequest {
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String gender;
  final String dateOfBirth;
  final String contactNumber;
  final String? address;
  final String? bloodType;
  final String? medicalHistory;

  const PatientRegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.contactNumber,
    this.address,
    this.bloodType,
    this.medicalHistory,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'full_name': fullName,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'contact_number': contactNumber,
      if (address?.trim().isNotEmpty == true) 'address': address!.trim(),
      if (bloodType?.trim().isNotEmpty == true) 'blood_type': bloodType!.trim(),
      if (medicalHistory?.trim().isNotEmpty == true)
        'medical_history': medicalHistory!.trim(),
    };
  }
}
