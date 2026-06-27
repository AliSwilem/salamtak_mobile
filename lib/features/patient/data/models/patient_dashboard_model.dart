class PatientDashboardModel {
  final List<PatientAppointmentPreview> upcomingAppointments;
  final List<PatientNotificationModel> notifications;

  const PatientDashboardModel({
    required this.upcomingAppointments,
    required this.notifications,
  });

  factory PatientDashboardModel.fromJson(Map<String, dynamic> json) {
    return PatientDashboardModel(
      upcomingAppointments: _list(
        json['UpcomingAppointments'],
      ).map(PatientAppointmentPreview.fromJson).toList(),
      notifications: _list(
        json['Notifications'],
      ).map(PatientNotificationModel.fromJson).toList(),
    );
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, nestedValue) => MapEntry(key.toString(), nestedValue),
          ),
        )
        .toList();
  }
}

class PatientAppointmentPreview {
  final int? id;
  final String doctorName;
  final String date;
  final String time;
  final String status;

  const PatientAppointmentPreview({
    this.id,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.status,
  });

  factory PatientAppointmentPreview.fromJson(Map<String, dynamic> json) {
    return PatientAppointmentPreview(
      id: _int(json['AppointmentID'] ?? json['appointment_id']),
      doctorName: _text(json['DoctorName'] ?? json['doctor_name']),
      date: _text(
        json['AppointmentDate'] ?? json['Date'] ?? json['appointment_date'],
      ),
      time: _text(json['Time'] ?? json['AppointmentTime'] ?? json['time']),
      status: _text(json['Status'] ?? json['status']),
    );
  }
}

class PatientNotificationModel {
  final int? id;
  final bool isRead;

  const PatientNotificationModel({this.id, required this.isRead});

  factory PatientNotificationModel.fromJson(Map<String, dynamic> json) {
    final raw = json['IsRead'] ?? json['is_read'];
    return PatientNotificationModel(
      id: _int(json['NotificationID'] ?? json['notification_id']),
      isRead:
          raw == true || raw == 1 || raw?.toString().toLowerCase() == 'true',
    );
  }
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _text(dynamic value) => value?.toString().trim() ?? '';
