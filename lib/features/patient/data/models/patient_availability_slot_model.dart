class PatientAvailabilitySlotModel {
  final String date;
  final String time;
  final String status;
  final bool available;

  const PatientAvailabilitySlotModel({
    required this.date,
    required this.time,
    required this.status,
    required this.available,
  });

  factory PatientAvailabilitySlotModel.fromJson(Map<String, dynamic> json) {
    final status = _text(json['Status'] ?? json['status']);
    final availableValue = json['available'] ?? json['Available'];
    return PatientAvailabilitySlotModel(
      date: _dateText(json['Date'] ?? json['date']),
      time: _timeText(
        json['Time'] ?? json['time'] ?? json['start_time'] ?? json['StartTime'],
      ),
      status: status,
      available: availableValue == null
          ? status.toLowerCase() != 'booked'
          : _bool(availableValue),
    );
  }

  String get displayTime => time.length >= 5 ? time.substring(0, 5) : time;
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String _dateText(dynamic value) {
  final text = _text(value);
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}

String _timeText(dynamic value) {
  final text = _text(value);
  if (text.length == 5) return '$text:00';
  return text;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes';
}
