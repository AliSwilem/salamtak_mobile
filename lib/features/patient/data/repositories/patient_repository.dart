import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/patient_appointment_model.dart';
import '../models/patient_availability_slot_model.dart';
import '../models/patient_dashboard_model.dart';
import '../models/patient_doctor_model.dart';
import '../models/patient_doctor_profile_model.dart';
import '../models/patient_hospital_model.dart';
import '../models/patient_profile_model.dart';

class PatientRepository {
  final ApiClient apiClient;

  PatientRepository(this.apiClient);

  Future<PatientDashboardModel> getDashboard() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.patientDashboard,
    );
    return PatientDashboardModel.fromJson(_map(response.data));
  }

  Future<int> getHealthRecordCount() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.patientHealthRecordStats,
    );
    final json = _map(response.data);
    final value = json['total_health_records'] ?? json['TotalHealthRecords'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<PatientProfileModel> getProfile() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.patientProfile,
    );
    return PatientProfileModel.fromJson(_map(response.data));
  }

  Future<PatientProfileModel> updateProfile(PatientProfileUpdate update) async {
    final response = await apiClient.dio.put<dynamic>(
      ApiConstants.patientProfile,
      data: update.toJson(),
    );
    return PatientProfileModel.fromJson(_map(response.data));
  }

  Future<List<PatientHospitalModel>> getHospitals() async {
    final response = await apiClient.dio.get<dynamic>(ApiConstants.hospitals);
    return _list(response.data).map(PatientHospitalModel.fromJson).toList();
  }

  Future<List<PatientDoctorModel>> searchDoctors({
    String? specialization,
    int? hospitalId,
  }) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.patientDoctorSearch,
      queryParameters: {
        if (specialization?.trim().isNotEmpty == true)
          'specialization': specialization!.trim(),
        'hospital_id': ?hospitalId,
      },
    );
    return _list(response.data).map(PatientDoctorModel.fromJson).toList();
  }

  Future<List<PatientAppointmentModel>> getUpcomingAppointments() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.patientUpcomingAppointments,
    );
    return _list(response.data).map(PatientAppointmentModel.fromJson).toList();
  }

  Future<List<PatientAppointmentModel>> getPastAppointments() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.patientPastAppointments,
    );
    return _list(response.data).map(PatientAppointmentModel.fromJson).toList();
  }

  Future<PatientAppointmentModel> getAppointment(int appointmentId) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.patientAppointment(appointmentId),
    );
    return PatientAppointmentModel.fromJson(_map(response.data));
  }

  Future<PatientAppointmentModel> bookAppointment(
    BookAppointmentRequest request,
  ) async {
    final response = await apiClient.dio.post<dynamic>(
      ApiConstants.patientAppointments,
      data: request.toJson(),
    );
    return PatientAppointmentModel.fromJson(_map(response.data));
  }

  Future<PatientAppointmentModel> cancelAppointment({
    required int appointmentId,
    required String reason,
  }) async {
    final response = await apiClient.dio.put<dynamic>(
      ApiConstants.cancelPatientAppointment(appointmentId),
      data: {
        'reason': reason.trim().isEmpty
            ? 'Cancelled by patient'
            : reason.trim(),
      },
    );
    return PatientAppointmentModel.fromJson(_map(response.data));
  }

  Future<PatientAppointmentModel> rescheduleAppointment({
    required int appointmentId,
    required AppointmentRescheduleRequest request,
  }) async {
    final response = await apiClient.dio.put<dynamic>(
      ApiConstants.reschedulePatientAppointment(appointmentId),
      data: request.toJson(),
    );
    return PatientAppointmentModel.fromJson(_map(response.data));
  }

  Future<List<PatientAvailabilitySlotModel>> getDoctorAvailability({
    required int doctorId,
    required String date,
  }) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorAvailability(doctorId),
      queryParameters: {'date': date},
    );
    return _list(response.data)
        .map(PatientAvailabilitySlotModel.fromJson)
        .where((slot) => slot.time.isNotEmpty)
        .toList();
  }

  Future<PatientDoctorProfileModel> getDoctorProfile(int doctorId) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorProfile(doctorId),
    );
    final profile = PatientDoctorProfileModel.fromJson(_map(response.data));
    if (profile.recentReviews.isNotEmpty) return profile;

    final reviews = await getDoctorReviews(doctorId);
    return PatientDoctorProfileModel(
      id: profile.id,
      fullName: profile.fullName,
      specialization: profile.specialization,
      email: profile.email,
      phone: profile.phone,
      yearsOfExperience: profile.yearsOfExperience,
      photoUrl: profile.photoUrl,
      bio: profile.bio,
      achievements: profile.achievements,
      languages: profile.languages,
      clinicName: profile.clinicName,
      averageRating: profile.averageRating,
      reviewsCount: profile.reviewsCount,
      recentReviews: reviews,
    );
  }

  Future<List<PatientDoctorReviewModel>> getDoctorReviews(int doctorId) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorReviews(doctorId),
    );
    return _list(response.data).map(PatientDoctorReviewModel.fromJson).toList();
  }

  Future<PatientDoctorReviewModel> submitDoctorReview({
    required int appointmentId,
    required DoctorReviewRequest request,
  }) async {
    final response = await apiClient.dio.post<dynamic>(
      ApiConstants.patientAppointmentReview(appointmentId),
      data: request.toJson(),
    );
    return PatientDoctorReviewModel.fromJson(_map(response.data));
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is! Map) {
      throw const FormatException('The server returned invalid patient data.');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) {
      throw const FormatException('The server returned an invalid list.');
    }
    return value.whereType<Map>().map(_map).toList();
  }
}
