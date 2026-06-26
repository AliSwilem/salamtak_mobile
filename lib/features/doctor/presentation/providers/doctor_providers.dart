import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/doctor_appointment_model.dart';
import '../../data/models/doctor_availability_model.dart';
import '../../data/models/doctor_consultation_model.dart';
import '../../data/models/doctor_dashboard_model.dart';
import '../../data/models/doctor_patient_model.dart';
import '../../data/models/doctor_profile_model.dart';
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

enum DoctorAppointmentFilter {
  today,
  upcoming,
  past,
  all;

  String get label {
    return switch (this) {
      DoctorAppointmentFilter.today => 'Today',
      DoctorAppointmentFilter.upcoming => 'Upcoming',
      DoctorAppointmentFilter.past => 'Past',
      DoctorAppointmentFilter.all => 'All',
    };
  }
}

typedef DoctorAppointmentsQuery = ({
  DoctorAppointmentFilter filter,
  String search,
});

final doctorAppointmentsProvider =
    FutureProvider.family<
      List<DoctorAppointmentModel>,
      DoctorAppointmentsQuery
    >((ref, query) {
      final repository = ref.watch(doctorRepositoryProvider);
      final search = query.search.trim();
      if (search.isNotEmpty) {
        return repository.searchAppointments(search);
      }

      return switch (query.filter) {
        DoctorAppointmentFilter.today => repository.getTodayAppointments(),
        DoctorAppointmentFilter.upcoming =>
          repository.getUpcomingAppointments(),
        DoctorAppointmentFilter.past => repository.getPastAppointments(),
        DoctorAppointmentFilter.all => repository.getAppointments(),
      };
    });

final doctorAppointmentActionProvider =
    AsyncNotifierProvider<DoctorAppointmentActionController, void>(
      DoctorAppointmentActionController.new,
    );

class DoctorAppointmentActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<DoctorAppointmentModel?> updateStatus({
    required int appointmentId,
    required DoctorAppointmentStatus status,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(doctorRepositoryProvider)
          .updateAppointmentStatus(
            appointmentId: appointmentId,
            status: status,
          ),
    );
    state = result.whenData((_) {});
    if (!result.hasError) _refreshDoctorAppointments();
    return result.hasValue ? result.value : null;
  }

  Future<DoctorAppointmentModel?> cancel({
    required int appointmentId,
    required String reason,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(doctorRepositoryProvider)
          .cancelAppointment(appointmentId: appointmentId, reason: reason),
    );
    state = result.whenData((_) {});
    if (!result.hasError) _refreshDoctorAppointments();
    return result.hasValue ? result.value : null;
  }

  void _refreshDoctorAppointments() {
    ref.invalidate(doctorAppointmentsProvider);
    ref.invalidate(doctorHomeProvider);
  }
}

final doctorPatientsProvider =
    FutureProvider.family<List<DoctorPatientModel>, String>((ref, search) {
      final query = search.trim();
      final repository = ref.watch(doctorRepositoryProvider);
      if (query.isEmpty) return repository.getPatients();
      return repository.searchPatients(query);
    });

class DoctorPatientFileData {
  final DoctorPatientModel? patient;
  final DoctorPatientSummaryModel summary;
  final DoctorPatientStatisticsModel statistics;
  final DoctorConsultationHistoryModel history;

  const DoctorPatientFileData({
    required this.patient,
    required this.summary,
    required this.statistics,
    required this.history,
  });
}

final doctorPatientFileProvider =
    FutureProvider.family<DoctorPatientFileData, int>((ref, patientId) async {
      final repository = ref.watch(doctorRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repository.getPatients(),
        repository.getPatientSummary(patientId),
        repository.getPatientStatistics(patientId),
        repository.getConsultationHistory(patientId),
      ]);

      final patients = results[0] as List<DoctorPatientModel>;
      final patient = patients
          .where((item) => item.id == patientId)
          .cast<DoctorPatientModel?>()
          .firstOrNull;

      return DoctorPatientFileData(
        patient: patient,
        summary: results[1] as DoctorPatientSummaryModel,
        statistics: results[2] as DoctorPatientStatisticsModel,
        history: results[3] as DoctorConsultationHistoryModel,
      );
    });

class DoctorAvailabilityData {
  final DoctorAvailabilityModel availability;
  final DoctorAvailabilityStatsModel stats;

  const DoctorAvailabilityData({
    required this.availability,
    required this.stats,
  });
}

final doctorAvailabilityProvider = FutureProvider<DoctorAvailabilityData>((
  ref,
) async {
  final repository = ref.watch(doctorRepositoryProvider);
  final results = await Future.wait<dynamic>([
    repository.getAvailability(),
    repository.getAvailabilityStats(),
  ]);
  return DoctorAvailabilityData(
    availability: results[0] as DoctorAvailabilityModel,
    stats: results[1] as DoctorAvailabilityStatsModel,
  );
});

