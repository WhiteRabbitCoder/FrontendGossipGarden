import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:gossip_garden/core/services/api_client.dart';
import 'package:gossip_garden/core/services/cache_service.dart';
import 'package:gossip_garden/features/plants/data/models/chat_dto.dart';

class BackendChatService {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  BackendChatService({ApiClient? apiClient, CacheService? cacheService})
      : _apiClient = apiClient ?? ApiClient(),
        _cacheService = cacheService ?? CacheService();

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
      // Actualizar historial local después de enviar un mensaje (Opcional, pero para mantener coherencia en caché si se puede, aunque por ahora solo confiamos en getHistory).
      return ChatMessageResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Error desconocido';
      throw Exception('Error en chat: $detail');
    }
  }

  Future<ChatHistoryResponse> getHistory(String plantId) async {
    try {
      final response = await _apiClient.dio.get('/chat/$plantId/history');
      
      try {
        await _cacheService.saveChatData(plantId, jsonEncode(response.data));
      } catch (_) {}

      return ChatHistoryResponse.fromJson(response.data);
    } on DioException catch (e) {
      // Fallback a caché
      try {
        final cachedData = await _cacheService.getChatData(plantId);
        if (cachedData != null) {
          final data = jsonDecode(cachedData);
          return ChatHistoryResponse.fromJson(data);
        }
      } catch (_) {}

      final detail = e.response?.data?['detail'] ?? 'Error desconocido';
      throw Exception('Error obteniendo historial: $detail');
    }
  }

  Future<String> transcribeAudio(String base64Audio) async {
    try {
      final response = await _apiClient.dio.post(
        '/chat/transcribe',
        data: {'user_audio_base64': base64Audio},
      );
      return response.data['transcription'] as String;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Error desconocido';
      throw Exception('Error transcribiendo audio: $detail');
    }
  }

  Future<VoicesResponse> getVoices(String plantId) async {
    try {
      final response = await _apiClient.dio.get('/chat/$plantId/voices');
      return VoicesResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Error desconocido';
      throw Exception('Error obteniendo voces: $detail');
    }
  }

  Future<VoicesResponse> setVoice(String plantId, String voiceId) async {
    try {
      final request = SetVoiceRequest(voiceId: voiceId);
      final response = await _apiClient.dio.patch(
        '/chat/$plantId/voice',
        data: request.toJson(),
      );
      return VoicesResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Error desconocido';
      throw Exception('Error estableciendo voz: $detail');
    }
  }
}
