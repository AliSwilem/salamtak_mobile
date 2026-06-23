import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/patient_dashboard_model.dart';
import '../models/patient_doctor_model.dart';
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