final doctorAvailabilityActionProvider =
    AsyncNotifierProvider<DoctorAvailabilityActionController, void>(
      DoctorAvailabilityActionController.new,
    );

class DoctorAvailabilityActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<DoctorAvailabilityModel?> save(
    List<DoctorAvailabilitySlotModel> slots,
  ) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(doctorRepositoryProvider).updateAvailability(slots),
    );
    state = result.whenData((_) {});
    if (!result.hasError) ref.invalidate(doctorAvailabilityProvider);
    return result.hasValue ? result.value : null;
  }

  Future<bool> deleteDay(int day) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(doctorRepositoryProvider).deleteAvailabilityDay(day),
    );
    if (!state.hasError) ref.invalidate(doctorAvailabilityProvider);
    return !state.hasError;
  }

  Future<DoctorAvailabilitySyncResult?> syncCalendar() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(doctorRepositoryProvider).syncAvailabilityCalendar(),
    );
    state = result.whenData((_) {});
    return result.hasValue ? result.value : null;
  }
}

final doctorConsultationProvider =
    FutureProvider.family<DoctorConsultationData, int>((ref, patientId) async {
      final repository = ref.watch(doctorRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repository.getConsultationHistory(patientId),
        repository.getMedications(),
        repository.getTreatmentTypes(),
      ]);
      return DoctorConsultationData(
        history: results[0] as DoctorConsultationHistoryModel,
        medications: results[1] as List<DoctorMedicationModel>,
        treatmentTypes: results[2] as List<DoctorTreatmentTypeModel>,
      );
    });

final doctorConsultationActionProvider =
    AsyncNotifierProvider<DoctorConsultationActionController, void>(
      DoctorConsultationActionController.new,
    );

class DoctorConsultationActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<DoctorDiagnosisModel?> createDiagnosis(
    DoctorDiagnosisCreateRequest request,
  ) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(doctorRepositoryProvider).createDiagnosis(request),
    );
    state = result.whenData((_) {});
    if (!result.hasError) _refreshPatient(request.appointmentId);
    return result.hasValue ? result.value : null;
  }

  Future<DoctorTreatmentModel?> createTreatment(
    DoctorTreatmentCreateRequest request, {
    required int patientId,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(doctorRepositoryProvider).createTreatment(request),
    );
    state = result.whenData((_) {});
    if (!result.hasError) {
      ref.invalidate(doctorConsultationProvider(patientId));
      ref.invalidate(doctorPatientFileProvider(patientId));
    }
    return result.hasValue ? result.value : null;
  }

  Future<bool> addMedication(
    DoctorTreatmentMedicationRequest request, {
    required int patientId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(doctorRepositoryProvider).addTreatmentMedication(request),
    );
    if (!state.hasError) {
      ref.invalidate(doctorConsultationProvider(patientId));
      ref.invalidate(doctorPatientFileProvider(patientId));
    }
    return !state.hasError;
  }

  Future<DoctorSummaryModel?> createSummary(
    DoctorSummaryCreateRequest request,
  ) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(doctorRepositoryProvider).createSummary(request),
    );
    state = result.whenData((_) {});
    if (!result.hasError) {
      ref.invalidate(doctorPatientFileProvider(request.patientId));
    }
    return result.hasValue ? result.value : null;
  }

  void _refreshPatient(int appointmentId) {
    ref.invalidate(doctorAppointmentsProvider);
    ref.invalidate(doctorHomeProvider);
  }
}

final doctorProfileProvider = FutureProvider<DoctorProfileData>((ref) async {
  final repository = ref.watch(doctorRepositoryProvider);
  final results = await Future.wait<dynamic>([
    repository.getProfile(),
    repository.getProfileStats(),
    repository.getProfileActivity(),
  ]);
  return DoctorProfileData(
    profile: results[0] as DoctorProfileModel,
    stats: results[1] as DoctorProfileStatsModel,
    activity: results[2] as List<DoctorActivityModel>,
  );
});

final doctorProfileActionProvider =
    AsyncNotifierProvider<DoctorProfileActionController, void>(
      DoctorProfileActionController.new,
    );

class DoctorProfileActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<DoctorProfileModel?> save(DoctorProfileUpdateRequest request) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(doctorRepositoryProvider).updateProfile(request),
    );
    state = result.whenData((_) {});
    if (!result.hasError) {
      ref.invalidate(doctorProfileProvider);
      ref.invalidate(doctorHomeProvider);
    }
    return result.hasValue ? result.value : null;
  }
}
