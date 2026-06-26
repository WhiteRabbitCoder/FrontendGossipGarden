import 'package:dio/dio.dart';
import 'package:gossip_garden/core/services/api_client.dart';
import 'package:gossip_garden/features/plants/data/models/chat_dto.dart';

class BackendChatService {
  final ApiClient _apiClient;

  BackendChatService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ChatMessageResponse> chat({
    required String plantId,
    required String message,
    String responseFormat = 'text',
    String? imageBase64,
    String? userAudioBase64,
  }) async {
    try {
      final request = ChatMessageRequest(
        message: message, 
        responseFormat: responseFormat,
        imageBase64: imageBase64,
        userAudioBase64: userAudioBase64,
      );
      final response = await _apiClient.dio.post(
        '/chat/$plantId',
        data: request.toJson(),
      );
      return ChatMessageResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Error desconocido';
      throw Exception('Error en chat: $detail');
    }
  }

  Future<ChatHistoryResponse> getHistory(String plantId) async {
    try {
      final response = await _apiClient.dio.get('/chat/$plantId/history');
      return ChatHistoryResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Error desconocido';
      throw Exception('Error obteniendo historial: $detail');
    }
  }
}
