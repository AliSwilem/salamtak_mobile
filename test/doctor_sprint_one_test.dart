import 'package:flutter_test/flutter_test.dart';
import 'package:salamtak_mobile/features/doctor/data/models/doctor_appointment_model.dart';
import 'package:salamtak_mobile/features/doctor/data/models/doctor_dashboard_model.dart';
import 'package:salamtak_mobile/features/doctor/data/models/doctor_patient_model.dart';

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

  test('doctor appointment parses ids, hospital, and status defensively', () {
    final appointment = DoctorAppointmentModel.fromJson({
      'appointment_id': '12',
      'PatientID': 4,
      'DoctorID': '9',
      'HospitalID': null,
      'Date': '2026-06-25',
      'Time': '09:15:00',
      'Status': 'no_show',
    });

    expect(appointment.id, 12);
    expect(appointment.patientId, 4);
    expect(appointment.doctorId, 9);
    expect(appointment.hospitalId, isNull);
    expect(appointment.displayPatientName, 'Patient #4');
    expect(appointment.parsedStatus, DoctorAppointmentStatus.noShow);
    expect(DoctorAppointmentStatus.rescheduled.apiValue, 'rescheduled');
  });

  test('doctor patient and medical file models parse backend shapes', () {
    final patient = DoctorPatientModel.fromJson({
      'PatientID': 3,
      'FullName': 'Ali Ahmed',
      'Gender': 'male',
      'DateOfBirth': '2000-01-02',
      'ContactInfo': '01000000000',
      'BloodType': 'O+',
    });
    final summary = DoctorPatientSummaryModel.fromJson({
      'diagnoses': '2',
      'treatments': 1,
      'ehr_files': null,
    });
    final stats = DoctorPatientStatisticsModel.fromJson({
      'last_diagnosis_date': '2026-06-25',
      'active_treatments': '1',
    });
    final history = DoctorConsultationHistoryModel.fromJson({
      'diagnoses': [
        {'DiagnosisID': 9, 'Notes': 'Stable'},
      ],
      'treatments': [
        {'TreatmentID': 4, 'DiagnosisID': 9, 'Result': 'Improved'},
      ],
    });

    expect(patient.id, 3);
    expect(patient.displayName, 'Ali Ahmed');
    expect(summary.diagnoses, 2);
    expect(summary.ehrFiles, 0);
    expect(stats.activeTreatments, 1);
    expect(history.diagnoses.single.notes, 'Stable');
    expect(history.treatments.single.result, 'Improved');
  });
}
