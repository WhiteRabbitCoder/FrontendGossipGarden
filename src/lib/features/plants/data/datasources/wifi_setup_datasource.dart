import 'dart:convert';
import 'package:http/http.dart' as http;

class WifiSetupDatasource {
  final http.Client _client;
  final String baseUrl;

  WifiSetupDatasource({
    http.Client? client,
    this.baseUrl = 'http://192.168.4.1',
  }) : _client = client ?? http.Client();

  /// Escanea las redes Wi-Fi al alcance del ESP32.
  Future<List<Map<String, dynamic>>> scanNetworks() async {
    try {
      final uri = Uri.parse('$baseUrl/wifi/scan');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded.whereType<Map>());
        } else if (decoded is Map && decoded['networks'] is List) {
          return List<Map<String, dynamic>>.from(
            (decoded['networks'] as List).whereType<Map>(),
          );
        }
      }
      return const [];
    } catch (e) {
      // Retorna una lista vacía o propaga el error según la política de reintentos
      return const [];
    }
  }

  /// Envía las credenciales SSID y password al ESP32.
  /// Llama al endpoint POST /wifi/setup o POST /configure.
  Future<bool> configureDevice({
    required String ssid,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/wifi/setup');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ssid': ssid,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Inicia o verifica la vinculación con el dispositivo IoT.
  /// Llama al endpoint GET /pair o GET /status.
  Future<bool> pairDevice() async {
    try {
      final uri = Uri.parse('$baseUrl/pair');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    } 
  }
}
