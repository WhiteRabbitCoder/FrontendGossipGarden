import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gossip_garden/core/config/app_config.dart';
import 'package:gossip_garden/core/exceptions.dart';
import 'package:gossip_garden/features/plants/presentation/widgets/message_bubble.dart';

class BackendChatService {
  BackendChatService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String> chat({
    required String plantId,
    required String message,
    String language = 'es',
    String? token,
  }) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/v1/chat/$plantId');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
        'language': language,
        'response_format': 'text',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['reply'] as String?) ?? '';
    }
    if (response.statusCode == 401) {
      throw UnauthorizedException('Sesión expirada. Por favor vuelve a iniciar sesión.');
    }
    throw Exception('Error ${response.statusCode} en chat: ${response.body}');
  }

  Future<List<ChatMessage>> getHistory({
    required String plantId,
    String? token,
    int limit = 50,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.backendBaseUrl}/api/v1/chat/$plantId/history',
    ).replace(queryParameters: {'limit': limit.toString()});

    final response = await _httpClient.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final messages = (data['messages'] as List<dynamic>?) ?? [];
      return messages.map((m) {
        final role = m['role']?.toString() ?? 'user';
        return ChatMessage(
          id: '${m['timestamp']}_$role',
          content: m['content']?.toString() ?? '',
          sender: role == 'assistant' ? 'plant' : 'user',
          source: role == 'assistant' ? 'ai' : 'no-data',
          confidence: 'high',
          timestamp:
              DateTime.tryParse(m['timestamp']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList();
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Sesión expirada. Por favor vuelve a iniciar sesión.');
    }
    throw Exception(
        'Error ${response.statusCode} en historial: ${response.body}');
  }
}
