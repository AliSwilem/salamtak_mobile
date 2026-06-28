import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/video_session_model.dart';

class VideoRepository {
  final ApiClient apiClient;

  const VideoRepository({required this.apiClient});

  Future<VideoSessionModel?> getSessionForAppointment(int appointmentId) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.videoSessionForAppointment(appointmentId),
      );
      return VideoSessionModel.fromJson(_map(response.data));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<VideoSessionModel> startSession(int appointmentId) async {
    final response = await apiClient.dio.post(
      ApiConstants.startVideoSession(appointmentId),
    );
    return VideoSessionModel.fromJson(_map(response.data));
  }

  Future<VideoSessionModel> joinSession(int appointmentId) async {
    final response = await apiClient.dio.post(
      ApiConstants.joinVideoSession(appointmentId),
    );
    return VideoSessionModel.fromJson(_map(response.data));
  }

  Future<VideoSessionModel> leaveSession(
    int sessionId, {
    String? reason,
  }) async {
    final response = await apiClient.dio.post(
      ApiConstants.leaveVideoSession(sessionId),
      data: VideoActionRequest(reason: reason).toJson(),
    );
    return VideoSessionModel.fromJson(_map(response.data));
  }

  Future<VideoSessionModel> endSession(int sessionId, {String? reason}) async {
    final response = await apiClient.dio.post(
      ApiConstants.endVideoSession(sessionId),
      data: VideoActionRequest(reason: reason).toJson(),
    );
    return VideoSessionModel.fromJson(_map(response.data));
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}
