class VideoSessionModel {
  final int id;
  final int appointmentId;
  final int doctorId;
  final int patientId;
  final String provider;
  final String roomName;
  final String status;
  final int initiatedByUserId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? doctorJoinedAt;
  final DateTime? patientJoinedAt;
  final DateTime? lastActivityAt;
  final DateTime? joinWindowStart;
  final DateTime? joinWindowEnd;
  final int? endedByUserId;
  final String? providerMetadataJson;
  final String currentUserRole;
  final bool canStart;
  final bool canJoin;
  final bool canEnd;
  final bool isJoinable;
  final bool isJoinableForPatient;
  final bool doctorHasJoined;
  final bool patientHasJoined;
  final bool waitingForDoctor;
  final bool waitingForPatient;
  final bool globalVideoCallsEnabled;
  final bool allowNewSessions;
  final bool allowExistingSessionsToContinue;
  final String? noticeMessage;
  final String? endReason;
  final String? endedByRole;
  final String? endedByDisplayName;
  final String? doctorName;
  final String? patientName;
  final String? liveKitUrl;
  final String? accessToken;

  const VideoSessionModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.provider,
    required this.roomName,
    required this.status,
    required this.initiatedByUserId,
    this.startedAt,
    this.endedAt,
    this.doctorJoinedAt,
    this.patientJoinedAt,
    this.lastActivityAt,
    this.joinWindowStart,
    this.joinWindowEnd,
    this.endedByUserId,
    this.providerMetadataJson,
    required this.currentUserRole,
    required this.canStart,
    required this.canJoin,
    required this.canEnd,
    required this.isJoinable,
    required this.isJoinableForPatient,
    required this.doctorHasJoined,
    required this.patientHasJoined,
    required this.waitingForDoctor,
    required this.waitingForPatient,
    required this.globalVideoCallsEnabled,
    required this.allowNewSessions,
    required this.allowExistingSessionsToContinue,
    this.noticeMessage,
    this.endReason,
    this.endedByRole,
    this.endedByDisplayName,
    this.doctorName,
    this.patientName,
    this.liveKitUrl,
    this.accessToken,
  });

  factory VideoSessionModel.fromJson(Map<String, dynamic> json) {
    return VideoSessionModel(
      id: _int(json, 'VideoSessionID', 'video_session_id', 'id'),
      appointmentId: _int(json, 'AppointmentID', 'appointment_id'),
      doctorId: _int(json, 'DoctorID', 'doctor_id'),
      patientId: _int(json, 'PatientID', 'patient_id'),
      provider: _text(json, 'Provider', 'provider') ?? 'livekit',
      roomName: _text(json, 'RoomName', 'room_name') ?? '',
      status: (_text(json, 'SessionStatus', 'session_status', 'Status') ?? '')
          .toLowerCase(),
      initiatedByUserId: _int(
        json,
        'InitiatedByUserID',
        'initiated_by_user_id',
      ),
      startedAt: _date(json, 'StartedAt', 'started_at'),
      endedAt: _date(json, 'EndedAt', 'ended_at'),
      doctorJoinedAt: _date(json, 'DoctorJoinedAt', 'doctor_joined_at'),
      patientJoinedAt: _date(json, 'PatientJoinedAt', 'patient_joined_at'),
      lastActivityAt: _date(json, 'LastActivityAt', 'last_activity_at'),
      joinWindowStart: _date(json, 'JoinWindowStart', 'join_window_start'),
      joinWindowEnd: _date(json, 'JoinWindowEnd', 'join_window_end'),
      endedByUserId: _nullableInt(json, 'EndedByUserID', 'ended_by_user_id'),
      providerMetadataJson: _text(
        json,
        'ProviderMetadataJson',
        'provider_metadata_json',
      ),
      currentUserRole:
          (_text(json, 'CurrentUserRole', 'current_user_role') ?? '')
              .toLowerCase(),
      canStart: _bool(json, 'CanStart', 'can_start'),
      canJoin: _bool(json, 'CanJoin', 'can_join'),
      canEnd: _bool(json, 'CanEnd', 'can_end'),
      isJoinable: _bool(json, 'IsJoinable', 'is_joinable'),
      isJoinableForPatient: _bool(
        json,
        'IsJoinableForPatient',
        'is_joinable_for_patient',
      ),
      doctorHasJoined: _bool(json, 'DoctorHasJoined', 'doctor_has_joined'),
      patientHasJoined: _bool(json, 'PatientHasJoined', 'patient_has_joined'),
      waitingForDoctor: _bool(json, 'WaitingForDoctor', 'waiting_for_doctor'),
      waitingForPatient: _bool(
        json,
        'WaitingForPatient',
        'waiting_for_patient',
      ),
      globalVideoCallsEnabled: _boolDefault(
        json,
        true,
        'GlobalVideoCallsEnabled',
        'global_video_calls_enabled',
      ),
      allowNewSessions: _boolDefault(
        json,
        true,
        'AllowNewSessions',
        'allow_new_sessions',
      ),
      allowExistingSessionsToContinue: _boolDefault(
        json,
        true,
        'AllowExistingSessionsToContinue',
        'allow_existing_sessions_to_continue',
      ),
      noticeMessage: _text(json, 'NoticeMessage', 'notice_message'),
      endReason: _text(json, 'EndReason', 'end_reason'),
      endedByRole: _text(json, 'EndedByRole', 'ended_by_role'),
      endedByDisplayName: _text(
        json,
        'EndedByDisplayName',
        'ended_by_display_name',
      ),
      doctorName: _text(json, 'DoctorName', 'doctor_name'),
      patientName: _text(json, 'PatientName', 'patient_name'),
      liveKitUrl: _text(json, 'LiveKitUrl', 'livekit_url', 'LiveKitURL'),
      accessToken: _text(json, 'AccessToken', 'access_token'),
    );
  }

  bool get isActive => status == 'active' && endedAt == null;

  bool get hasCredentials =>
      liveKitUrl?.isNotEmpty == true && accessToken?.isNotEmpty == true;

  bool get currentUserHasJoined {
    if (currentUserRole == 'doctor') return doctorHasJoined;
    if (currentUserRole == 'patient') return patientHasJoined;
    return false;
  }

  String get displayStatus {
    if (status.isEmpty) return 'Unknown';
    return status
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String get participantName {
    if (currentUserRole == 'doctor') {
      return patientName?.trim().isNotEmpty == true
          ? patientName!.trim()
          : 'Patient #$patientId';
    }
    return doctorName?.trim().isNotEmpty == true
        ? doctorName!.trim()
        : 'Doctor #$doctorId';
  }
}

