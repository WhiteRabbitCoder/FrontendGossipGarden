import 'package:flutter_test/flutter_test.dart';

import 'package:gossip_garden/features/plants/data/models/sensors.dart';

void main() {
  group('Sensors.fromJson', () {
    test('parsea todos los campos', () {
      final sensors = Sensors.fromJson({
        'humidity': 55.2,
        'temperature': 22.5,
        'light': 850.0,
        'soilMoisture': 45.0,
      });

      expect(sensors.humidity, 55.2);
      expect(sensors.temperature, 22.5);
      expect(sensors.light, 850.0);
      expect(sensors.soilMoisture, 45.0);
    });

    test('convierte int a double', () {
      final sensors = Sensors.fromJson({
        'humidity': 55,
        'temperature': 22,
        'light': 850,
        'soilMoisture': 45,
      });

      expect(sensors.humidity, isA<double>());
      expect(sensors.humidity, 55.0);
    });

    test('usa 0 cuando campos ausentes', () {
      final sensors = Sensors.fromJson({});

      expect(sensors.humidity, 0.0);
      expect(sensors.temperature, 0.0);
      expect(sensors.light, 0.0);
      expect(sensors.soilMoisture, 0.0);
    });

    test('usa 0 cuando valores son null', () {
      final sensors = Sensors.fromJson({
        'humidity': null,
        'temperature': null,
        'light': null,
        'soilMoisture': null,
      });

      expect(sensors.humidity, 0.0);
    });
  });

  group('Sensors constructor', () {
    test('const constructor funciona', () {
      const sensors = Sensors(
        humidity: 60.0,
        temperature: 24.0,
        light: 1000.0,
        soilMoisture: 50.0,
      );

      expect(sensors.humidity, 60.0);
      expect(sensors.temperature, 24.0);
    });
  });
}
