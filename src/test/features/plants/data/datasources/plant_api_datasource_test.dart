import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gossip_garden/features/plants/data/datasources/plant_api_datasource.dart';
import 'package:gossip_garden/features/plants/data/models/plant_enums.dart';

import '../../../../helpers/fixture_loader.dart';

// Reloj fijo para tests deterministas de _deriveSensorStatus.
final _fixedNow = DateTime.utc(2024, 1, 15, 12, 0, 0);
DateTime _fixedClock() => _fixedNow;

String _onlineTs() =>
    _fixedNow.subtract(const Duration(minutes: 5)).toIso8601String();
String _degradedTs() =>
    _fixedNow.subtract(const Duration(hours: 1)).toIso8601String();
String _offlineTs() =>
    _fixedNow.subtract(const Duration(hours: 5)).toIso8601String();

PlantApiDatasource _buildDatasource(MockClient client) =>
    PlantApiDatasource(httpClient: client, authToken: 'test_jwt', now: _fixedClock);

http.Response _jsonResponse(String body, [int status = 200]) =>
    http.Response(body, status, headers: {'content-type': 'application/json'});

void main() {
  group('PlantApiDatasource.getPlants', () {
    test('devuelve lista de plantas al recibir 200', () async {
      final client = MockClient((req) async {
        if (req.url.path == '/api/v1/plants/') {
          return _jsonResponse(loadFixture('plants_response.json'));
        }
        // sensor-data/latest → sin datos (planta sin sensor)
        return _jsonResponse('{}', 404);
      });

      final datasource = _buildDatasource(client);
      final plants = await datasource.getPlants();

      expect(plants, hasLength(2));
      expect(plants.first.id, 'abc123-plant-uuid');
      expect(plants.first.name, 'Mi Monstera');
    });

    test('incluye bearer token en el header', () async {
      String? capturedAuth;
      final client = MockClient((req) async {
        capturedAuth = req.headers['Authorization'];
        if (req.url.path == '/api/v1/plants/') {
          return _jsonResponse('[]');
        }
        return _jsonResponse('{}', 404);
      });

      final datasource = _buildDatasource(client);
      await datasource.getPlants();

      expect(capturedAuth, 'Bearer test_jwt');
    });

    test('lanza UnauthorizedException con 401', () async {
      final client = MockClient(
        (_) async => _jsonResponse('{"detail": "Unauthorized"}', 401),
      );
      final datasource = _buildDatasource(client);

      expect(datasource.getPlants(), throwsA(isA<UnauthorizedException>()));
    });

    test('lanza Exception genérica con 500', () async {
      final client = MockClient(
        (_) async => _jsonResponse('{"error": "server error"}', 500),
      );
      final datasource = _buildDatasource(client);

      expect(datasource.getPlants(), throwsException);
    });

    test('devuelve lista vacía si el JSON no es una lista', () async {
      final client = MockClient((req) async {
        if (req.url.path == '/api/v1/plants/') {
          return _jsonResponse('{"message": "no plants"}');
        }
        return _jsonResponse('{}', 404);
      });
      final datasource = _buildDatasource(client);
      final plants = await datasource.getPlants();

      expect(plants, isEmpty);
    });

    test('extrae lista de clave "plants" cuando el JSON es un map', () async {
      final client = MockClient((req) async {
        if (req.url.path == '/api/v1/plants/') {
          return _jsonResponse(jsonEncode({
            'plants': [
              {'plant_id': 'p1', 'nickname': 'Planta Uno'},
            ],
          }));
        }
        return _jsonResponse('{}', 404);
      });
      final datasource = _buildDatasource(client);
      final plants = await datasource.getPlants();

      expect(plants, hasLength(1));
    });
  });

  group('PlantApiDatasource.getSensorSnapshot', () {
    test('mapea campos del backend a nombres internos', () async {
      final body = jsonEncode({
        'temperature_c': 22.5,
        'humidity_pct': 55.2,
        'soil_moisture_pct': 45.0,
        'light_lux': 850.0,
        'health_score': 98.5,
        'timestamp': _onlineTs(),
      });
      final client = MockClient((_) async => _jsonResponse(body));
      final datasource = _buildDatasource(client);

      final snapshot = await datasource.getSensorSnapshot('plant-uuid');

      expect(snapshot.latestSensorData?['temperature'], 22.5);
      expect(snapshot.latestSensorData?['humidity'], 55.2);
      expect(snapshot.latestSensorData?['soil_moisture'], 45.0);
      expect(snapshot.latestSensorData?['light'], 850.0);
    });

    test('devuelve SensorSnapshot vacío con 404', () async {
      final client = MockClient((_) async => _jsonResponse('{}', 404));
      final datasource = _buildDatasource(client);

      final snapshot = await datasource.getSensorSnapshot('plant-uuid');

      expect(snapshot.latestSensorData, isNull);
      expect(snapshot.readingsCount, 0);
    });

    test('devuelve SensorSnapshot vacío con plantId vacío', () async {
      final client = MockClient((_) async => _jsonResponse('{}'));
      final datasource = _buildDatasource(client);

      final snapshot = await datasource.getSensorSnapshot('');

      expect(snapshot.latestSensorData, isNull);
    });

    test('devuelve SensorSnapshot vacío si la respuesta lanza error', () async {
      final client = MockClient((_) async => throw Exception('network error'));
      final datasource = _buildDatasource(client);

      final snapshot = await datasource.getSensorSnapshot('plant-uuid');

      expect(snapshot.latestSensorData, isNull);
    });
  });

  group('Business logic — _deriveSensorStatus (vía getPlants)', () {
    test('online cuando timestamp tiene menos de 20 min de antigüedad', () async {
      final sensorBody = _buildSensorBody(timestamp: _onlineTs());
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.sensorStatus, SensorStatus.online);
    });

    test('degraded cuando timestamp tiene 1h de antigüedad', () async {
      final sensorBody = _buildSensorBody(timestamp: _degradedTs());
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.sensorStatus, SensorStatus.degraded);
    });

    test('offline cuando timestamp tiene más de 3h de antigüedad', () async {
      final sensorBody = _buildSensorBody(timestamp: _offlineTs());
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.sensorStatus, SensorStatus.offline);
    });

    test('offline cuando no hay sensor data', () async {
      final plants = await _runGetPlantsWithSensor('{}', statusCode: 404);
      expect(plants.first.sensorStatus, SensorStatus.offline);
    });

    test('degraded cuando timestamp está presente pero no parseable', () async {
      final sensorBody = _buildSensorBody(timestamp: 'not-a-date');
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.sensorStatus, SensorStatus.degraded);
    });
  });

  group('Business logic — _deriveMood (vía getPlants)', () {
    // Zonas por defecto: temp 18–27, soil 30–60, humidity 40–70, light 250–1100

    test('stressed cuando sensor offline', () async {
      final plants = await _runGetPlantsWithSensor('{}', statusCode: 404);
      expect(plants.first.mood, PlantMood.stressed);
    });

    test('thirsty cuando soil_moisture < min (30)', () async {
      final sensorBody = _buildSensorBody(
        soil: 20.0,
        timestamp: _onlineTs(),
      );
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.mood, PlantMood.thirsty);
    });

    test('cold cuando temperature < min (18)', () async {
      final sensorBody = _buildSensorBody(
        temp: 10.0,
        soil: 45.0,
        timestamp: _onlineTs(),
      );
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.mood, PlantMood.cold);
    });

    test('hot cuando temperature > max (27)', () async {
      final sensorBody = _buildSensorBody(
        temp: 35.0,
        soil: 45.0,
        timestamp: _onlineTs(),
      );
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.mood, PlantMood.hot);
    });

    test('perfect cuando todos los sensores están en rango', () async {
      final sensorBody = _buildSensorBody(
        temp: 22.0,
        humidity: 55.0,
        soil: 45.0,
        light: 600.0,
        timestamp: _onlineTs(),
      );
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.mood, PlantMood.perfect);
    });

    test('stressed cuando humidity fuera de rango', () async {
      final sensorBody = _buildSensorBody(
        temp: 22.0,
        humidity: 80.0, // > max 70
        soil: 45.0,
        light: 600.0,
        timestamp: _onlineTs(),
      );
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.mood, PlantMood.stressed);
    });
  });

  group('Business logic — _calculateHealth (vía getPlants)', () {
    test('health 45 cuando sensor offline', () async {
      final plants = await _runGetPlantsWithSensor('{}', statusCode: 404);
      expect(plants.first.health, closeTo(45.0, 0.1));
    });

    test('health 100 cuando todos los sensores en rango', () async {
      final sensorBody = _buildSensorBody(
        temp: 22.0,
        humidity: 55.0,
        soil: 45.0,
        light: 600.0,
        timestamp: _onlineTs(),
      );
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.health, closeTo(100.0, 0.1));
    });

    test('health < 100 cuando sensor degraded (descuento de 10 puntos)', () async {
      final sensorBody = _buildSensorBody(
        temp: 22.0,
        humidity: 55.0,
        soil: 45.0,
        light: 600.0,
        timestamp: _degradedTs(),
      );
      final plants = await _runGetPlantsWithSensor(sensorBody);
      // Con degraded se aplica max(0, avg - 10); todos en rango → 100 - 10 = 90
      expect(plants.first.health, closeTo(90.0, 0.1));
    });
  });

  group('Business logic — _estimateLastWatered (vía getPlants)', () {
    // Comfort zone soilMoisture: min=30, max=60, middle=45

    test('"Hoy" cuando soilMoisture >= max (60)', () async {
      final sensorBody = _buildSensorBody(soil: 65.0, timestamp: _onlineTs());
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.lastWatered, 'Hoy');
    });

    test('"Sin datos" cuando sensor offline', () async {
      final plants = await _runGetPlantsWithSensor('{}', statusCode: 404);
      expect(plants.first.lastWatered, 'Sin datos');
    });

    test('"1 dia" cuando soilMoisture entre middle y max', () async {
      final sensorBody = _buildSensorBody(soil: 50.0, timestamp: _onlineTs());
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.lastWatered, '1 dia');
    });

    test('"2 dias" cuando soilMoisture entre min y middle', () async {
      final sensorBody = _buildSensorBody(soil: 35.0, timestamp: _onlineTs());
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.lastWatered, '2 dias');
    });

    test('"3+ dias" cuando soilMoisture < min (30)', () async {
      final sensorBody = _buildSensorBody(soil: 20.0, timestamp: _onlineTs());
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.lastWatered, '3+ dias');
    });
  });

  group('Business logic — _deriveConfidence', () {
    test('high con sensor online', () async {
      final sensorBody = _buildSensorBody(timestamp: _onlineTs());
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.confidence, ConfidenceLevel.high);
    });

    test('medium con sensor degraded', () async {
      final sensorBody = _buildSensorBody(timestamp: _degradedTs());
      final plants = await _runGetPlantsWithSensor(sensorBody);
      expect(plants.first.confidence, ConfidenceLevel.medium);
    });

    test('low con sensor offline', () async {
      final plants = await _runGetPlantsWithSensor('{}', statusCode: 404);
      expect(plants.first.confidence, ConfidenceLevel.low);
    });
  });
}

// ─── Helpers internos ────────────────────────────────────────────────────────

String _buildSensorBody({
  double temp = 22.5,
  double humidity = 55.0,
  double soil = 45.0,
  double light = 600.0,
  String? timestamp,
}) {
  return jsonEncode({
    'temperature_c': temp,
    'humidity_pct': humidity,
    'soil_moisture_pct': soil,
    'light_lux': light,
    'health_score': 95.0,
    'timestamp': timestamp ?? _onlineTs(),
  });
}

Future<List<dynamic>> _runGetPlantsWithSensor(
  String sensorBody, {
  int statusCode = 200,
}) async {
  final plantsBody = jsonEncode([
    {'plant_id': 'p1', 'nickname': 'Planta Test'},
  ]);

  final client = MockClient((req) async {
    if (req.url.path == '/api/v1/plants/') {
      return _jsonResponse(plantsBody);
    }
    if (req.url.path.contains('/sensor-data/latest')) {
      return _jsonResponse(sensorBody, statusCode);
    }
    return _jsonResponse('{}', 404);
  });

  final datasource = _buildDatasource(client);
  return datasource.getPlants();
}
