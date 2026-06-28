import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(apiClient: ref.watch(apiClientProvider));
});

final chatConversationsProvider = FutureProvider<List<ChatConversationModel>>((
  ref,
) {
  final authState = ref.watch(authControllerProvider);
  if (!authState.isAuthenticated) {
    return const <ChatConversationModel>[];
  }
  return ref.watch(chatRepositoryProvider).listConversations();
});

final chatMessagesProvider = FutureProvider.family<List<ChatMessageModel>, int>(
  (ref, conversationId) {
    final authState = ref.watch(authControllerProvider);
    if (!authState.isAuthenticated) {
      return const <ChatMessageModel>[];
    }
    return ref.watch(chatRepositoryProvider).getMessages(conversationId);
  },
);

final chatUnreadCountProvider = FutureProvider<int>((ref) async {
  final conversations = await ref.watch(chatConversationsProvider.future);
  return conversations.fold<int>(
    0,
    (total, conversation) => total + conversation.unreadCount,
  );
});

final chatSearchProvider =
    FutureProvider.family<List<ChatSearchResultModel>, String>((ref, query) {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return const <ChatSearchResultModel>[];

      final role = ref.watch(authControllerProvider).role;
      final repository = ref.watch(chatRepositoryProvider);
      if (role == 'doctor') {
        return repository.searchPatients(trimmed);
      }
      if (role == 'patient') {
        return repository.searchDoctors(trimmed);
      }
      return const <ChatSearchResultModel>[];
    });

final chatActionProvider = AsyncNotifierProvider<ChatActionController, void>(
  ChatActionController.new,
);

class ChatActionController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<ChatConversationModel?> startConversation({
    int? patientId,
    int? doctorId,
  }) async {
    ChatConversationModel? conversation;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      conversation = await ref
          .read(chatRepositoryProvider)
          .startConversation(
            ChatStartRequest(patientId: patientId, doctorId: doctorId),
          );
      ref.invalidate(chatConversationsProvider);
    });
    return conversation;
  }

  Future<ChatMessageModel?> sendMessage({
    required int conversationId,
    required String content,
  }) async {
    ChatMessageModel? message;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      message = await ref
          .read(chatRepositoryProvider)
          .sendMessage(conversationId: conversationId, content: content);
      ref.invalidate(chatMessagesProvider(conversationId));
      ref.invalidate(chatConversationsProvider);
    });
    return message;
  }

  Future<void> markRead({required int messageId, int? conversationId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(chatRepositoryProvider).markRead(messageId);
      if (conversationId != null) {
        ref.invalidate(chatMessagesProvider(conversationId));
      }
      ref.invalidate(chatConversationsProvider);
    });
  }
}
