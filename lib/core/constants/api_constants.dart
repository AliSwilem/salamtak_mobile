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
}
