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
}
