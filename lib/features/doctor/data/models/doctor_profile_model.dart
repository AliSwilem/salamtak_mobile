import 'doctor_dashboard_model.dart';

class DoctorProfileModel {
  final int id;
  final String fullName;
  final String specialization;
  final String email;
  final String phone;
  final int yearsOfExperience;
  final int? hospitalId;
  final int? userId;
  final String photoUrl;
  final String bio;
  final String achievements;
  final String languages;
  final String clinicName;
  final double averageRating;
  final int reviewsCount;

  const DoctorProfileModel({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.email,
    required this.phone,
    required this.yearsOfExperience,
    required this.hospitalId,
    required this.userId,
    required this.photoUrl,
    required this.bio,
    required this.achievements,
    required this.languages,
    required this.clinicName,
    required this.averageRating,
    required this.reviewsCount,
  });

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    return DoctorProfileModel(
      id: _int(json['DoctorID'] ?? json['doctor_id']),
      fullName: _text(json['FullName'] ?? json['full_name']),
      specialization: _text(json['Specialization'] ?? json['specialization']),
      email: _text(json['Email'] ?? json['email']),
      phone: _text(json['Phone'] ?? json['phone']),
      yearsOfExperience: _int(
        json['YearsOfExperience'] ?? json['years_of_experience'],
      ),
      hospitalId: _nullableInt(json['HospitalID'] ?? json['hospital_id']),
      userId: _nullableInt(json['UserID'] ?? json['user_id']),
      photoUrl: _text(json['PhotoUrl'] ?? json['photo_url']),
      bio: _text(json['Bio'] ?? json['bio']),
      achievements: _text(json['Achievements'] ?? json['achievements']),
      languages: _text(json['Languages'] ?? json['languages']),
      clinicName: _text(json['ClinicName'] ?? json['clinic_name']),
      averageRating: _double(json['AverageRating'] ?? json['average_rating']),
      reviewsCount: _int(json['ReviewsCount'] ?? json['reviews_count']),
    );
  }
}

class DoctorProfileUpdateRequest {
  final String fullName;
  final String specialization;
  final String phone;
  final int? yearsOfExperience;
  final int? hospitalId;
  final String bio;
  final String achievements;
  final String languages;
  final String clinicName;

  const DoctorProfileUpdateRequest({
    required this.fullName,
    required this.specialization,
    required this.phone,
    required this.yearsOfExperience,
    required this.hospitalId,
    required this.bio,
    required this.achievements,
    required this.languages,
    required this.clinicName,
  });

  Map<String, dynamic> toJson() => {
    'FullName': fullName.trim(),
    'Specialization': specialization.trim(),
    'Phone': phone.trim(),
    if (yearsOfExperience != null) 'YearsOfExperience': yearsOfExperience,
    'HospitalID': hospitalId,
    'Bio': bio.trim(),
    'Achievements': achievements.trim(),
    'Languages': languages.trim(),
    'ClinicName': clinicName.trim(),
  };
}

class DoctorProfileStatsModel {
  final int patients;
  final int appointments;
  final int reviews;
  final double averageRating;

  const DoctorProfileStatsModel({
    required this.patients,
    required this.appointments,
    required this.reviews,
    required this.averageRating,
  });

  factory DoctorProfileStatsModel.fromJson(Map<String, dynamic> json) {
    return DoctorProfileStatsModel(
      patients: _int(json['patients'] ?? json['Patients']),
      appointments: _int(json['appointments'] ?? json['Appointments']),
      reviews: _int(json['reviews'] ?? json['Reviews']),
      averageRating: _double(json['average_rating'] ?? json['AverageRating']),
    );
  }
}

class DoctorProfileData {
  final DoctorProfileModel profile;
  final DoctorProfileStatsModel stats;
  final List<DoctorActivityModel> activity;

  const DoctorProfileData({
    required this.profile,
    required this.stats,
    required this.activity,
  });
}

int _int(dynamic value) => _nullableInt(value) ?? 0;

int? _nullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _text(dynamic value) {
  final parsed = value?.toString().trim();
  return parsed == null || parsed.isEmpty ? '' : parsed;
}
