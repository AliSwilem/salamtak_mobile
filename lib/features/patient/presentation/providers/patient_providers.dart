import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/patient_appointment_model.dart';
import '../../data/models/patient_availability_slot_model.dart';
import '../../data/models/patient_dashboard_model.dart';
import '../../data/models/patient_doctor_model.dart';
import '../../data/models/patient_doctor_profile_model.dart';
import '../../data/models/patient_hospital_model.dart';
import '../../data/models/patient_notification_model.dart';
import '../../data/models/patient_profile_model.dart';
import '../../data/models/patient_records_model.dart';
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

final upcomingAppointmentsProvider =
    FutureProvider<List<PatientAppointmentModel>>((ref) {
      return ref.watch(patientRepositoryProvider).getUpcomingAppointments();
    });

final pastAppointmentsProvider = FutureProvider<List<PatientAppointmentModel>>((
  ref,
) {
  return ref.watch(patientRepositoryProvider).getPastAppointments();
});

final appointmentDetailsProvider =
    FutureProvider.family<PatientAppointmentModel, int>((ref, appointmentId) {
      return ref.watch(patientRepositoryProvider).getAppointment(appointmentId);
    });

typedef DoctorAvailabilityFilter = ({int doctorId, String date});

final doctorAvailabilityProvider =
    FutureProvider.family<
      List<PatientAvailabilitySlotModel>,
      DoctorAvailabilityFilter
    >((ref, filter) {
      return ref
          .watch(patientRepositoryProvider)
          .getDoctorAvailability(doctorId: filter.doctorId, date: filter.date);
    });

final doctorProfileProvider =
    FutureProvider.family<PatientDoctorProfileModel, int>((ref, doctorId) {
      return ref.watch(patientRepositoryProvider).getDoctorProfile(doctorId);
    });

final appointmentActionProvider =
    AsyncNotifierProvider<AppointmentActionController, void>(
      AppointmentActionController.new,
    );

class AppointmentActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<PatientAppointmentModel?> book(BookAppointmentRequest request) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(patientRepositoryProvider).bookAppointment(request),
    );
    state = result.whenData((_) {});
    final appointment = result.hasValue ? result.value : null;
    if (appointment != null) _refreshAppointments();
    return appointment;
  }

  Future<bool> cancel({
    required int appointmentId,
    required String reason,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(patientRepositoryProvider)
          .cancelAppointment(appointmentId: appointmentId, reason: reason),
    );
    state = result.whenData((_) {});
    if (!result.hasError) {
      _refreshAppointments();
      ref.invalidate(appointmentDetailsProvider(appointmentId));
    }
    return !result.hasError;
  }

  Future<bool> reschedule({
    required int appointmentId,
    required AppointmentRescheduleRequest request,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(patientRepositoryProvider)
          .rescheduleAppointment(
            appointmentId: appointmentId,
            request: request,
          ),
    );
    state = result.whenData((_) {});
    if (!result.hasError) {
      _refreshAppointments();
      ref.invalidate(appointmentDetailsProvider(appointmentId));
    }
    return !result.hasError;
  }

  Future<bool> submitReview({
    required int appointmentId,
    required DoctorReviewRequest request,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(patientRepositoryProvider)
          .submitDoctorReview(appointmentId: appointmentId, request: request),
    );
    state = result.whenData((_) {});
    if (!result.hasError) {
      ref.invalidate(pastAppointmentsProvider);
      ref.invalidate(appointmentDetailsProvider(appointmentId));
    }
    return !result.hasError;
  }

  void _refreshAppointments() {
    ref.invalidate(patientHomeProvider);
    ref.invalidate(upcomingAppointmentsProvider);
    ref.invalidate(pastAppointmentsProvider);
  }
}

final patientRecordsProvider = FutureProvider<PatientRecordsBundle>((ref) {
  return ref.watch(patientRepositoryProvider).getHealthRecords();
});

final patientTestResultsProvider = FutureProvider<List<PatientDocumentModel>>((
  ref,
) {
  return ref.watch(patientRepositoryProvider).getTestResults();
});

final patientNotificationsProvider =
    FutureProvider<List<PatientFullNotificationModel>>((ref) {
      return ref.watch(patientRepositoryProvider).getNotifications();
    });

final patientUnreadNotificationsProvider = Provider<int>((ref) {
  final notifications = ref.watch(patientNotificationsProvider);
  return notifications.maybeWhen(
    data: (items) => items.where((item) => !item.isRead).length,
    orElse: () => 0,
  );
});

final notificationActionProvider =
    AsyncNotifierProvider<NotificationActionController, void>(
      NotificationActionController.new,
    );

class NotificationActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> markRead(int notificationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(patientRepositoryProvider)
          .markNotificationRead(notificationId),
    );
    if (!state.hasError) {
      ref.invalidate(patientNotificationsProvider);
      ref.invalidate(patientHomeProvider);
    }
    return !state.hasError;
  }

  Future<bool> delete(int notificationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(patientRepositoryProvider)
          .deleteNotification(notificationId),
    );
    if (!state.hasError) {
      ref.invalidate(patientNotificationsProvider);
      ref.invalidate(patientHomeProvider);
    }
    return !state.hasError;
  }
}
