class PatientFullNotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String dateCreated;
  final String type;
  final String referenceKey;
  final String fromName;

  const PatientFullNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.dateCreated,
    required this.type,
    required this.referenceKey,
    required this.fromName,
  });

  factory PatientFullNotificationModel.fromJson(Map<String, dynamic> json) {
    return PatientFullNotificationModel(
      id: _int(json['NotificationID'] ?? json['notification_id']) ?? 0,
      title: _text(json['Title'] ?? json['title']),
      message: _text(json['Message'] ?? json['message']),
      isRead: _bool(json['IsRead'] ?? json['is_read']),
      dateCreated: _dateText(json['DateCreated'] ?? json['date_created']),
      type: _text(json['Type'] ?? json['type']),
      referenceKey: _text(json['ReferenceKey'] ?? json['reference_key']),
      fromName: _text(json['FromName'] ?? json['from_name']),
    );
  }

  String get displayTitle => title.isEmpty ? 'Notification' : title;
  String get displayFrom => fromName.isEmpty ? 'System' : fromName;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes';
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String _dateText(dynamic value) {
  final text = _text(value);
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}
