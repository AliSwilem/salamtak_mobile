class PatientDoctorModel {
  final int id;
  final String fullName;
  final String specialization;
  final int yearsOfExperience;
  final double averageRating;
  final int reviewsCount;
  final String clinicName;
  final String? photoUrl;

  const PatientDoctorModel({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.yearsOfExperience,
    required this.averageRating,
    required this.reviewsCount,
    required this.clinicName,
    this.photoUrl,
  });

  factory PatientDoctorModel.fromJson(Map<String, dynamic> json) {
    return PatientDoctorModel(
      id: _int(json['DoctorID'] ?? json['doctor_id']) ?? 0,
      fullName: _text(json['FullName'] ?? json['full_name']),
      specialization: _text(json['Specialization'] ?? json['specialization']),
      yearsOfExperience:
          _int(json['YearsOfExperience'] ?? json['years_of_experience']) ?? 0,
      averageRating:
          _double(json['AverageRating'] ?? json['average_rating']) ?? 0,
      reviewsCount: _int(json['ReviewsCount'] ?? json['reviews_count']) ?? 0,
      clinicName: _text(json['ClinicName'] ?? json['clinic_name']),
      photoUrl: _nullableText(json['PhotoUrl'] ?? json['photo_url']),
    );
  }
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String? _nullableText(dynamic value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}
