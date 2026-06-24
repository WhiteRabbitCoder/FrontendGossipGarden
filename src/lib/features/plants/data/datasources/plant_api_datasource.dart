import 'package:gossip_garden/core/services/api_client.dart';

import '../models/comfort_zones.dart';
import '../models/plant.dart';
import '../models/plant_action.dart';
import '../models/plant_enums.dart';
import '../models/sensors.dart';
import '../models/plant_dto.dart';
import '../models/sensor_dto.dart';
import 'plant_datasource.dart';

class PlantApiDatasource implements PlantDatasource {
  PlantApiDatasource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<Plant>> getPlants() async {
    try {
      final response = await _apiClient.dio.get('/plants/');
      
      final List<dynamic> plantsRaw = response.data;
      final List<PlantResponse> plantResponses = plantsRaw
          .map((e) => PlantResponse.fromJson(e as Map<String, dynamic>))
          .toList();

      final futures = plantResponses.map((pr) => _toPlant(pr));
      return Future.wait(futures);
    } catch (e) {
      return [];
    }
  }

  Future<Plant> _toPlant(PlantResponse response) async {
    final sensorResponse = await _getSensorSnapshot(response.plantId);
    
    // As the new backend doesn't provide min/max ranges directly on the /plants/ endpoint,
    // we use fallback comfort zones or could fetch the profile.
    final comfortZones = ComfortZones(
      humidity: Range(40, 70),
      temperature: Range(18, 27),
      light: Range(250, 1100),
      soilMoisture: Range(30, 60),
    );

    final sensors = _buildSensors(sensorResponse);
    final status = _deriveSensorStatus(sensorResponse);

    String resolvedImage = response.photoUrl ?? '';
    if (resolvedImage.contains('firebasestorage.googleapis.com') && !resolvedImage.contains('token=')) {
      try {
        final uri = Uri.parse(resolvedImage);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 5 && pathSegments[0] == 'v0' && pathSegments[1] == 'b' && pathSegments[3] == 'o') {
          final bucket = pathSegments[2];
          final encodedPath = pathSegments[4];
          final decodedPath = Uri.decodeComponent(encodedPath);
          resolvedImage = 'https://storage.googleapis.com/$bucket/$decodedPath';
        }
      } catch (_) {}
    }

    if (resolvedImage.isEmpty &&
        response.photoStoragePath != null &&
        response.photoStoragePath!.isNotEmpty) {
      final bucket = const String.fromEnvironment('FIREBASE_STORAGE_BUCKET').isNotEmpty
          ? const String.fromEnvironment('FIREBASE_STORAGE_BUCKET')
          : 'gossipgarden-e2879.firebasestorage.app';
      resolvedImage =
          'https://storage.googleapis.com/$bucket/${response.photoStoragePath}';
    }

    return Plant(
      id: response.plantId,
      name: response.nickname,
      species: response.commonName ?? response.scientificName ?? 'Especie desconocida',
      image: resolvedImage,
      personality: PlantPersonality.playful, // Now needs to be derived from profile if needed
      health: response.healthScore,
      mood: _deriveMood(status),
      lastWatered: _estimateLastWatered(sensors, comfortZones, status),
      sensors: sensors,
      sensorStatus: status,
      confidence: _deriveConfidence(status),
      actions: const <PlantAction>[],
      insights: [
        if (response.specificCareTips != null) 'Tips de IA disponibles'
      ],
      comfortZones: comfortZones,
    );
  }

  Future<SensorDataResponse?> _getSensorSnapshot(String plantId) async {
    try {
      final response = await _apiClient.dio.get('/plants/$plantId/sensor-data/latest');
      return SensorDataResponse.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Sensors _buildSensors(SensorDataResponse? sensorData) {
    if (sensorData == null) {
      return const Sensors(humidity: 0, temperature: 0, light: 0, soilMoisture: 0);
    }
    return Sensors(
      humidity: sensorData.humidityPct,
      temperature: sensorData.temperatureC,
      light: sensorData.lightLux,
      soilMoisture: sensorData.soilMoisturePct,
    );
  }

  SensorStatus _deriveSensorStatus(SensorDataResponse? latest) {
    if (latest == null) return SensorStatus.offline;

    final age = DateTime.now().toUtc().difference(latest.timestamp.toUtc());
    if (age.inMinutes <= 20) return SensorStatus.online;
    if (age.inHours <= 3) return SensorStatus.degraded;
    return SensorStatus.offline;
  }

  ConfidenceLevel _deriveConfidence(SensorStatus status) {
    switch (status) {
      case SensorStatus.online:
        return ConfidenceLevel.high;
      case SensorStatus.degraded:
        return ConfidenceLevel.medium;
      case SensorStatus.offline:
        return ConfidenceLevel.low;
    }
  }

  PlantMood _deriveMood(SensorStatus status) {
    if (status == SensorStatus.offline || status == SensorStatus.degraded) return PlantMood.stressed;
    return PlantMood.happy; // simplified for now
  }

  String _estimateLastWatered(Sensors sensors, ComfortZones zones, SensorStatus status) {
    if (status == SensorStatus.offline) return 'Sin datos';
    if (sensors.soilMoisture >= zones.soilMoisture.max) return 'Hoy';
    final middle = (zones.soilMoisture.min + zones.soilMoisture.max) / 2;
    if (sensors.soilMoisture >= middle) return '1 día';
    if (sensors.soilMoisture >= zones.soilMoisture.min) return '2 días';
    return '3+ días';
  }
}
