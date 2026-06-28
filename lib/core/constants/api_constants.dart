class ApiConstants {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const String login = '/login';
  static const String authMe = '/auth/me';
  static const String registerPatient = '/register/patient';
  static const String registerDoctor = '/register/doctor';
  static const String hospitals = '/patients/hospitals';
  static const String patientDashboard = '/patients/me/dashboard';
  static const String patientHealthRecordStats =
      '/patients/me/health-records/stats';
  static const String patientProfile = '/patients/me/profile';
  static const String patientDoctorSearch = '/patients/doctors/search';
  static const String patientUpcomingAppointments =
      '/patients/me/appointments/upcoming';
  static const String patientPastAppointments =
      '/patients/me/appointments/past';
  static const String patientAppointments = '/patients/me/appointments';

  static String patientAppointment(int appointmentId) =>
      '/patients/me/appointments/$appointmentId';

  static String cancelPatientAppointment(int appointmentId) =>
      '/patients/me/appointments/$appointmentId/cancel';

  static String reschedulePatientAppointment(int appointmentId) =>
      '/patients/me/appointments/$appointmentId/reschedule';

  static String patientAppointmentReview(int appointmentId) =>
      '/patients/me/appointments/$appointmentId/review';

  static String doctorProfile(int doctorId) =>
      '/patients/doctors/$doctorId/profile';

  static String doctorReviews(int doctorId) =>
      '/patients/doctors/$doctorId/reviews';

  static String doctorAvailability(int doctorId) =>
      '/patients/doctors/$doctorId/availability';

  static const String patientDiagnoses = '/patients/me/diagnoses';
  static const String patientTreatments = '/patients/me/treatments';
  static const String patientMedications = '/patients/me/medications';
  static const String patientEhrs = '/patients/me/ehrs';
  static const String patientTestResults = '/patients/me/test-results';
  static const String patientNotifications = '/patients/me/notifications';

  static String patientTestResultDownload(int ehrId) =>
      '/patients/me/test-results/$ehrId/download';

  static String markPatientNotificationRead(int notificationId) =>
      '/patients/me/notifications/$notificationId/read';

  static String patientNotification(int notificationId) =>
      '/patients/me/notifications/$notificationId';

  static const String doctorDashboard = '/doctors/me/dashboard';
  static const String doctorStats = '/doctors/me/stats';
  static const String doctorTodaySummary = '/doctors/me/today-summary';
  static const String doctorActivityLog = '/doctors/me/activity-log';
  static const String doctorAppointments = '/doctors/me/appointments';
  static const String doctorTodayAppointments =
      '/doctors/me/appointments/today';
  static const String doctorUpcomingAppointments =
      '/doctors/me/appointments/upcoming';
  static const String doctorPastAppointments = '/doctors/me/appointments/past';
  static const String doctorSearchAppointments =
      '/doctors/me/appointments/search';
  static const String doctorPatients = '/doctors/me/patients';
  static const String doctorSearchPatients = '/doctors/patients/search';

  static String doctorAppointmentStatus(int appointmentId) =>
      '/doctors/me/appointments/$appointmentId/status';

  static String doctorCancelAppointment(int appointmentId) =>
      '/doctors/me/appointments/$appointmentId/cancel';

  static String doctorPatientSummary(int patientId) =>
      '/doctors/patients/$patientId/summary';

  static String doctorPatientStatistics(int patientId) =>
      '/doctors/patients/$patientId/statistics';

  static String doctorConsultationHistory(int patientId) =>
      '/doctors/consultations/history/$patientId';

  static const String doctorCreateDiagnosis =
      '/doctors/consultations/diagnosis';
  static const String doctorCreateTreatment =
      '/doctors/consultations/treatment';
  static const String doctorAddTreatmentMedication =
      '/doctors/consultations/treatment-medication';
  static const String doctorCreateSummary = '/doctors/consultations/summary';
  static const String doctorMedications = '/doctors/medications';
  static const String doctorTreatmentTypes = '/doctors/lookups/treatment-types';

  static const String doctorOwnAvailability = '/doctors/me/availability';
  static const String doctorAvailabilityStats =
      '/doctors/me/availability/stats';
  static const String doctorUpdateAvailability =
      '/doctors/me/availability/update';
  static const String doctorSyncAvailabilityCalendar =
      '/doctors/me/availability/sync-calendar';

  static String doctorDeleteAvailabilityDay(int day) =>
      '/doctors/me/availability/delete-day/$day';

  static const String doctorProfileMe = '/doctors/me/profile';
  static const String doctorProfileStats = '/doctors/me/profile/stats';
  static const String doctorProfileActivity = '/doctors/me/profile/activity';

  static const String chatConversations = '/chat/conversations';
  static const String chatStart = '/chat/start';
  static const String chatSearchDoctors = '/chat/search/doctors';
  static const String chatSearchPatients = '/chat/search/patients';

  static String chatMessages(int conversationId) =>
      '/chat/conversations/$conversationId/messages';

  static String chatMarkRead(int messageId) =>
      '/chat/messages/$messageId/mark-read';

  static String videoSessionForAppointment(int appointmentId) =>
      '/video-sessions/appointments/$appointmentId';

  static String startVideoSession(int appointmentId) =>
      '/video-sessions/appointments/$appointmentId/start';

  static String joinVideoSession(int appointmentId) =>
      '/video-sessions/appointments/$appointmentId/join';

  static String leaveVideoSession(int sessionId) =>
      '/video-sessions/$sessionId/leave';

  static String endVideoSession(int sessionId) =>
      '/video-sessions/$sessionId/end';
}
