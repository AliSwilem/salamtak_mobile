class DoctorRegisterRequest {
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String specialization;
  final String phone;
  final String medicalLicenseNumber;
  final int yearsOfExperience;
  final int hospitalId;

  const DoctorRegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    required this.specialization,
    required this.phone,
    required this.medicalLicenseNumber,
    required this.yearsOfExperience,
    required this.hospitalId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'full_name': fullName,
      'specialization': specialization,
      'phone': phone,
      'medical_license_number': medicalLicenseNumber,
      'years_of_experience': yearsOfExperience,
      'HospitalID': hospitalId,
    };
  }
}
