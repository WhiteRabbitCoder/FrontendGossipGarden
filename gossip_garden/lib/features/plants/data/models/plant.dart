import '../../../../core/utils/enum_utils.dart';
import 'plant_enums.dart';
import 'sensors.dart';
import 'plant_action.dart';
import 'comfort_zones.dart';

class Plant {
  final String id;
  final String name;
  final double health;
  final PlantMood mood;
  final Sensors sensors;
  final ComfortZones comfortZones;

  Plant({
    required this.id,
    required this.name,
    required this.health,
    required this.mood,
    required this.sensors,
    required this.comfortZones,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      health: (json['health'] as num?)?.toDouble() ?? 0,
      mood: enumFromString(
        PlantMood.values,
        json['mood'],
        PlantMood.happy,
      ),
      sensors: Sensors.fromJson(json['sensors'] ?? {}),
      comfortZones: ComfortZones.fromJson(json['comfortZones'] ?? {}),
    );
  }
}