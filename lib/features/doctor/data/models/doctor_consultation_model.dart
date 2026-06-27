import 'doctor_patient_model.dart';

class DoctorDiagnosisCreateRequest {
  final int appointmentId;
  final String notes;

  const DoctorDiagnosisCreateRequest({
    required this.appointmentId,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'AppointmentID': appointmentId,
    'Notes': notes.trim(),
  };
}

class DoctorTreatmentCreateRequest {
  final int diagnosisId;
  final int? treatmentTypeId;
  final String? startDate;
  final String? endDate;
  final String? result;

  const DoctorTreatmentCreateRequest({
    required this.diagnosisId,
    this.treatmentTypeId,
    this.startDate,
    this.endDate,
    this.result,
  });

  Map<String, dynamic> toJson() => {
    'DiagnosisID': diagnosisId,
    if (treatmentTypeId != null) 'TreatmentTypeID': treatmentTypeId,
    if (startDate?.trim().isNotEmpty == true) 'StartDate': startDate!.trim(),
    if (endDate?.trim().isNotEmpty == true) 'EndDate': endDate!.trim(),
    if (result?.trim().isNotEmpty == true) 'Result': result!.trim(),
  };
}

class DoctorTreatmentMedicationRequest {
  final int treatmentId;
  final int medicationId;
  final String? dosageInstructions;

  const DoctorTreatmentMedicationRequest({
    required this.treatmentId,
    required this.medicationId,
    this.dosageInstructions,
  });

  Map<String, dynamic> toJson() => {
    'TreatmentID': treatmentId,
    'MedicationID': medicationId,
    if (dosageInstructions?.trim().isNotEmpty == true)
      'DosageInstructions': dosageInstructions!.trim(),
  };
}

class DoctorSummaryCreateRequest {
  final int patientId;
  final String keyFindings;
  final String recommendations;

  const DoctorSummaryCreateRequest({
    required this.patientId,
    required this.keyFindings,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'PatientID': patientId,
    'KeyFindings': keyFindings.trim(),
    'Recommendations': recommendations.trim(),
  };
}

class DoctorMedicationModel {
  final int id;
  final String name;
  final String dosage;
  final String description;

  const DoctorMedicationModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.description,
  });

  factory DoctorMedicationModel.fromJson(Map<String, dynamic> json) {
    return DoctorMedicationModel(
      id: _int(json['MedicationID'] ?? json['medication_id']),
      name: _text(json['Name'] ?? json['name']),
      dosage: _text(json['Dosage'] ?? json['dosage']),
      description: _text(json['Description'] ?? json['description']),
    );
  }
}

class DoctorTreatmentTypeModel {
  final int id;
  final String name;

  const DoctorTreatmentTypeModel({required this.id, required this.name});

  factory DoctorTreatmentTypeModel.fromJson(Map<String, dynamic> json) {
    return DoctorTreatmentTypeModel(
      id: _int(json['TreatmentTypeID'] ?? json['treatment_type_id']),
      name: _text(json['Name'] ?? json['name']),
    );
  }
}

class DoctorSummaryModel {
  final int id;
  final int patientId;
  final String date;
  final String keyFindings;
  final String recommendations;

  const DoctorSummaryModel({
    required this.id,
    required this.patientId,
    required this.date,
    required this.keyFindings,
    required this.recommendations,
  });

  factory DoctorSummaryModel.fromJson(Map<String, dynamic> json) {
    return DoctorSummaryModel(
      id: _int(json['SummaryID'] ?? json['summary_id']),
      patientId: _int(json['PatientID'] ?? json['patient_id']),
      date: _dateText(json['SummaryDate'] ?? json['summary_date']),
      keyFindings: _text(json['KeyFindings'] ?? json['key_findings']),
      recommendations: _text(
        json['Recommendations'] ?? json['recommendations'],
      ),
    );
  }
}

class DoctorConsultationData {
  final DoctorConsultationHistoryModel history;
  final List<DoctorMedicationModel> medications;
  final List<DoctorTreatmentTypeModel> treatmentTypes;

  const DoctorConsultationData({
    required this.history,
    required this.medications,
    required this.treatmentTypes,
  });
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _text(dynamic value) {
  final parsed = value?.toString().trim();
  return parsed == null || parsed.isEmpty ? '' : parsed;
}

String _dateText(dynamic value) {
  final text = _text(value);
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}
