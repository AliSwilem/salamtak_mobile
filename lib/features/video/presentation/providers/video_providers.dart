import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/video_session_model.dart';
import '../../data/repositories/video_repository.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository(apiClient: ref.watch(apiClientProvider));
});

final videoSessionProvider = FutureProvider.family<VideoSessionModel?, int>((
  ref,
  appointmentId,
) {
  final authState = ref.watch(authControllerProvider);
  if (!authState.isAuthenticated) return null;
  return ref
      .watch(videoRepositoryProvider)
      .getSessionForAppointment(appointmentId);
});

final videoActionProvider = AsyncNotifierProvider<VideoActionController, void>(
  VideoActionController.new,
);

class VideoActionController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<VideoSessionModel?> start(int appointmentId) async {
    VideoSessionModel? session;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      session = await ref
          .read(videoRepositoryProvider)
          .startSession(appointmentId);
      ref.invalidate(videoSessionProvider(appointmentId));
    });
    return session;
  }

  Future<VideoSessionModel?> join(int appointmentId) async {
    VideoSessionModel? session;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      session = await ref
          .read(videoRepositoryProvider)
          .joinSession(appointmentId);
      ref.invalidate(videoSessionProvider(appointmentId));
    });
    return session;
  }

  Future<VideoSessionModel?> leave({
    required int appointmentId,
    required int sessionId,
    String? reason,
  }) async {
    VideoSessionModel? session;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      session = await ref
          .read(videoRepositoryProvider)
          .leaveSession(sessionId, reason: reason);
      ref.invalidate(videoSessionProvider(appointmentId));
    });
    return session;
  }

  Future<VideoSessionModel?> end({
    required int appointmentId,
    required int sessionId,
    String? reason,
  }) async {
    VideoSessionModel? session;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      session = await ref
          .read(videoRepositoryProvider)
          .endSession(sessionId, reason: reason);
      ref.invalidate(videoSessionProvider(appointmentId));
    });
    return session;
  }
}
