import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/patient_dashboard_model.dart';
import '../../data/models/patient_doctor_model.dart';
import '../../data/models/patient_hospital_model.dart';
import '../../data/models/patient_profile_model.dart';
import '../../data/repositories/patient_repository.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(apiClientProvider));
});

class PatientHomeData {
  final String patientName;
  final PatientDashboardModel dashboard;
  final int healthRecordCount;

  const PatientHomeData({
    required this.patientName,
    required this.dashboard,
    required this.healthRecordCount,
  });
}

final patientHomeProvider = FutureProvider<PatientHomeData>((ref) async {
  final repository = ref.watch(patientRepositoryProvider);
  final results = await Future.wait<dynamic>([
    repository.getDashboard(),
    repository.getHealthRecordCount(),
    repository.getProfile(),
  ]);
  return PatientHomeData(
    patientName: (results[2] as PatientProfileModel).fullName,
    dashboard: results[0] as PatientDashboardModel,
    healthRecordCount: results[1] as int,
  );
});

final patientHospitalsProvider = FutureProvider<List<PatientHospitalModel>>((
  ref,
) {
  return ref.watch(patientRepositoryProvider).getHospitals();
});

typedef DoctorSearchFilter = ({String? specialization, int? hospitalId});

final patientDoctorsProvider =
    FutureProvider.family<List<PatientDoctorModel>, DoctorSearchFilter>((
      ref,
      filter,
    ) {
      return ref
          .watch(patientRepositoryProvider)
          .searchDoctors(
            specialization: filter.specialization,
            hospitalId: filter.hospitalId,
          );
    });

final patientProfileProvider =
    AsyncNotifierProvider<PatientProfileController, PatientProfileModel>(
      PatientProfileController.new,
    );

class PatientProfileController extends AsyncNotifier<PatientProfileModel> {
  @override
  Future<PatientProfileModel> build() {
    return ref.watch(patientRepositoryProvider).getProfile();
  }

  Future<bool> save(PatientProfileUpdate update) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(patientRepositoryProvider).updateProfile(update),
    );
    return !state.hasError;
  }
}
