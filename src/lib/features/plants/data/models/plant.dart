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
  
  final String? macAddress;

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
    this.macAddress,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sin nombre',
      species: json['species']?.toString() ?? '',
      image: json['image']?.toString() ?? '',

      health: (json['health'] as num?)?.toDouble() ?? 0.0,
      lastWatered: json['lastWatered']?.toString() ?? '',

      // Mapeo de Enums usando la utilidad inferior
      personality: _enumFromString(
        PlantPersonality.values,
        json['personality'],
        PlantPersonality.playful,
      ),
      mood: _enumFromString(
        PlantMood.values,
        json['mood'],
        PlantMood.happy,
      ),
      sensorStatus: _enumFromString(
        SensorStatus.values,
        json['sensorStatus'],
        SensorStatus.offline,
      ),
      confidence: _enumFromString(
        ConfidenceLevel.values,
        json['confidence'],
        ConfidenceLevel.low,
      ),

      // Inicialización de sub-objetos con validación de nulos
      sensors: Sensors.fromJson(json['sensors'] ?? {}),
      comfortZones: ComfortZones.fromJson(json['comfortZones'] ?? {}),

      // Listas
      insights: List<String>.from(json['insights'] ?? []),
      actions: (json['actions'] as List?)
              ?.map((e) => PlantAction.fromJson(e))
              .toList() ??
          [],
      macAddress: json['mac_address']?.toString(),
    );
  }

  Plant copyWith({
    String? id,
    String? name,
    String? species,
    String? image,
    PlantPersonality? personality,
    double? health,
    PlantMood? mood,
    String? lastWatered,
    Sensors? sensors,
    SensorStatus? sensorStatus,
    ConfidenceLevel? confidence,
    List<PlantAction>? actions,
    List<String>? insights,
    ComfortZones? comfortZones,
    String? macAddress,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      image: image ?? this.image,
      personality: personality ?? this.personality,
      health: health ?? this.health,
      mood: mood ?? this.mood,
      lastWatered: lastWatered ?? this.lastWatered,
      sensors: sensors ?? this.sensors,
      sensorStatus: sensorStatus ?? this.sensorStatus,
      confidence: confidence ?? this.confidence,
      actions: actions ?? this.actions,
      insights: insights ?? this.insights,
      comfortZones: comfortZones ?? this.comfortZones,
      macAddress: macAddress ?? this.macAddress,
    );
  }
}

/// Utilidad para convertir String de JSON a Enum de Dart de forma segura.
/// Se marca con '_' para que sea privada a este archivo.
T _enumFromString<T>(List<T> values, dynamic key, T defaultValue) {
  if (key == null || key is! String) return defaultValue;
  return values.firstWhere(
    (v) => v.toString().split('.').last.toLowerCase() == key.toLowerCase(),
    orElse: () => defaultValue,
  );
}