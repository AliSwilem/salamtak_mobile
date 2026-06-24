class PatientDoctorProfileModel {
  final int id;
  final String fullName;
  final String specialization;
  final String email;
  final String phone;
  final int yearsOfExperience;
  final String? photoUrl;
  final String bio;
  final String achievements;
  final String languages;
  final String clinicName;
  final double averageRating;
  final int reviewsCount;
  final List<PatientDoctorReviewModel> recentReviews;

  const PatientDoctorProfileModel({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.email,
    required this.phone,
    required this.yearsOfExperience,
    required this.photoUrl,
    required this.bio,
    required this.achievements,
    required this.languages,
    required this.clinicName,
    required this.averageRating,
    required this.reviewsCount,
    required this.recentReviews,
  });

  factory PatientDoctorProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientDoctorProfileModel(
      id: _int(json['DoctorID'] ?? json['doctor_id']) ?? 0,
      fullName: _text(json['FullName'] ?? json['full_name']),
      specialization: _text(json['Specialization'] ?? json['specialization']),
      email: _text(json['Email'] ?? json['email']),
      phone: _text(json['Phone'] ?? json['phone']),
      yearsOfExperience:
          _int(json['YearsOfExperience'] ?? json['years_of_experience']) ?? 0,
      photoUrl: _nullableText(json['PhotoUrl'] ?? json['photo_url']),
      bio: _text(json['Bio'] ?? json['bio']),
      achievements: _text(json['Achievements'] ?? json['achievements']),
      languages: _text(json['Languages'] ?? json['languages']),
      clinicName: _text(json['ClinicName'] ?? json['clinic_name']),
      averageRating:
          _double(json['AverageRating'] ?? json['average_rating']) ?? 0,
      reviewsCount: _int(json['ReviewsCount'] ?? json['reviews_count']) ?? 0,
      recentReviews: _list(
        json['RecentReviews'] ?? json['recent_reviews'],
      ).map(PatientDoctorReviewModel.fromJson).toList(),
    );
  }

  List<String> get achievementItems => achievements
      .split(RegExp(r'\r?\n|;'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

class PatientDoctorReviewModel {
  final int id;
  final int appointmentId;
  final int rating;
  final String comment;
  final String createdAt;
  final String patientName;

  const PatientDoctorReviewModel({
    required this.id,
    required this.appointmentId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.patientName,
  });

  factory PatientDoctorReviewModel.fromJson(Map<String, dynamic> json) {
    return PatientDoctorReviewModel(
      id: _int(json['ReviewID'] ?? json['review_id']) ?? 0,
      appointmentId: _int(json['AppointmentID'] ?? json['appointment_id']) ?? 0,
      rating: _int(json['Rating'] ?? json['rating']) ?? 0,
      comment: _text(json['Comment'] ?? json['comment']),
      createdAt: _text(json['CreatedAt'] ?? json['created_at']),
      patientName: _text(json['PatientName'] ?? json['patient_name']),
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

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}
