class PatientRecordsBundle {
  final List<PatientDiagnosisModel> diagnoses;
  final List<PatientTreatmentModel> treatments;
  final List<PatientMedicationModel> medications;
  final List<PatientDocumentModel> documents;

  const PatientRecordsBundle({
    required this.diagnoses,
    required this.treatments,
    required this.medications,
    required this.documents,
  });
}

class PatientDiagnosisModel {
  final int id;
  final String diagnosisName;
  final String notes;
  final String date;
  final String doctorName;
  final String doctorSpecialization;

  const PatientDiagnosisModel({
    required this.id,
    required this.diagnosisName,
    required this.notes,
    required this.date,
    required this.doctorName,
    required this.doctorSpecialization,
  });

  factory PatientDiagnosisModel.fromJson(Map<String, dynamic> json) {
    return PatientDiagnosisModel(
      id: _int(json['DiagnosisID'] ?? json['diagnosis_id']) ?? 0,
      diagnosisName: _text(json['DiagnosisName'] ?? json['diagnosis_name']),
      notes: _text(json['Notes'] ?? json['notes']),
      date: _dateText(json['DiagnosisDate'] ?? json['diagnosis_date']),
      doctorName: _text(json['DoctorName'] ?? json['doctor_name']),
      doctorSpecialization: _text(
        json['DoctorSpecialization'] ?? json['doctor_specialization'],
      ),
    );
  }
}

class PatientTreatmentModel {
  final int id;
  final int diagnosisId;
  final String type;
  final String description;
  final String startDate;
  final String endDate;
  final String doctorName;
  final String doctorSpecialization;

  const PatientTreatmentModel({
    required this.id,
    required this.diagnosisId,
    required this.type,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.doctorName,
    required this.doctorSpecialization,
  });

  factory PatientTreatmentModel.fromJson(Map<String, dynamic> json) {
    return PatientTreatmentModel(
      id: _int(json['TreatmentID'] ?? json['treatment_id']) ?? 0,
      diagnosisId: _int(json['DiagnosisID'] ?? json['diagnosis_id']) ?? 0,
      type: _text(json['TreatmentType'] ?? json['treatment_type']),
      description: _text(json['Description'] ?? json['description']),
      startDate: _dateText(json['StartDate'] ?? json['start_date']),
      endDate: _dateText(json['EndDate'] ?? json['end_date']),
      doctorName: _text(json['DoctorName'] ?? json['doctor_name']),
      doctorSpecialization: _text(
        json['DoctorSpecialization'] ?? json['doctor_specialization'],
      ),
    );
  }
}

class PatientMedicationModel {
  final int id;
  final String name;
  final String dosage;
  final String form;
  final String description;
  final String sideEffects;
  final String doctorName;
  final String diagnosisName;
  final String diagnosisDate;
  final String treatmentStartDate;
  final String treatmentEndDate;

  const PatientMedicationModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.form,
    required this.description,
    required this.sideEffects,
    required this.doctorName,
    required this.diagnosisName,
    required this.diagnosisDate,
    required this.treatmentStartDate,
    required this.treatmentEndDate,
  });

  factory PatientMedicationModel.fromJson(Map<String, dynamic> json) {
    return PatientMedicationModel(
      id: _int(json['MedicationID'] ?? json['medication_id']) ?? 0,
      name: _text(json['Name'] ?? json['name']),
      dosage: _text(json['Dosage'] ?? json['dosage']),
      form: _text(json['Form'] ?? json['form']),
      description: _text(json['Description'] ?? json['description']),
      sideEffects: _text(json['SideEffects'] ?? json['side_effects']),
      doctorName: _text(json['DoctorName'] ?? json['doctor_name']),
      diagnosisName: _text(json['DiagnosisName'] ?? json['diagnosis_name']),
      diagnosisDate: _dateText(json['DiagnosisDate'] ?? json['diagnosis_date']),
      treatmentStartDate: _dateText(
        json['TreatmentStartDate'] ?? json['treatment_start_date'],
      ),
      treatmentEndDate: _dateText(
        json['TreatmentEndDate'] ?? json['treatment_end_date'],
      ),
    );
  }
}

class PatientDocumentModel {
  final int id;
  final int patientId;
  final String dateCreated;
  final String fileType;
  final String fileLocation;
  final String accessLevel;
  final String uploadedAt;

  const PatientDocumentModel({
    required this.id,
    required this.patientId,
    required this.dateCreated,
    required this.fileType,
    required this.fileLocation,
    required this.accessLevel,
    required this.uploadedAt,
  });

  factory PatientDocumentModel.fromJson(Map<String, dynamic> json) {
    return PatientDocumentModel(
      id: _int(json['EHRID'] ?? json['RecordID'] ?? json['record_id']) ?? 0,
      patientId: _int(json['PatientID'] ?? json['patient_id']) ?? 0,
      dateCreated: _dateText(json['DateCreated'] ?? json['date_created']),
      fileType: _text(json['FileType'] ?? json['file_type']),
      fileLocation: _text(json['FileLocation'] ?? json['file_location']),
      accessLevel: _text(json['AccessLevel'] ?? json['access_level']),
      uploadedAt: _dateText(json['UploadedAt'] ?? json['uploaded_at']),
    );
  }

  PatientDocumentCategory get category {
    final text = '$fileType $fileLocation'.toLowerCase();
    if (text.contains('lab') || text.contains('blood')) {
      return PatientDocumentCategory.laboratory;
    }
    if (text.contains('xray') ||
        text.contains('radiology') ||
        text.contains('scan') ||
        text.contains('mri') ||
        text.contains('ct') ||
        text.contains('imaging')) {
      return PatientDocumentCategory.imaging;
    }
    return PatientDocumentCategory.other;
  }

  bool get isProbablyDownloadable {
    final path = fileLocation.trim();
    if (path.isEmpty) return false;
    if (path.startsWith('{') || path.startsWith('[')) return false;
    if (path.contains(',') && !path.contains('/') && !path.contains(r'\')) {
      return false;
    }
    return true;
  }
}

enum PatientDocumentCategory { laboratory, imaging, other }

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String _dateText(dynamic value) {
  final text = _text(value);
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}
