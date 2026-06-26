import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/doctor_appointment_model.dart';
import '../models/doctor_dashboard_model.dart';
import '../models/doctor_patient_model.dart';

class DoctorRepository {
  final ApiClient apiClient;

  DoctorRepository(this.apiClient);

  Future<DoctorDashboardModel> getDashboard() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorDashboard,
    );
    return DoctorDashboardModel.fromJson(_map(response.data));
  }

  Future<DoctorStatsModel> getStats() async {
    final response = await apiClient.dio.get<dynamic>(ApiConstants.doctorStats);
    return DoctorStatsModel.fromJson(_map(response.data));
  }

  Future<DoctorTodaySummaryModel> getTodaySummary() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorTodaySummary,
    );
    return DoctorTodaySummaryModel.fromJson(_map(response.data));
  }

  Future<List<DoctorActivityModel>> getActivityLog() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorActivityLog,
      queryParameters: {'limit': 10},
    );
    return _list(response.data).map(DoctorActivityModel.fromJson).toList();
  }

  Future<List<DoctorAppointmentModel>> getAppointments() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorAppointments,
    );
    return _withPatientNames(
      _list(response.data).map(DoctorAppointmentModel.fromJson).toList(),
    );
  }

  Future<List<DoctorAppointmentModel>> getTodayAppointments() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorTodayAppointments,
    );
    return _withPatientNames(
      _list(response.data).map(DoctorAppointmentModel.fromJson).toList(),
    );
  }

  Future<List<DoctorAppointmentModel>> getUpcomingAppointments() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorUpcomingAppointments,
    );
    return _withPatientNames(
      _list(response.data).map(DoctorAppointmentModel.fromJson).toList(),
    );
  }

  Future<List<DoctorAppointmentModel>> getPastAppointments() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorPastAppointments,
    );
    return _withPatientNames(
      _list(response.data).map(DoctorAppointmentModel.fromJson).toList(),
    );
  }

  Future<List<DoctorAppointmentModel>> searchAppointments(String query) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorSearchAppointments,
      queryParameters: {'query': query.trim()},
    );
    return _withPatientNames(
      _list(response.data).map(DoctorAppointmentModel.fromJson).toList(),
    );
  }

  Future<List<DoctorPatientModel>> getPatients() async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorPatients,
    );
    return _list(response.data).map(DoctorPatientModel.fromJson).toList();
  }

  Future<List<DoctorPatientModel>> searchPatients(String query) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorSearchPatients,
      queryParameters: {'q': query.trim()},
    );
    return _list(response.data).map(DoctorPatientModel.fromJson).toList();
  }

  Future<DoctorPatientSummaryModel> getPatientSummary(int patientId) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorPatientSummary(patientId),
    );
    return DoctorPatientSummaryModel.fromJson(_map(response.data));
  }

  Future<DoctorPatientStatisticsModel> getPatientStatistics(
    int patientId,
  ) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorPatientStatistics(patientId),
    );
    return DoctorPatientStatisticsModel.fromJson(_map(response.data));
  }

  Future<DoctorConsultationHistoryModel> getConsultationHistory(
    int patientId,
  ) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiConstants.doctorConsultationHistory(patientId),
    );
    return DoctorConsultationHistoryModel.fromJson(_map(response.data));
  }

  Future<DoctorAppointmentModel> updateAppointmentStatus({
    required int appointmentId,
    required DoctorAppointmentStatus status,
  }) async {
    final response = await apiClient.dio.put<dynamic>(
      ApiConstants.doctorAppointmentStatus(appointmentId),
      data: {'Status': status.apiValue},
    );
    return _withPatientName(
      DoctorAppointmentModel.fromJson(_map(response.data)),
    );
  }

  Future<DoctorAppointmentModel> cancelAppointment({
    required int appointmentId,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    final response = await apiClient.dio.put<dynamic>(
      ApiConstants.doctorCancelAppointment(appointmentId),
      data: trimmedReason.isEmpty ? null : trimmedReason,
    );
    return _withPatientName(
      DoctorAppointmentModel.fromJson(_map(response.data)),
    );
  }

  Future<Map<int, String>> _getPatientNameMap() async {
    final patients = await getPatients();
    return {
      for (final patient in patients)
        if (patient.id > 0) patient.id: patient.displayName,
    };
  }

  Future<List<DoctorAppointmentModel>> _withPatientNames(
    List<DoctorAppointmentModel> appointments,
  ) async {
    if (appointments.isEmpty) return appointments;
    final patientNames = await _getPatientNameMap();
    return appointments
        .map(
          (appointment) => appointment.patientName.isNotEmpty
              ? appointment
              : appointment.copyWith(
                  patientName: patientNames[appointment.patientId],
                ),
        )
        .toList();
  }

  Future<DoctorAppointmentModel> _withPatientName(
    DoctorAppointmentModel appointment,
  ) async {
    if (appointment.patientName.isNotEmpty) return appointment;
    final patientNames = await _getPatientNameMap();
    return appointment.copyWith(
      patientName: patientNames[appointment.patientId],
    );
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is! Map) {
      throw const FormatException('The server returned invalid doctor data.');
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
