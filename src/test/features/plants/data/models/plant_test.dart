import 'package:flutter_test/flutter_test.dart';

import 'package:gossip_garden/features/plants/data/models/plant.dart';
import 'package:gossip_garden/features/plants/data/models/plant_enums.dart';
import 'package:gossip_garden/features/plants/data/models/sensors.dart';
import 'package:gossip_garden/features/plants/data/models/comfort_zones.dart';

void main() {
  group('Plant.fromJson', () {
    test('parsea planta completa', () {
      final json = _fullPlantJson();
      final plant = Plant.fromJson(json);

      expect(plant.id, 'plant-uuid-001');
      expect(plant.name, 'Mi Monstera');
      expect(plant.species, 'Monstera deliciosa');
      expect(plant.image, 'https://example.com/monstera.jpg');
      expect(plant.health, 85.0);
      expect(plant.lastWatered, 'Hoy');
      expect(plant.personality, PlantPersonality.playful);
      expect(plant.mood, PlantMood.happy);
      expect(plant.sensorStatus, SensorStatus.online);
      expect(plant.confidence, ConfidenceLevel.high);
      expect(plant.insights, hasLength(2));
    });

    test('usa defaults seguros para campos ausentes', () {
      final plant = Plant.fromJson({});

      expect(plant.id, '');
      expect(plant.name, 'Sin nombre');
      expect(plant.species, '');
      expect(plant.image, '');
      expect(plant.health, 0.0);
      expect(plant.lastWatered, '');
      expect(plant.personality, PlantPersonality.playful);
      expect(plant.mood, PlantMood.happy);
      expect(plant.sensorStatus, SensorStatus.offline);
      expect(plant.confidence, ConfidenceLevel.low);
      expect(plant.insights, isEmpty);
      expect(plant.actions, isEmpty);
    });

    test('parsea enums de forma insensible a mayúsculas', () {
      final plant = Plant.fromJson({
        'personality': 'WISE',
        'mood': 'THIRSTY',
        'sensorStatus': 'DEGRADED',
        'confidence': 'MEDIUM',
      });

      expect(plant.personality, PlantPersonality.wise);
      expect(plant.mood, PlantMood.thirsty);
      expect(plant.sensorStatus, SensorStatus.degraded);
      expect(plant.confidence, ConfidenceLevel.medium);
    });

    test('usa fallback para enum desconocido', () {
      final plant = Plant.fromJson({
        'personality': 'unknown_value',
        'mood': 'whatever',
      });

      expect(plant.personality, PlantPersonality.playful);
      expect(plant.mood, PlantMood.happy);
    });

    test('parsea sensors y comfortZones anidados', () {
      final plant = Plant.fromJson({
        'sensors': {
          'humidity': 55.0,
          'temperature': 22.5,
          'light': 800.0,
          'soilMoisture': 45.0,
        },
        'comfortZones': {
          'humidity': [40.0, 70.0],
          'temperature': [18.0, 27.0],
          'light': [250.0, 1100.0],
          'soilMoisture': [30.0, 60.0],
        },
      });

      expect(plant.sensors.humidity, 55.0);
      expect(plant.comfortZones.temperature.min, 18.0);
    });
  });

  group('Plant constructor', () {
    test('crea planta con const constructor', () {
      const plant = Plant(
        id: 'id1',
        name: 'Planta Test',
        species: 'Especie test',
        image: '',
        personality: PlantPersonality.wise,
        health: 90.0,
        mood: PlantMood.perfect,
        lastWatered: 'Hoy',
        sensors: Sensors(humidity: 0, temperature: 0, light: 0, soilMoisture: 0),
        sensorStatus: SensorStatus.offline,
        confidence: ConfidenceLevel.low,
        actions: [],
        insights: [],
        comfortZones: ComfortZones(
          humidity: Range(40, 70),
          temperature: Range(18, 27),
          light: Range(250, 1100),
          soilMoisture: Range(30, 60),
        ),
      );

      expect(plant.id, 'id1');
      expect(plant.personality, PlantPersonality.wise);
      expect(plant.health, 90.0);
    });
  });
}

Map<String, dynamic> _fullPlantJson() => {
      'id': 'plant-uuid-001',
      'name': 'Mi Monstera',
      'species': 'Monstera deliciosa',
      'image': 'https://example.com/monstera.jpg',
      'health': 85.0,
      'lastWatered': 'Hoy',
      'personality': 'playful',
      'mood': 'happy',
      'sensorStatus': 'online',
      'confidence': 'high',
      'insights': ['Riego normal.', 'Temperatura ideal.'],
      'actions': [],
      'sensors': {
        'humidity': 55.0,
        'temperature': 22.5,
        'light': 800.0,
        'soilMoisture': 45.0,
      },
      'comfortZones': {
        'humidity': [40.0, 70.0],
        'temperature': [18.0, 27.0],
        'light': [250.0, 1100.0],
        'soilMoisture': [30.0, 60.0],
      },
    };
