import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'package:gossip_garden/core/config/app_config.dart';

import '../models/comfort_zones.dart';
import '../models/plant.dart';
import '../models/plant_action.dart';
import '../models/plant_enums.dart';
import '../models/sensors.dart';
import 'plant_datasource.dart';

class PlantApiDatasource implements PlantDatasource {
  PlantApiDatasource({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<List<Plant>> getPlants() async {
    final plantsResponse = await _getJson('/plants');
    final speciesResponse = await _getJson('/plant_species');

    final plantsRaw = (plantsResponse['plants'] as List?) ?? const [];
    final speciesRaw = (speciesResponse['plant_species_profiles'] as List?) ??
        (speciesResponse['plant_species_profile'] as List?) ??
        const [];

    final speciesById = <int, Map<String, dynamic>>{};
    for (final raw in speciesRaw) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final specieId = _toInt(map['plant_species_id']) ??
          _toInt(map['plant_specie_id']) ??
          -1;
      if (specieId > 0) {
        speciesById[specieId] = map;
      }
    }

    final futures = plantsRaw
        .whereType<Map>()
        .map((raw) => _toPlant(Map<String, dynamic>.from(raw), speciesById));

    return Future.wait(futures);
  }

  Future<Plant> _toPlant(
    Map<String, dynamic> plantRaw,
    Map<int, Map<String, dynamic>> speciesById,
  ) async {
    final plantId = _toInt(plantRaw['plant_id']) ?? 0;
    final speciesId = _toInt(plantRaw['plant_species_id']) ??
        _toInt(plantRaw['plant_specie_id']) ??
        -1;
    final speciesRaw = speciesById[speciesId] ?? const {};

    final sensorSnapshot = await _getSensorSnapshot(plantId);
    final comfortZones = _buildComfortZones(speciesRaw);
    final sensors = _buildSensors(sensorSnapshot);
    final status = _deriveSensorStatus(sensorSnapshot.latestSensorData);

    return Plant(
      id: plantId.toString(),
      name: _toString(plantRaw['name'], fallback: 'Planta #$plantId'),
      species: _toString(
        speciesRaw['specie_name'] ?? speciesRaw['species_name'],
        fallback: 'Especie desconocida',
      ),
      image: '',
      personality: _derivePersonality(speciesRaw['personality']),
      health: _calculateHealth(sensors, comfortZones, status),
      mood: _deriveMood(sensors, comfortZones, status),
      lastWatered: _estimateLastWatered(sensors, comfortZones, status),
      sensors: sensors,
      sensorStatus: status,
      confidence: _deriveConfidence(status),
      actions: const <PlantAction>[],
      insights: _buildInsights(
        sensors,
        comfortZones,
        status,
        sensorSnapshot.readingsCount,
      ),
      comfortZones: comfortZones,
    );
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}$path');
    final response = await _httpClient.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error ${response.statusCode} consumiendo $path');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Respuesta invalida en $path');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<_SensorSnapshot> _getSensorSnapshot(int plantId) async {
    if (plantId <= 0) return const _SensorSnapshot();

    try {
      final response = await _getJson('/sensor_data/$plantId');
      final latestRaw = response['sensor_data'];
      final averagesRaw = response['averages'];
      final readingsCount = _toInt(response['readings_count']) ?? 0;

      return _SensorSnapshot(
        latestSensorData:
            latestRaw is Map ? Map<String, dynamic>.from(latestRaw) : null,
        averages:
            averagesRaw is Map ? Map<String, dynamic>.from(averagesRaw) : null,
        readingsCount: readingsCount,
      );
    } catch (_) {
      return const _SensorSnapshot();
    }
  }

