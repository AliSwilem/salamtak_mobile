import 'package:flutter_test/flutter_test.dart';
import 'package:salamtak_mobile/features/doctor/data/models/doctor_appointment_model.dart';
import 'package:salamtak_mobile/features/doctor/data/models/doctor_availability_model.dart';
import 'package:salamtak_mobile/features/doctor/data/models/doctor_consultation_model.dart';
import 'package:salamtak_mobile/features/doctor/data/models/doctor_dashboard_model.dart';
import 'package:salamtak_mobile/features/doctor/data/models/doctor_patient_model.dart';
import 'package:salamtak_mobile/features/doctor/data/models/doctor_profile_model.dart';

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

  test('doctor availability models parse and serialize backend contract', () {
    final availability = DoctorAvailabilityModel.fromJson({
      'doctor_id': '2',
      'slots': [
        {'day_of_week': 1, 'start_time': '09:00', 'end_time': '17:30:00'},
      ],
    });
    final stats = DoctorAvailabilityStatsModel.fromJson({
      'DoctorID': 2,
      'Entries': '1',
    });
    final sync = DoctorAvailabilitySyncResult.fromJson({
      'synced': false,
      'mode': 'demo-disabled',
      'message': 'Not connected',
    });

    expect(availability.doctorId, 2);
    expect(availability.slots.single.startTime, '09:00:00');
    expect(availability.slots.single.displayEndTime, '17:30');
    expect(availability.slots.single.toJson(), {
      'day_of_week': 1,
      'start_time': '09:00:00',
      'end_time': '17:30:00',
    });
    expect(stats.entries, 1);
    expect(sync.synced, isFalse);
    expect(sync.message, 'Not connected');
  });

  test('doctor consultation request and lookup models use backend casing', () {
    final diagnosis = const DoctorDiagnosisCreateRequest(
      appointmentId: 6,
      notes: 'Follow up',
    );
    final treatment = const DoctorTreatmentCreateRequest(
      diagnosisId: 9,
      treatmentTypeId: 2,
      startDate: '2026-06-26',
      result: 'Improving',
    );
    final medication = DoctorMedicationModel.fromJson({
      'MedicationID': '3',
      'Name': 'Med',
      'Dosage': '10mg',
    });
    final type = DoctorTreatmentTypeModel.fromJson({
      'TreatmentTypeID': 2,
      'Name': 'Physical therapy',
    });

    expect(diagnosis.toJson(), {'AppointmentID': 6, 'Notes': 'Follow up'});
    expect(treatment.toJson()['DiagnosisID'], 9);
    expect(treatment.toJson()['TreatmentTypeID'], 2);
    expect(medication.id, 3);
    expect(type.name, 'Physical therapy');
  });

  test('doctor profile parses and serializes editable fields', () {
    final profile = DoctorProfileModel.fromJson({
      'DoctorID': 2,
      'FullName': 'hazem swilem',
      'Specialization': 'Cardiology',
      'YearsOfExperience': '5',
      'AverageRating': '4.5',
      'ReviewsCount': 7,
    });
    final update = DoctorProfileUpdateRequest(
      fullName: 'hazem swilem',
      specialization: 'Cardiology',
      phone: '0100',
      yearsOfExperience: 5,
      hospitalId: 1,
      bio: 'Bio',
      achievements: 'Awards',
      languages: 'Arabic, English',
      clinicName: 'Clinic',
    );

    expect(profile.id, 2);
    expect(profile.yearsOfExperience, 5);
    expect(profile.averageRating, 4.5);
    expect(update.toJson()['FullName'], 'hazem swilem');
    expect(update.toJson()['HospitalID'], 1);
  });
}
