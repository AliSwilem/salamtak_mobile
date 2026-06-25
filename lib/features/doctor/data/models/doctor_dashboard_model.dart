class DoctorDashboardModel {
  final List<DoctorAppointmentPreview> appointments;
  final List<DoctorPatientPreview> patients;

  const DoctorDashboardModel({
    required this.appointments,
    required this.patients,
  });

  factory DoctorDashboardModel.fromJson(Map<String, dynamic> json) {
    return DoctorDashboardModel(
      appointments: _list(
        json['appointments'] ?? json['Appointments'],
      ).map(DoctorAppointmentPreview.fromJson).toList(),
      patients: _list(
        json['patients'] ?? json['Patients'],
      ).map(DoctorPatientPreview.fromJson).toList(),
    );
  }
}

class DoctorStatsModel {
  final int today;
  final int completed;
  final int cancelled;
  final int noShow;

  const DoctorStatsModel({
    required this.today,
    required this.completed,
    required this.cancelled,
    required this.noShow,
  });

  factory DoctorStatsModel.fromJson(Map<String, dynamic> json) {
    return DoctorStatsModel(
      today: _parseInt(
        json['total_today'] ??
            json['TotalToday'] ??
            json['today'] ??
            json['Today'],
      ),
      completed: _parseInt(json['completed'] ?? json['Completed']),
      cancelled: _parseInt(json['cancelled'] ?? json['Cancelled']),
      noShow: _parseInt(
        json['no_show'] ?? json['NoShow'] ?? json['noShow'] ?? json['No_Show'],
      ),
    );
  }
}

class DoctorTodaySummaryModel {
  final String date;
  final int count;
  final List<DoctorAppointmentPreview> appointments;

  const DoctorTodaySummaryModel({
    required this.date,
    required this.count,
    required this.appointments,
  });

  factory DoctorTodaySummaryModel.fromJson(Map<String, dynamic> json) {
    final appointments = _list(
      json['appointments'] ?? json['Appointments'],
    ).map(DoctorAppointmentPreview.fromJson).toList();
    return DoctorTodaySummaryModel(
      date: _parseString(json['date'] ?? json['Date']),
      count: _parseInt(json['count'] ?? json['Count'] ?? appointments.length),
      appointments: appointments,
    );
  }
}

class DoctorAppointmentPreview {
  final int id;
  final int? patientId;
  final String patientName;
  final String date;
  final String time;
  final String status;

  const DoctorAppointmentPreview({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.status,
  });

  factory DoctorAppointmentPreview.fromJson(Map<String, dynamic> json) {
    return DoctorAppointmentPreview(
      id: _parseInt(json['AppointmentID'] ?? json['appointment_id']),
      patientId: _parseNullableInt(json['PatientID'] ?? json['patient_id']),
      patientName: _parseString(
        json['PatientName'] ??
            json['patient_name'] ??
            json['FullName'] ??
            json['full_name'],
      ),
      date: _parseString(json['Date'] ?? json['date']),
      time: _parseString(json['Time'] ?? json['time']),
      status: _parseString(json['Status'] ?? json['status']),
    );
  }
}

class DoctorPatientPreview {
  final int id;
  final String fullName;
  final String gender;
  final String contactInfo;

  const DoctorPatientPreview({
    required this.id,
    required this.fullName,
    required this.gender,
    required this.contactInfo,
  });

  factory DoctorPatientPreview.fromJson(Map<String, dynamic> json) {
    return DoctorPatientPreview(
      id: _parseInt(json['PatientID'] ?? json['patient_id']),
      fullName: _parseString(json['FullName'] ?? json['full_name']),
      gender: _parseString(json['Gender'] ?? json['gender']),
      contactInfo: _parseString(
        json['ContactInfo'] ?? json['contact_info'] ?? json['Phone'],
      ),
    );
  }
}

class DoctorActivityModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final String dateCreated;
  final bool isRead;

  const DoctorActivityModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.dateCreated,
    required this.isRead,
  });

  factory DoctorActivityModel.fromJson(Map<String, dynamic> json) {
    final message = _parseString(json['Message'] ?? json['message']);
    return DoctorActivityModel(
      id: _parseInt(json['NotificationID'] ?? json['notification_id']),
      title: _parseString(json['Title'] ?? json['title'] ?? message),
      message: message,
      type: _parseString(json['Type'] ?? json['type']),
      dateCreated: _parseString(json['DateCreated'] ?? json['date_created']),
      isRead: _parseBool(json['IsRead'] ?? json['is_read']),
    );
  }
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}

int _parseInt(dynamic value) => _parseNullableInt(value) ?? 0;

int? _parseNullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _parseString(dynamic value) {
  final parsed = value?.toString().trim();
  return parsed == null || parsed.isEmpty ? '' : parsed;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  final parsed = value?.toString().trim().toLowerCase();
  return parsed == 'true' || parsed == '1' || parsed == 'yes';
}
