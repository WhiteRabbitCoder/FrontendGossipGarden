import 'package:flutter_test/flutter_test.dart';

import 'package:gossip_garden/features/plants/data/models/comfort_zones.dart';

void main() {
  group('Range', () {
    test('constructor directo', () {
      const range = Range(10.0, 30.0);
      expect(range.min, 10.0);
      expect(range.max, 30.0);
    });

    group('fromList', () {
      test('parsea lista de dos elementos', () {
        final range = Range.fromList([18.0, 27.0]);
        expect(range.min, 18.0);
        expect(range.max, 27.0);
      });

      test('convierte int a double', () {
        final range = Range.fromList([18, 27]);
        expect(range.min, isA<double>());
        expect(range.min, 18.0);
      });

      test('devuelve Range(0,0) para lista null', () {
        final range = Range.fromList(null);
        expect(range.min, 0.0);
        expect(range.max, 0.0);
      });

      test('devuelve Range(0,0) para lista con menos de 2 elementos', () {
        final range = Range.fromList([10.0]);
        expect(range.min, 0.0);
        expect(range.max, 0.0);
      });

      test('devuelve Range(0,0) para lista vacía', () {
        final range = Range.fromList([]);
        expect(range.min, 0.0);
        expect(range.max, 0.0);
      });
    });
  });

  group('ComfortZones', () {
    test('constructor directo', () {
      final zones = ComfortZones(
        humidity: Range(40, 70),
        temperature: Range(18, 27),
        light: Range(250, 1100),
        soilMoisture: Range(30, 60),
      );

      expect(zones.humidity.min, 40);
      expect(zones.temperature.max, 27);
    });

    group('fromJson', () {
      test('parsea listas de rangos', () {
        final zones = ComfortZones.fromJson({
          'humidity': [40.0, 70.0],
          'temperature': [18.0, 27.0],
          'light': [250.0, 1100.0],
          'soilMoisture': [30.0, 60.0],
        });

        expect(zones.humidity.min, 40.0);
        expect(zones.humidity.max, 70.0);
        expect(zones.temperature.min, 18.0);
        expect(zones.temperature.max, 27.0);
        expect(zones.light.min, 250.0);
        expect(zones.light.max, 1100.0);
        expect(zones.soilMoisture.min, 30.0);
        expect(zones.soilMoisture.max, 60.0);
      });

      test('usa Range(0,0) para campos ausentes', () {
        final zones = ComfortZones.fromJson({});

        expect(zones.humidity.min, 0.0);
        expect(zones.humidity.max, 0.0);
        expect(zones.temperature.min, 0.0);
      });
    });
  });
}
