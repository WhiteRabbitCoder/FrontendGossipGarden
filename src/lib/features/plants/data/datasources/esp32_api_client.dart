import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../presentation/providers/sensor_setup_providers.dart';

class Esp32ApiClient {
  final String baseUrl;
  final http.Client _client;

  Esp32ApiClient({this.baseUrl = 'http://192.168.4.1', http.Client? client})
      : _client = client ?? http.Client();

  int _rssiToSignalBars(int rssi) {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    return 1;
  }

  Future<List<WifiNetworkOption>> getWifiNetworks() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/wifi/networks'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          final rssi = (json['rssi'] as num?)?.toInt() ?? -100;
          final security = json['security']?.toString().toLowerCase() ?? '';
          final isSecured = security.isNotEmpty && security != 'open' && security != 'none';
          
          return WifiNetworkOption(
            ssid: json['ssid'] as String? ?? 'Unknown',
            signal: _rssiToSignalBars(rssi),
            secured: isSecured,
          );
        }).toList();
      } else {
        throw Exception('Error del sensor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('No se pudo conectar al sensor. ¿Estás conectado a la red WiFi GossipGarden_Setup?');
    }
  }

  Future<bool> connectWifi(String ssid, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/wifi/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ssid': ssid,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      // Si ocurre un error de red o timeout, fallamos explícitamente.
      // El contrato de la API dice que el ESP32 responde 200 OK antes de apagar el AP (con 1 segundo de retraso).
      return false;
    }
  }

  Future<String?> getSystemInfo() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/system/info')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['mac_address'] as String?;
      }
      return null;
    } catch (e) {
      // Fallback: Si el sensor aún no tiene este endpoint, ignoramos el error.
      return null;
    }
  }
}
