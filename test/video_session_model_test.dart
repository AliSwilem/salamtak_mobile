import 'package:flutter_test/flutter_test.dart';
import 'package:salamtak_mobile/features/video/data/models/video_session_model.dart';

void main() {
  test('video session parses backend PascalCase fields defensively', () {
    final session = VideoSessionModel.fromJson({
      'VideoSessionID': 4,
      'AppointmentID': 17,
      'DoctorID': 2,
      'PatientID': 3,
      'Provider': 'livekit',
      'RoomName': 'room-123',
      'SessionStatus': 'active',
      'InitiatedByUserID': 9,
      'CurrentUserRole': 'doctor',
      'CanStart': true,
      'CanJoin': true,
      'CanEnd': true,
      'IsJoinable': true,
      'IsJoinableForPatient': true,
      'DoctorHasJoined': true,
      'PatientHasJoined': false,
      'WaitingForPatient': true,
      'LiveKitUrl': 'wss://example.livekit.cloud',
      'AccessToken': 'token',
      'PatientName': 'Ali Ahmed',
    });

    expect(session.id, 4);
    expect(session.appointmentId, 17);
    expect(session.status, 'active');
    expect(session.isActive, isTrue);
    expect(session.hasCredentials, isTrue);
    expect(session.currentUserHasJoined, isTrue);
    expect(session.participantName, 'Ali Ahmed');
    expect(session.waitingForPatient, isTrue);
  });

  test('video action request omits empty reasons', () {
    expect(const VideoActionRequest(reason: '').toJson(), isEmpty);
    expect(const VideoActionRequest(reason: 'doctor_ended_call').toJson(), {
      'reason': 'doctor_ended_call',
    });
  });
}
