class DoctorPatientModel {
  final int id;
  final String fullName;
  final String gender;
  final String dateOfBirth;
  final String contactInfo;
  final String address;
  final String bloodType;
  final String medicalHistory;
  final int? userId;

  const DoctorPatientModel({
    required this.id,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.contactInfo,
    required this.address,
    required this.bloodType,
    required this.medicalHistory,
    required this.userId,
  });

  factory DoctorPatientModel.fromJson(Map<String, dynamic> json) {
    return DoctorPatientModel(
      id: _int(json['PatientID'] ?? json['patient_id']),
      fullName: _text(json['FullName'] ?? json['full_name']),
      gender: _text(json['Gender'] ?? json['gender']),
      dateOfBirth: _dateText(json['DateOfBirth'] ?? json['date_of_birth']),
      contactInfo: _text(
        json['ContactInfo'] ?? json['contact_info'] ?? json['Phone'],
      ),
      address: _text(json['Address'] ?? json['address']),
      bloodType: _text(json['BloodType'] ?? json['blood_type']),
      medicalHistory: _text(json['MedicalHistory'] ?? json['medical_history']),
      userId: _nullableInt(json['UserID'] ?? json['user_id']),
    );
  }

  String get displayName => fullName.isEmpty ? 'Patient #$id' : fullName;

  int? get age {
    if (dateOfBirth.isEmpty) return null;
    final birthDate = DateTime.tryParse(dateOfBirth);
    if (birthDate == null) return null;
    final today = DateTime.now();
    var years = today.year - birthDate.year;
    final hadBirthday =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hadBirthday) years--;
    return years >= 0 ? years : null;
  }
}

class DoctorPatientSummaryModel {
  final int diagnoses;
  final int treatments;
  final int ehrFiles;

  const DoctorPatientSummaryModel({
    required this.diagnoses,
    required this.treatments,
    required this.ehrFiles,
  });

  factory DoctorPatientSummaryModel.fromJson(Map<String, dynamic> json) {
    return DoctorPatientSummaryModel(
      diagnoses: _int(json['diagnoses'] ?? json['Diagnoses']),
      treatments: _int(json['treatments'] ?? json['Treatments']),
      ehrFiles: _int(json['ehr_files'] ?? json['EhrFiles'] ?? json['EHRFiles']),
    );
  }
}

class DoctorPatientStatisticsModel {
  final String lastDiagnosisDate;
  final int activeTreatments;

  const DoctorPatientStatisticsModel({
    required this.lastDiagnosisDate,
    required this.activeTreatments,
  });

  factory DoctorPatientStatisticsModel.fromJson(Map<String, dynamic> json) {
    return DoctorPatientStatisticsModel(
      lastDiagnosisDate: _dateText(
        json['last_diagnosis_date'] ?? json['LastDiagnosisDate'],
      ),
      activeTreatments: _int(
        json['active_treatments'] ?? json['ActiveTreatments'],
      ),
    );
  }
}

class DoctorConsultationHistoryModel {
  final List<DoctorDiagnosisModel> diagnoses;
  final List<DoctorTreatmentModel> treatments;

  const DoctorConsultationHistoryModel({
    required this.diagnoses,
    required this.treatments,
  });

  factory DoctorConsultationHistoryModel.fromJson(Map<String, dynamic> json) {
    return DoctorConsultationHistoryModel(
      diagnoses: _list(
        json['diagnoses'] ?? json['Diagnoses'],
      ).map(DoctorDiagnosisModel.fromJson).toList(),
      treatments: _list(
        json['treatments'] ?? json['Treatments'],
      ).map(DoctorTreatmentModel.fromJson).toList(),
    );
  }
}

class DoctorDiagnosisModel {
  final int id;
  final String date;
  final int patientId;
  final int doctorId;
  final int? diseaseId;
  final double? confidenceLevel;
  final String notes;

  const DoctorDiagnosisModel({
    required this.id,
    required this.date,
    required this.patientId,
    required this.doctorId,
    required this.diseaseId,
    required this.confidenceLevel,
    required this.notes,
  });

  factory DoctorDiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DoctorDiagnosisModel(
      id: _int(json['DiagnosisID'] ?? json['diagnosis_id']),
      date: _dateText(json['DiagnosisDate'] ?? json['diagnosis_date']),
      patientId: _int(json['PatientID'] ?? json['patient_id']),
      doctorId: _int(json['DoctorID'] ?? json['doctor_id']),
      diseaseId: _nullableInt(json['DiseaseID'] ?? json['disease_id']),
      confidenceLevel: _nullableDouble(
        json['ConfidenceLevel'] ?? json['confidence_level'],
      ),
      notes: _text(json['Notes'] ?? json['notes']),
    );
  }
}

class DoctorTreatmentModel {
  final int id;
  final int diagnosisId;
  final int? treatmentTypeId;
  final String startDate;
  final String endDate;
  final String result;
  final String description;

  const DoctorTreatmentModel({
    required this.id,
    required this.diagnosisId,
    required this.treatmentTypeId,
    required this.startDate,
    required this.endDate,
    required this.result,
    required this.description,
  });

  factory DoctorTreatmentModel.fromJson(Map<String, dynamic> json) {
    return DoctorTreatmentModel(
      id: _int(json['TreatmentID'] ?? json['treatment_id']),
      diagnosisId: _int(json['DiagnosisID'] ?? json['diagnosis_id']),
      treatmentTypeId: _nullableInt(
        json['TreatmentTypeID'] ?? json['treatment_type_id'],
      ),
      startDate: _dateText(json['StartDate'] ?? json['start_date']),
      endDate: _dateText(json['EndDate'] ?? json['end_date']),
      result: _text(json['Result'] ?? json['result']),
      description: _text(json['Description'] ?? json['description']),
    );
  }
}

int _int(dynamic value) => _nullableInt(value) ?? 0;

int? _nullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _nullableDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
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

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}
