import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gossip_garden/core/config/app_config.dart';

class BackendAuthException implements Exception {
  BackendAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackendAuthService {
  BackendAuthService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  String get _base => AppConfig.backendBaseUrl;

  /// Llama a POST /api/v1/auth/login y devuelve el JWT de Supabase.
  /// Lanza [BackendAuthException] si las credenciales son inválidas.
  Future<String> login(String email, String password) async {
    final uri = Uri.parse('$_base/api/v1/auth/login');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token == null) throw BackendAuthException('Respuesta de login inválida');
      return token;
    }
    final detail = _extractDetail(response.body);
    throw BackendAuthException(detail ?? 'Credenciales incorrectas (${response.statusCode})');
  }

  /// Llama a POST /api/v1/auth/register.
  /// Lanza [BackendAuthException] si el registro falla.
  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final uri = Uri.parse('$_base/api/v1/auth/register');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'username': username}),
    );
    if (response.statusCode == 200) return;
    final detail = _extractDetail(response.body);
    throw BackendAuthException(detail ?? 'Error al registrar (${response.statusCode})');
  }

  /// Llama a GET /api/v1/auth/google-url y devuelve la URL OAuth de Supabase.
  /// Lanza [BackendAuthException] si falla.
  Future<String> getGoogleAuthUrl({required String redirectTo}) async {
    final uri = Uri.parse('$_base/api/v1/auth/google-url')
        .replace(queryParameters: {'redirect_to': redirectTo});
    final response = await _httpClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url == null) throw BackendAuthException('URL de Google inválida');
      return url;
    }
    throw BackendAuthException('Error al obtener URL de Google (${response.statusCode})');
  }

  String? _extractDetail(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['detail']?.toString();
    } catch (_) {
      return null;
    }
  }
}
