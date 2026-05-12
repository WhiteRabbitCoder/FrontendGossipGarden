import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gossip_garden/core/config/app_config.dart';

class BackendAuthService {
  BackendAuthService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// Llama a POST /api/v1/auth/login y devuelve el JWT de Supabase, o null si falla.
  Future<String?> login(String email, String password) async {
    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/v1/auth/login');
      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['access_token'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
