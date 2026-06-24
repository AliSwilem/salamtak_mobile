import 'package:flutter_test/flutter_test.dart';
import 'package:salamtak_mobile/features/patient/data/models/patient_notification_model.dart';
import 'package:salamtak_mobile/features/patient/data/models/patient_records_model.dart';

void main() {
  test('diagnosis and treatment parse PascalCase backend fields', () {
    final diagnosis = PatientDiagnosisModel.fromJson({
      'DiagnosisID': 7,
      'DiagnosisName': 'Hypertension',
      'DiagnosisDate': '2026-06-20',
      'DoctorName': 'Dr Example',
      'DoctorSpecialization': 'Cardiology',
      'Notes': 'Follow up required',
    });
    final treatment = PatientTreatmentModel.fromJson({
      'TreatmentID': 8,
      'DiagnosisID': 7,
      'TreatmentType': 'Medication',
      'StartDate': '2026-06-21',
      'EndDate': '2026-07-21',
      'Description': 'Daily treatment',
    });

    expect(diagnosis.id, 7);
    expect(diagnosis.doctorName, 'Dr Example');
    expect(treatment.diagnosisId, 7);
    expect(treatment.type, 'Medication');
  });

  test('medication and document parse defensive fields', () {
    final medication = PatientMedicationModel.fromJson({
      'MedicationID': 9,
      'Name': 'Aspirin',
      'Dosage': '100mg',
      'DiagnosisName': 'Cardiac risk',
      'TreatmentStartDate': '2026-06-21',
    });
    final document = PatientDocumentModel.fromJson({
      'EHRID': 10,
      'RecordID': 10,
      'FileType': 'lab result',
      'FileLocation': 'uploads/lab.pdf',
      'UploadedAt': '2026-06-22T10:00:00',
    });

    expect(medication.name, 'Aspirin');
    expect(medication.dosage, '100mg');
    expect(document.id, 10);
    expect(document.category, PatientDocumentCategory.laboratory);
    expect(document.isProbablyDownloadable, isTrue);
  });

  test('notification parses read state and snake case fallback', () {
    final notification = PatientFullNotificationModel.fromJson({
      'notification_id': 3,
      'title': 'Appointment Confirmed',
      'message': 'Your appointment is ready.',
      'is_read': false,
      'date_created': '2026-06-23T12:00:00',
      'from_name': 'System',
    });

    expect(notification.id, 3);
    expect(notification.isRead, isFalse);
    expect(notification.displayFrom, 'System');
  });
}