  ComfortZones _buildComfortZones(Map<String, dynamic> speciesRaw) {
    final humidityMin = _toDouble(speciesRaw['min_humidity']) ?? 40;
    final humidityMax = _toDouble(speciesRaw['max_humidity']) ?? 70;

    final temperatureMin = _toDouble(speciesRaw['min_temperature']) ?? 18;
    final temperatureMax = _toDouble(speciesRaw['max_temperature']) ?? 27;

    final soilMin = _toDouble(speciesRaw['min_soil_moisture']) ?? 30;
    final soilMax = _toDouble(speciesRaw['max_soil_moisture']) ?? 60;

    final lightMin = _toDouble(speciesRaw['min_light']) ?? 250;
    final lightMax = _toDouble(speciesRaw['max_light']) ?? 1100;

    return ComfortZones(
      humidity: Range(humidityMin, humidityMax),
      temperature: Range(temperatureMin, temperatureMax),
      light: Range(lightMin, lightMax),
      soilMoisture: Range(soilMin, soilMax),
    );
  }

  Sensors _buildSensors(_SensorSnapshot snapshot) {
    final averages = snapshot.averages;
    final latestSensorRaw = snapshot.latestSensorData;

    if (averages == null && latestSensorRaw == null) {
      return const Sensors(
        humidity: 0,
        temperature: 0,
        light: 0,
        soilMoisture: 0,
      );
    }

    final humidity = _toDouble(averages?['humidity']) ??
        _toDouble(latestSensorRaw?['humidity']) ??
        0;
    final temperature = _toDouble(averages?['temperature']) ??
        _toDouble(latestSensorRaw?['temperature']) ??
        0;
    final light = _toDouble(averages?['light']) ??
        _toDouble(latestSensorRaw?['light']) ??
        0;
    final soilMoisture = _toDouble(averages?['soil_moisture']) ??
        _toDouble(latestSensorRaw?['soil_moisture']) ??
        0;

    return Sensors(
      humidity: humidity,
      temperature: temperature,
      light: light,
      soilMoisture: soilMoisture,
    );
  }

