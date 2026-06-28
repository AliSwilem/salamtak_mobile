class ChatConversationModel {
  final int id;
  final int patientId;
  final int doctorId;
  final DateTime? createdAt;
  final String? patientName;
  final String? doctorName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatConversationModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.createdAt,
    this.patientName,
    this.doctorName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: _readInt(json, 'ConversationID', 'conversation_id', 'id'),
      patientId: _readInt(json, 'PatientID', 'patient_id'),
      doctorId: _readInt(json, 'DoctorID', 'doctor_id'),
      createdAt: _readDate(json, 'CreatedAt', 'created_at'),
      patientName: _readString(json, 'PatientName', 'patient_name'),
      doctorName: _readString(json, 'DoctorName', 'doctor_name'),
      lastMessage: _readString(json, 'LastMessage', 'last_message'),
      lastMessageAt: _readDate(json, 'LastMessageAt', 'last_message_at'),
      unreadCount: _readInt(json, 'UnreadCount', 'unread_count'),
    );
  }

  String titleForRole(String? role) {
    if (role == 'doctor') {
      return _fallbackName(patientName, 'Patient', patientId);
    }
    return _fallbackName(doctorName, 'Doctor', doctorId);
  }

  String subtitleForRole(String? role) {
    if (lastMessage?.trim().isNotEmpty == true) {
      return lastMessage!.trim();
    }
    return role == 'doctor'
        ? 'Start a secure patient conversation'
        : 'Start a secure doctor conversation';
  }
}

class ChatMessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderRole;
  final String content;
  final bool isRead;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.isRead,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: _readInt(json, 'MessageID', 'message_id', 'id'),
      conversationId: _readInt(json, 'ConversationID', 'conversation_id'),
      senderId: _readInt(json, 'SenderID', 'sender_id'),
      senderRole: (_readString(json, 'SenderRole', 'sender_role') ?? '')
          .trim()
          .toLowerCase(),
      content: _readString(json, 'Content', 'content') ?? '',
      isRead: _readBool(json, 'IsRead', 'is_read'),
      createdAt: _readDate(json, 'CreatedAt', 'created_at'),
    );
  }

  bool isMine(String? role) => senderRole == role?.trim().toLowerCase();
}

class ChatSearchResultModel {
  final int id;
  final String fullName;
  final String? specialization;
  final String? avatarUrl;

  const ChatSearchResultModel({
    required this.id,
    required this.fullName,
    this.specialization,
    this.avatarUrl,
  });

  factory ChatSearchResultModel.fromJson(Map<String, dynamic> json) {
    return ChatSearchResultModel(
      id: _readInt(
        json,
        'id',
        'DoctorID',
        'PatientID',
        'doctor_id',
        'patient_id',
      ),
      fullName:
          _readString(json, 'fullName', 'FullName', 'full_name') ??
          'Contact #${_readInt(json, 'id', 'DoctorID', 'PatientID')}',
      specialization: _readString(json, 'specialization', 'Specialization'),
      avatarUrl: _readString(json, 'avatarUrl', 'avatar_url'),
    );
  }
}

class ChatStartRequest {
  final int? patientId;
  final int? doctorId;

  const ChatStartRequest({this.patientId, this.doctorId});

  Map<String, dynamic> toJson() => {
    if (patientId != null) 'patient_id': patientId,
    if (doctorId != null) 'doctor_id': doctorId,
  };
}

class ChatSendMessageRequest {
  final String content;

  const ChatSendMessageRequest({required this.content});

  Map<String, dynamic> toJson() => {'content': content};
}

String _fallbackName(String? value, String label, int id) {
  final trimmed = value?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  return '$label #$id';
}

String? _readString(
  Map<String, dynamic> json,
  String key1, [
  String? key2,
  String? key3,
]) {
  final value =
      json[key1] ??
      (key2 == null ? null : json[key2]) ??
      (key3 == null ? null : json[key3]);
  if (value == null) return null;
  final text = value.toString();
  return text.trim().isEmpty ? null : text;
}

int _readInt(
  Map<String, dynamic> json,
  String key1, [
  String? key2,
  String? key3,
  String? key4,
  String? key5,
]) {
  final value =
      json[key1] ??
      (key2 == null ? null : json[key2]) ??
      (key3 == null ? null : json[key3]) ??
      (key4 == null ? null : json[key4]) ??
      (key5 == null ? null : json[key5]);
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _readBool(Map<String, dynamic> json, String key1, [String? key2]) {
  final value = json[key1] ?? (key2 == null ? null : json[key2]);
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString().toLowerCase() == 'true';
}

DateTime? _readDate(Map<String, dynamic> json, String key1, [String? key2]) {
  final value = json[key1] ?? (key2 == null ? null : json[key2]);
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
