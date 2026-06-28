import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_models.dart';

class ChatRepository {
  final ApiClient apiClient;

  const ChatRepository({required this.apiClient});

  Future<List<ChatConversationModel>> listConversations() async {
    final response = await apiClient.dio.get(ApiConstants.chatConversations);
    return _list(response.data).map(ChatConversationModel.fromJson).toList();
  }

  Future<ChatConversationModel> startConversation(
    ChatStartRequest request,
  ) async {
    final response = await apiClient.dio.post(
      ApiConstants.chatStart,
      data: request.toJson(),
    );
    return ChatConversationModel.fromJson(_map(response.data));
  }

  Future<List<ChatMessageModel>> getMessages(
    int conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await apiClient.dio.get(
      ApiConstants.chatMessages(conversationId),
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return _list(response.data).map(ChatMessageModel.fromJson).toList();
  }

  Future<ChatMessageModel> sendMessage({
    required int conversationId,
    required String content,
  }) async {
    final response = await apiClient.dio.post(
      ApiConstants.chatMessages(conversationId),
      data: ChatSendMessageRequest(content: content).toJson(),
    );
    return ChatMessageModel.fromJson(_map(response.data));
  }

  Future<void> markRead(int messageId) async {
    await apiClient.dio.put(ApiConstants.chatMarkRead(messageId));
  }

  Future<List<ChatSearchResultModel>> searchDoctors(
    String query, {
    int limit = 10,
  }) async {
    final response = await apiClient.dio.get(
      ApiConstants.chatSearchDoctors,
      queryParameters: {'q': query, 'limit': limit},
    );
    return _list(response.data).map(ChatSearchResultModel.fromJson).toList();
  }

  Future<List<ChatSearchResultModel>> searchPatients(
    String query, {
    int limit = 10,
  }) async {
    final response = await apiClient.dio.get(
      ApiConstants.chatSearchPatients,
      queryParameters: {'q': query, 'limit': limit},
    );
    return _list(response.data).map(ChatSearchResultModel.fromJson).toList();
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }
}
