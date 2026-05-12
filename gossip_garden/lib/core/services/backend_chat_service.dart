import 'dart:convert';
import 'package:http/http.dart' as http;

const _chatBaseUrl = 'https://deacon-graveless-conjugally.ngrok-free.dev';

class BackendChatService {
  BackendChatService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String> chat({
    required String plantId,
    required String message,
    String? token,
  }) async {
    final uri = Uri.parse('$_chatBaseUrl/api/v1/chat/$plantId');
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
