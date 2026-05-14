import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gossip_garden/core/config/app_config.dart';

// PENDIENTE: endpoint POST /api/v1/chat/{plant_id} aún no implementado en el backend.
// Ver PENDING_BACKEND.md — hasta que exista, PlantChatScreen usa Firestore como fallback.
class BackendChatService {
  BackendChatService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String> chat({
    required String plantId,
    required String message,
    String? token,
  }) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/v1/chat/$plantId');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['response'] as String?) ?? '';
    }

    throw Exception('Error ${response.statusCode} en chat: ${response.body}');
  }
}
