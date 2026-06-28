import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salamtak_mobile/features/chat/data/models/chat_models.dart';
import 'package:salamtak_mobile/features/chat/presentation/chat_text_direction.dart';

void main() {
  group('Chat models', () {
    test('parses PascalCase conversation responses defensively', () {
      final conversation = ChatConversationModel.fromJson({
        'ConversationID': 12,
        'PatientID': 3,
        'DoctorID': 8,
        'PatientName': 'Ali Ahmed',
        'DoctorName': 'Hazem',
        'LastMessage': 'Hello',
        'UnreadCount': 2,
      });

      expect(conversation.id, 12);
      expect(conversation.patientId, 3);
      expect(conversation.doctorId, 8);
      expect(conversation.titleForRole('doctor'), 'Ali Ahmed');
      expect(conversation.titleForRole('patient'), 'Hazem');
      expect(conversation.unreadCount, 2);
    });

    test('parses snake_case message responses defensively', () {
      final message = ChatMessageModel.fromJson({
        'message_id': 20,
        'conversation_id': 12,
        'sender_id': 5,
        'sender_role': 'patient',
        'content': 'Thanks doctor',
        'is_read': false,
      });

      expect(message.id, 20);
      expect(message.conversationId, 12);
      expect(message.content, 'Thanks doctor');
      expect(message.isMine('patient'), isTrue);
      expect(message.isRead, isFalse);
    });

    test('serializes start and send requests with backend field names', () {
      expect(const ChatStartRequest(patientId: 3).toJson(), {'patient_id': 3});
      expect(const ChatStartRequest(doctorId: 8).toJson(), {'doctor_id': 8});
      expect(const ChatSendMessageRequest(content: 'Hello').toJson(), {
        'content': 'Hello',
      });
    });
  });

  group('Chat text direction', () {
    test('detects Arabic messages as RTL', () {
      expect(textDirectionFor('السلام عليكم يا دكتور'), TextDirection.rtl);
      expect(textAlignFor('السلام عليكم يا دكتور'), TextAlign.right);
    });

    test('keeps English messages LTR', () {
      expect(textDirectionFor('Hello doctor'), TextDirection.ltr);
      expect(textAlignFor('Hello doctor'), TextAlign.left);
    });
  });
}
