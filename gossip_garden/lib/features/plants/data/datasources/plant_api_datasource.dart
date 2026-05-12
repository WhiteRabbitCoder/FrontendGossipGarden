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
  PlantApiDatasource({http.Client? httpClient, this.authToken})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String? authToken;

  Map<String, String> get _authHeaders => {
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  @override
  Future<List<Plant>> getPlants() async {
    final plantsRaw = await _getJsonList('/api/v1/plants/');
    final speciesResponse = await _getJson('/api/v1/species');

    final speciesRaw =
        (speciesResponse['plant_species_profiles'] as List?) ??
            (speciesResponse['plant_species_profile'] as List?) ??
            const [];

    // Especies indexadas por UUID string
    final speciesById = <String, Map<String, dynamic>>{};
    for (final raw in speciesRaw) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final id = map['plant_species_id']?.toString() ?? '';
      if (id.isNotEmpty) speciesById[id] = map;
    }

    final futures = plantsRaw
        .whereType<Map>()
        .map((raw) => _toPlant(Map<String, dynamic>.from(raw), speciesById));

    return Future.wait(futures);
  }

  Future<Plant> _toPlant(
    Map<String, dynamic> plantRaw,
    Map<String, Map<String, dynamic>> speciesById,
  ) async {
    // Backend devuelve UUIDs como strings
    final plantId = (plantRaw['plant_id'] ?? '').toString();
    final speciesId = (plantRaw['species_id'] ?? '').toString();
    final speciesRaw = speciesById[speciesId] ?? const {};

    final sensorSnapshot = await _getSensorSnapshot(plantId);
    final comfortZones = _buildComfortZones(speciesRaw);
    final sensors = _buildSensors(sensorSnapshot);
    final status = _deriveSensorStatus(sensorSnapshot.latestSensorData);

    return Plant(
      id: plantId,
      name: _toString(plantRaw['nickname'], fallback: 'Planta'),
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

  // ─── HTTP helpers ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _getJson(String path) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}$path');
    final response = await _httpClient.get(uri, headers: _authHeaders);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error ${response.statusCode} consumiendo $path');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Respuesta invalida en $path');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<List<dynamic>> _getJsonList(String path) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}$path');
    final response = await _httpClient.get(uri, headers: _authHeaders);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error ${response.statusCode} consumiendo $path');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in ['plants', 'data', 'results']) {
        if (decoded[key] is List) return decoded[key] as List;
      }
    }
    return const [];
  }

  // ─── Sensor snapshot ─────────────────────────────────────────────────────────

  Future<_SensorSnapshot> _getSensorSnapshot(String plantId) async {
    if (plantId.isEmpty) return const _SensorSnapshot();

    try {
      // GET /api/v1/sensors/{plant_id}/latest — no requiere auth
      final uri = Uri.parse(
          '${AppConfig.backendBaseUrl}/api/v1/sensors/$plantId/latest');
      final response = await _httpClient.get(uri);

      if (response.statusCode == 404) return const _SensorSnapshot();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const _SensorSnapshot();
      }

      final raw = jsonDecode(response.body);
      if (raw is! Map) return const _SensorSnapshot();

      // Mapear nombres de campos del backend → nombres internos del Flutter
      final latestSensorData = <String, dynamic>{
        'temperature': raw['temperature_c'],
        'humidity': raw['humidity_pct'],
        'soil_moisture': raw['soil_moisture_pct'],
        'light': raw['light_lux'],
        'timestamp': raw['timestamp']?.toString(),
      };

      return _SensorSnapshot(
        latestSensorData: latestSensorData,
        readingsCount: 1,
      );
    } catch (_) {
      return const _SensorSnapshot();
    }
  }

  // ─── Model builders (sin cambios) ────────────────────────────────────────────

  ComfortZones _buildComfortZones(Map<String, dynamic> speciesRaw) {
    return ComfortZones(
      humidity: Range(
        _toDouble(speciesRaw['min_humidity']) ?? 40,
        _toDouble(speciesRaw['max_humidity']) ?? 70,
      ),
      temperature: Range(
        _toDouble(speciesRaw['min_temperature']) ?? 18,
        _toDouble(speciesRaw['max_temperature']) ?? 27,
      ),
      light: Range(
        _toDouble(speciesRaw['min_light']) ?? 250,
        _toDouble(speciesRaw['max_light']) ?? 1100,
      ),
      soilMoisture: Range(
        _toDouble(speciesRaw['min_soil_moisture']) ?? 30,
        _toDouble(speciesRaw['max_soil_moisture']) ?? 60,
      ),
    );
  }

  Sensors _buildSensors(_SensorSnapshot snapshot) {
    final averages = snapshot.averages;
    final latest = snapshot.latestSensorData;

    if (averages == null && latest == null) {
      return const Sensors(humidity: 0, temperature: 0, light: 0, soilMoisture: 0);
    }

    return Sensors(
      humidity: _toDouble(averages?['humidity']) ?? _toDouble(latest?['humidity']) ?? 0,
      temperature: _toDouble(averages?['temperature']) ?? _toDouble(latest?['temperature']) ?? 0,
      light: _toDouble(averages?['light']) ?? _toDouble(latest?['light']) ?? 0,
      soilMoisture: _toDouble(averages?['soil_moisture']) ?? _toDouble(latest?['soil_moisture']) ?? 0,
    );
  }

  SensorStatus _deriveSensorStatus(Map<String, dynamic>? latest) {
    if (latest == null) return SensorStatus.offline;

    final tsRaw = latest['timestamp']?.toString();
    if (tsRaw == null || tsRaw.isEmpty) return SensorStatus.degraded;

    final parsed = DateTime.tryParse(tsRaw)?.toUtc();
    if (parsed == null) return SensorStatus.degraded;

    final age = DateTime.now().toUtc().difference(parsed);
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

  PlantMood _deriveMood(Sensors sensors, ComfortZones zones, SensorStatus status) {
    if (status == SensorStatus.offline) return PlantMood.stressed;
    if (sensors.soilMoisture < zones.soilMoisture.min) return PlantMood.thirsty;
    if (sensors.temperature < zones.temperature.min) return PlantMood.cold;
    if (sensors.temperature > zones.temperature.max) return PlantMood.hot;
    final humidityOut = sensors.humidity < zones.humidity.min || sensors.humidity > zones.humidity.max;
    final lightOut = sensors.light < zones.light.min || sensors.light > zones.light.max;
    if (humidityOut || lightOut || status == SensorStatus.degraded) return PlantMood.stressed;
    return PlantMood.perfect;
  }

  double _calculateHealth(Sensors sensors, ComfortZones zones, SensorStatus status) {
    if (status == SensorStatus.offline) return 45;

    final avg = (_metricScore(sensors.soilMoisture, zones.soilMoisture.min, zones.soilMoisture.max) +
            _metricScore(sensors.temperature, zones.temperature.min, zones.temperature.max) +
            _metricScore(sensors.humidity, zones.humidity.min, zones.humidity.max) +
            _metricScore(sensors.light, zones.light.min, zones.light.max)) /
        4;

    return status == SensorStatus.degraded ? math.max(0, avg - 10) : avg;
  }

  double _metricScore(double value, double min, double max) {
    final safeMin = math.min(min, max);
    final safeMax = math.max(min, max);
    final spread = (safeMax - safeMin).clamp(1, double.infinity);
    if (value >= safeMin && value <= safeMax) return 100;
    final distance = value < safeMin ? safeMin - value : value - safeMax;
    return (100 - (distance / spread * 100)).clamp(0, 100);
  }

  String _estimateLastWatered(Sensors sensors, ComfortZones zones, SensorStatus status) {
    if (status == SensorStatus.offline) return 'Sin datos';
    if (sensors.soilMoisture >= zones.soilMoisture.max) return 'Hoy';
    final middle = (zones.soilMoisture.min + zones.soilMoisture.max) / 2;
    if (sensors.soilMoisture >= middle) return '1 dia';
    if (sensors.soilMoisture >= zones.soilMoisture.min) return '2 dias';
    return '3+ dias';
  }

  List<String> _buildInsights(
      Sensors sensors, ComfortZones zones, SensorStatus status, int readingsCount) {
    if (status == SensorStatus.offline) {
      return readingsCount > 0
          ? const ['No hay telemetria reciente. Ultimos datos desactualizados.']
          : const ['No hay telemetria historica para esta planta.'];
    }

    final readingInsight = readingsCount > 1
        ? 'Promedios calculados con $readingsCount lecturas.'
        : 'Mostrando la ultima lectura disponible.';

    final soilMsg =
        'Humedad suelo ${sensors.soilMoisture.toStringAsFixed(1)}% (ideal ${zones.soilMoisture.min.toStringAsFixed(0)}-${zones.soilMoisture.max.toStringAsFixed(0)}%).';
    final tempMsg =
        'Temperatura ${sensors.temperature.toStringAsFixed(1)} C (ideal ${zones.temperature.min.toStringAsFixed(0)}-${zones.temperature.max.toStringAsFixed(0)} C).';
    final humMsg =
        'Humedad aire ${sensors.humidity.toStringAsFixed(1)}% (ideal ${zones.humidity.min.toStringAsFixed(0)}-${zones.humidity.max.toStringAsFixed(0)}%).';

    if (status == SensorStatus.degraded) {
      return [readingInsight, 'Telemetria atrasada: ultimo registro con latencia.', soilMsg];
    }

    return [readingInsight, soilMsg, tempMsg, humMsg];
  }

  // ─── Type helpers ─────────────────────────────────────────────────────────────

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _toString(dynamic value, {required String fallback}) {
    final parsed = value?.toString();
    return (parsed == null || parsed.trim().isEmpty) ? fallback : parsed;
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