  SensorStatus _deriveSensorStatus(Map<String, dynamic>? latestSensorRaw) {
    if (latestSensorRaw == null) {
      return SensorStatus.offline;
    }

    final timestampRaw = latestSensorRaw['timestamp']?.toString();
    if (timestampRaw == null || timestampRaw.isEmpty) {
      return SensorStatus.degraded;
    }

    final parsed = DateTime.tryParse(timestampRaw)?.toUtc();
    if (parsed == null) {
      return SensorStatus.degraded;
    }

    final age = DateTime.now().toUtc().difference(parsed);
    if (age.inMinutes <= 20) {
      return SensorStatus.online;
    }

    if (age.inHours <= 3) {
      return SensorStatus.degraded;
    }

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

  PlantPersonality _derivePersonality(dynamic rawPersonality) {
    final text = rawPersonality?.toString().toLowerCase() ?? '';

    if (text.contains('fuerte') ||
        text.contains('resistente') ||
        text.contains('sabia') ||
        text.contains('serena')) {
      return PlantPersonality.wise;
    }

    if (text.contains('dram') ||
        text.contains('intensa') ||
        text.contains('ans')) {
      return PlantPersonality.dramatic;
    }

    return PlantPersonality.playful;
  }

  PlantMood _deriveMood(
    Sensors sensors,
    ComfortZones zones,
    SensorStatus status,
  ) {
    if (status == SensorStatus.offline) {
      return PlantMood.stressed;
    }

    if (sensors.soilMoisture < zones.soilMoisture.min) {
      return PlantMood.thirsty;
    }

    if (sensors.temperature < zones.temperature.min) {
      return PlantMood.cold;
    }

    if (sensors.temperature > zones.temperature.max) {
      return PlantMood.hot;
    }

    final humidityOut = sensors.humidity < zones.humidity.min ||
        sensors.humidity > zones.humidity.max;
    final lightOut =
        sensors.light < zones.light.min || sensors.light > zones.light.max;

    if (humidityOut || lightOut || status == SensorStatus.degraded) {
      return PlantMood.stressed;
    }

    return PlantMood.perfect;
  }

  double _calculateHealth(
    Sensors sensors,
    ComfortZones zones,
    SensorStatus status,
  ) {
    if (status == SensorStatus.offline) {
      return 45;
    }

    final soil = _metricScore(
      value: sensors.soilMoisture,
      min: zones.soilMoisture.min,
      max: zones.soilMoisture.max,
    );
    final temperature = _metricScore(
      value: sensors.temperature,
      min: zones.temperature.min,
      max: zones.temperature.max,
    );
    final humidity = _metricScore(
      value: sensors.humidity,
      min: zones.humidity.min,
      max: zones.humidity.max,
    );
    final light = _metricScore(
      value: sensors.light,
      min: zones.light.min,
      max: zones.light.max,
    );

    final average = (soil + temperature + humidity + light) / 4;

    if (status == SensorStatus.degraded) {
      return math.max(0, average - 10);
    }

    return average;
  }

  double _metricScore({
    required double value,
    required double min,
    required double max,
  }) {
    final safeMin = math.min(min, max);
    final safeMax = math.max(min, max);
    final range = safeMax - safeMin;
    final spread = range <= 0 ? 1 : range;

    if (value >= safeMin && value <= safeMax) {
      return 100;
    }

    final distance = value < safeMin ? safeMin - value : value - safeMax;
    final score = 100 - ((distance / spread) * 100);

    return score.clamp(0, 100);
  }

  String _estimateLastWatered(
    Sensors sensors,
    ComfortZones zones,
    SensorStatus status,
  ) {
    if (status == SensorStatus.offline) {
      return 'Sin datos';
    }

    if (sensors.soilMoisture >= zones.soilMoisture.max) {
      return 'Hoy';
    }

    final middle = (zones.soilMoisture.min + zones.soilMoisture.max) / 2;
    if (sensors.soilMoisture >= middle) {
      return '1 dia';
    }

    if (sensors.soilMoisture >= zones.soilMoisture.min) {
      return '2 dias';
    }

    return '3+ dias';
  }

  List<String> _buildInsights(
    Sensors sensors,
    ComfortZones zones,
    SensorStatus status,
    int readingsCount,
  ) {
    if (status == SensorStatus.offline) {
      if (readingsCount > 0) {
        return const [
          'No hay telemetria reciente. Ultimos datos desactualizados.',
        ];
      }

      return const ['No hay telemetria historica para esta planta.'];
    }

    final humidityMessage =
        'Humedad aire ${sensors.humidity.toStringAsFixed(1)}% '
        '(ideal ${zones.humidity.min.toStringAsFixed(0)}-${zones.humidity.max.toStringAsFixed(0)}%).';
    final temperatureMessage =
        'Temperatura ${sensors.temperature.toStringAsFixed(1)} C '
        '(ideal ${zones.temperature.min.toStringAsFixed(0)}-${zones.temperature.max.toStringAsFixed(0)} C).';
    final soilMessage =
        'Humedad suelo ${sensors.soilMoisture.toStringAsFixed(1)}% '
        '(ideal ${zones.soilMoisture.min.toStringAsFixed(0)}-${zones.soilMoisture.max.toStringAsFixed(0)}%).';

    final readingInsight = readingsCount > 1
        ? 'Promedios calculados con $readingsCount lecturas.'
        : 'Mostrando la ultima lectura disponible.';

    if (status == SensorStatus.degraded) {
      return [
        readingInsight,
        'Telemetria atrasada: ultimo registro con latencia.',
        soilMessage,
      ];
    }

    return [readingInsight, soilMessage, temperatureMessage, humidityMessage];
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);

    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);

    return null;
  }

  String _toString(dynamic value, {required String fallback}) {
    final parsed = value?.toString();
    if (parsed == null || parsed.trim().isEmpty) {
      return fallback;
    }

    return parsed;
  }
}

class _SensorSnapshot {
  final Map<String, dynamic>? latestSensorData;
  final Map<String, dynamic>? averages;
  final int readingsCount;

  const _SensorSnapshot({
    this.latestSensorData,
    this.averages,
    this.readingsCount = 0,
  });
}
