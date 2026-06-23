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

    return Plant(
      id: response.plantId,
      name: response.nickname,
      species: response.commonName ?? response.scientificName ?? 'Especie desconocida',
      image: response.photoUrl ?? '',
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
