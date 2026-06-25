import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/doctor_dashboard_model.dart';

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
