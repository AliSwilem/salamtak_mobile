import 'package:flutter_test/flutter_test.dart';
import 'package:salamtak_mobile/features/doctor/data/models/doctor_dashboard_model.dart';

void main() {
  test('doctor dashboard parses PascalCase and snake_case defensively', () {
    final dashboard = DoctorDashboardModel.fromJson({
      'Appointments': [
        {
          'AppointmentID': 10,
          'PatientID': 5,
          'PatientName': 'Patient One',
          'Date': '2026-06-25',
          'Time': '10:30:00',
          'Status': 'scheduled',
        },
      ],
      'patients': [
        {
          'patient_id': 5,
          'full_name': 'Patient One',
          'gender': 'female',
          'contact_info': '01000000000',
        },
      ],
    });

    expect(dashboard.appointments.single.id, 10);
    expect(dashboard.appointments.single.patientName, 'Patient One');
    expect(dashboard.patients.single.fullName, 'Patient One');
  });

  test('doctor stats and activity parse optional backend fields safely', () {
    final stats = DoctorStatsModel.fromJson({
      'total_today': '4',
      'Completed': 2,
      'cancelled': null,
      'no_show': '1',
    });
    final activity = DoctorActivityModel.fromJson({
      'notification_id': 7,
      'message': 'Appointment updated',
      'is_read': 'false',
    });

    expect(stats.today, 4);
    expect(stats.completed, 2);
    expect(stats.cancelled, 0);
    expect(stats.noShow, 1);
    expect(activity.id, 7);
    expect(activity.isRead, isFalse);
  });
}
