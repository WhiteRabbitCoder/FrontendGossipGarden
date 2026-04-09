import 'plant_enums.dart';
import 'plant_action.dart';
import 'sensors.dart';
import 'comfort_zones.dart';

class Plant {
  final String id;
  final String name;
  final String species;
  final String image;

  final PlantPersonality personality;
  final double health;
  final PlantMood mood;

  final String lastWatered;

  final Sensors sensors;
  final SensorStatus sensorStatus;
  final ConfidenceLevel confidence;

  final List<PlantAction> actions;
  final List<String> insights;
  final ComfortZones comfortZones;

  const Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.image,
    required this.personality,
    required this.health,
    required this.mood,
    required this.lastWatered,
    required this.sensors,
    required this.sensorStatus,
    required this.confidence,
    required this.actions,
    required this.insights,
    required this.comfortZones,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Sin nombre',
      species: json['species'] ?? '',
      image: json['image'] ?? '',

      health: (json['health'] as num?)?.toDouble() ?? 0,
      lastWatered: json['lastWatered'] ?? '',

      personality: enumFromString(
        PlantPersonality.values,
        json['personality'],
        PlantPersonality.playful,
      ),
      mood: enumFromString(
        PlantMood.values,
        json['mood'],
        PlantMood.happy,
      ),
      sensorStatus: enumFromString(
        SensorStatus.values,
        json['sensorStatus'],
        SensorStatus.offline,
      ),
      confidence: enumFromString(
        ConfidenceLevel.values,
        json['confidence'],
        ConfidenceLevel.low,
      ),

      sensors: Sensors.fromJson(json['sensors'] ?? {}),
      comfortZones: ComfortZones.fromJson(json['comfortZones'] ?? {}),

      insights: List<String>.from(json['insights'] ?? []),

      actions: (json['actions'] as List?)
              ?.map((e) => PlantAction.fromJson(e))
              .toList() ??
          [],
    );
  }
}