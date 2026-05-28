import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:gossip_garden/core/config/app_config.dart';
import '../models/plant.dart';
import '../models/plant_enums.dart';
import '../models/sensors.dart';
import '../models/comfort_zones.dart';

/// Llama a POST /api/v1/plants/ para crear una planta nueva.
class PlantCreateDatasource {
  PlantCreateDatasource({
    required this.authToken,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String? authToken;
  final http.Client _httpClient;

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<Plant> createPlant({
    required String speciesId,
    required String nickname,
    String? photoStoragePath,
  }) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/v1/plants/');
    final body = <String, dynamic>{
      'species_id': speciesId,
      'nickname': nickname,
      if (photoStoragePath != null) 'photo_storage_path': photoStoragePath,
    };

    final response = await _httpClient.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor vuelve a iniciar sesión.');
    }
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode} al crear planta: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _toPlant(json);
  }

  Plant _toPlant(Map<String, dynamic> raw) {
    final plantId = (raw['plant_id'] ?? '').toString();
    final nickname = (raw['nickname'] ?? 'Mi planta').toString();
    final photo = raw['photo_url'] as String? ?? '';

    return Plant(
      id: plantId,
      name: nickname,
      species: '',
      image: photo,
      personality: PlantPersonality.playful,
      health: (raw['health_score'] as num?)?.toDouble() ?? 100.0,
      mood: PlantMood.happy,
      lastWatered: 'Hoy',
      sensors: const Sensors(
        humidity: 0,
        temperature: 0,
        light: 0,
        soilMoisture: 0,
      ),
      sensorStatus: SensorStatus.offline,
      confidence: ConfidenceLevel.low,
      actions: const [],
      insights: const [],
      comfortZones: ComfortZones(
        humidity: Range(40, 70),
        temperature: Range(18, 27),
        light: Range(250, 1100),
        soilMoisture: Range(30, 60),
      ),
    );
  }
}
