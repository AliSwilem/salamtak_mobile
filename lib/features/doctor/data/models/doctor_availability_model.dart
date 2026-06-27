class DoctorAvailabilitySlotModel {
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  const DoctorAvailabilitySlotModel({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory DoctorAvailabilitySlotModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilitySlotModel(
      dayOfWeek: _int(json['day_of_week'] ?? json['DayOfWeek']),
      startTime: _timeText(json['start_time'] ?? json['StartTime']),
      endTime: _timeText(json['end_time'] ?? json['EndTime']),
    );
  }

  Map<String, dynamic> toJson() => {
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
  };

  DoctorAvailabilitySlotModel copyWith({
    int? dayOfWeek,
    String? startTime,
    String? endTime,
  }) {
    return DoctorAvailabilitySlotModel(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  String get displayStartTime => _displayTime(startTime);
  String get displayEndTime => _displayTime(endTime);
}

class DoctorAvailabilityModel {
  final int doctorId;
  final List<DoctorAvailabilitySlotModel> slots;

  const DoctorAvailabilityModel({required this.doctorId, required this.slots});

  factory DoctorAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilityModel(
      doctorId: _int(json['doctor_id'] ?? json['DoctorID']),
      slots: _list(
        json['slots'] ?? json['Slots'],
      ).map(DoctorAvailabilitySlotModel.fromJson).toList(),
    );
  }
}

class DoctorAvailabilityStatsModel {
  final int doctorId;
  final int entries;

  const DoctorAvailabilityStatsModel({
    required this.doctorId,
    required this.entries,
  });

  factory DoctorAvailabilityStatsModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilityStatsModel(
      doctorId: _int(json['doctor_id'] ?? json['DoctorID']),
      entries: _int(json['entries'] ?? json['Entries']),
    );
  }
}

class DoctorAvailabilitySyncResult {
  final bool synced;
  final String mode;
  final String message;

  const DoctorAvailabilitySyncResult({
    required this.synced,
    required this.mode,
    required this.message,
  });

  factory DoctorAvailabilitySyncResult.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilitySyncResult(
      synced: _bool(json['synced'] ?? json['Synced']),
      mode: _text(json['mode'] ?? json['Mode']),
      message: _text(json['message'] ?? json['Message']),
    );
  }
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

String _timeText(dynamic value) {
  final text = _text(value);
  if (text.length == 5) return '$text:00';
  return text;
}

String _displayTime(String value) {
  if (value.length >= 5) return value.substring(0, 5);
  return value;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  final parsed = value?.toString().trim().toLowerCase();
  return parsed == 'true' || parsed == '1' || parsed == 'yes';
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}
