import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/doctor_dashboard_model.dart';
import '../../data/repositories/doctor_repository.dart';

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(apiClientProvider));
});

class DoctorHomeData {
  final String doctorName;
  final DoctorDashboardModel dashboard;
  final DoctorStatsModel stats;
  final DoctorTodaySummaryModel todaySummary;
  final List<DoctorActivityModel> activity;

  const DoctorHomeData({
    required this.doctorName,
    required this.dashboard,
    required this.stats,
    required this.todaySummary,
    required this.activity,
  });
}

final doctorHomeProvider = FutureProvider<DoctorHomeData>((ref) async {
  final repository = ref.watch(doctorRepositoryProvider);
  final authState = ref.watch(authControllerProvider);
  final results = await Future.wait<dynamic>([
    repository.getDashboard(),
    repository.getStats(),
    repository.getTodaySummary(),
    repository.getActivityLog(),
  ]);

  return DoctorHomeData(
    doctorName:
        authState.user?.fullName ??
        authState.user?.username ??
        authState.user?.email ??
        '',
    dashboard: results[0] as DoctorDashboardModel,
    stats: results[1] as DoctorStatsModel,
    todaySummary: results[2] as DoctorTodaySummaryModel,
    activity: results[3] as List<DoctorActivityModel>,
  );
});