class VideoActionRequest {
  final String? reason;

  const VideoActionRequest({this.reason});

  Map<String, dynamic> toJson() => {
    if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
  };
}

int _int(Map<String, dynamic> json, String key1, [String? key2, String? key3]) {
  return _nullableInt(json, key1, key2, key3) ?? 0;
}

int? _nullableInt(
  Map<String, dynamic> json,
  String key1, [
  String? key2,
  String? key3,
]) {
  final value =
      json[key1] ??
      (key2 == null ? null : json[key2]) ??
      (key3 == null ? null : json[key3]);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _text(
  Map<String, dynamic> json,
  String key1, [
  String? key2,
  String? key3,
]) {
  final value =
      json[key1] ??
      (key2 == null ? null : json[key2]) ??
      (key3 == null ? null : json[key3]);
  final parsed = value?.toString().trim();
  return parsed == null || parsed.isEmpty ? null : parsed;
}

bool _bool(Map<String, dynamic> json, String key1, [String? key2]) {
  return _boolDefault(json, false, key1, key2);
}

bool _boolDefault(
  Map<String, dynamic> json,
  bool defaultValue,
  String key1, [
  String? key2,
]) {
  final value = json[key1] ?? (key2 == null ? null : json[key2]);
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

DateTime? _date(Map<String, dynamic> json, String key1, [String? key2]) {
  final value = json[key1] ?? (key2 == null ? null : json[key2]);
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
