enum DoctorAppointmentStatus {
  scheduled,
  completed,
  cancelled,
  noShow,
  rescheduled;

  String get apiValue {
    return switch (this) {
      DoctorAppointmentStatus.scheduled => 'scheduled',
      DoctorAppointmentStatus.completed => 'completed',
      DoctorAppointmentStatus.cancelled => 'cancelled',
      DoctorAppointmentStatus.noShow => 'no_show',
      DoctorAppointmentStatus.rescheduled => 'rescheduled',
    };
  }

  String get label {
    return switch (this) {
      DoctorAppointmentStatus.scheduled => 'Scheduled',
      DoctorAppointmentStatus.completed => 'Completed',
      DoctorAppointmentStatus.cancelled => 'Cancelled',
      DoctorAppointmentStatus.noShow => 'No-show',
      DoctorAppointmentStatus.rescheduled => 'Rescheduled',
    };
  }

  static DoctorAppointmentStatus fromApi(String value) {
    final normalized = value.trim().toLowerCase();
    return DoctorAppointmentStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => DoctorAppointmentStatus.scheduled,
    );
  }
}

class DoctorAppointmentModel {
  final int id;
  final int patientId;
  final int doctorId;
  final int? hospitalId;
  final String patientName;
  final String date;
  final String time;
  final String status;

  const DoctorAppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.hospitalId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.status,
  });

  factory DoctorAppointmentModel.fromJson(Map<String, dynamic> json) {
    return DoctorAppointmentModel(
      id: _int(json['AppointmentID'] ?? json['appointment_id']),
      patientId: _int(json['PatientID'] ?? json['patient_id']),
      doctorId: _int(json['DoctorID'] ?? json['doctor_id']),
      hospitalId: _nullableInt(json['HospitalID'] ?? json['hospital_id']),
      patientName: _text(
        json['PatientName'] ??
            json['patient_name'] ??
            json['FullName'] ??
            json['full_name'],
      ),
      date: _text(json['Date'] ?? json['date']),
      time: _text(json['Time'] ?? json['time']),
      status: _text(json['Status'] ?? json['status']),
    );
  }

  DoctorAppointmentStatus get parsedStatus {
    return DoctorAppointmentStatus.fromApi(status);
  }

  DoctorAppointmentModel copyWith({
    int? id,
    int? patientId,
    int? doctorId,
    int? hospitalId,
    String? patientName,
    String? date,
    String? time,
    String? status,
  }) {
    return DoctorAppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      hospitalId: hospitalId ?? this.hospitalId,
      patientName: patientName ?? this.patientName,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }

  String get displayPatientName {
    if (patientName.isNotEmpty) return patientName;
    if (patientId > 0) return 'Patient #$patientId';
    return 'Patient';
  }

  String get displayStatus {
    return parsedStatus.label;
  }
}

int _int(dynamic value) => _nullableInt(value) ?? 0;

int? _nullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _text(dynamic value) {
  final parsed = value?.toString().trim();
  return parsed == null || parsed.isEmpty ? '' : parsed;
}
