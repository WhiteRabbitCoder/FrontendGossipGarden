import 'package:flutter/material.dart';

import 'plant.dart';
import 'plant_enums.dart';

enum UrgentTaskKind { water, light, sensor, temperature }

class UrgentPlantTask {
  final String id;
  final String plantId;
  final String plantName;
  final String title;
  final String description;
  final UrgentTaskKind kind;
  final ActionUrgency urgency;
  final IconData icon;

  const UrgentPlantTask({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.title,
    required this.description,
    required this.kind,
    required this.urgency,
    required this.icon,
  });
}

List<UrgentPlantTask> deriveUrgentTasks(Plant plant) {
  final tasks = <UrgentPlantTask>[];
  final insight =
      plant.insights.isNotEmpty ? plant.insights.first : 'Necesita tu atención.';

  switch (plant.mood) {
    case PlantMood.thirsty:
      tasks.add(
        UrgentPlantTask(
          id: '${plant.id}_water',
          plantId: plant.id,
          plantName: plant.name,
          title: 'Regar ${plant.name}',
          description: insight,
          kind: UrgentTaskKind.water,
          urgency: ActionUrgency.today,
          icon: Icons.water_drop_outlined,
        ),
      );
    case PlantMood.stressed:
      final needsLight = insight.toLowerCase().contains('luz');
      tasks.add(
        UrgentPlantTask(
          id: '${plant.id}_${needsLight ? 'light' : 'care'}',
          plantId: plant.id,
          plantName: plant.name,
          title: needsLight
              ? 'Mejorar la luz de ${plant.name}'
              : 'Revisar el estrés de ${plant.name}',
          description: insight,
          kind: UrgentTaskKind.light,
          urgency: ActionUrgency.today,
          icon: needsLight
              ? Icons.wb_sunny_outlined
              : Icons.spa_outlined,
        ),
      );
    case PlantMood.cold:
      tasks.add(
        UrgentPlantTask(
          id: '${plant.id}_warm',
          plantId: plant.id,
          plantName: plant.name,
          title: 'Subir la temperatura de ${plant.name}',
          description: insight,
          kind: UrgentTaskKind.temperature,
          urgency: ActionUrgency.today,
          icon: Icons.thermostat_outlined,
        ),
      );
    case PlantMood.hot:
      tasks.add(
        UrgentPlantTask(
          id: '${plant.id}_cool',
          plantId: plant.id,
          plantName: plant.name,
          title: 'Refrescar ${plant.name}',
          description: insight,
          kind: UrgentTaskKind.temperature,
          urgency: ActionUrgency.today,
          icon: Icons.ac_unit_outlined,
        ),
      );
    case PlantMood.happy:
    case PlantMood.perfect:
      break;
  }

  if (plant.sensorStatus == SensorStatus.offline) {
    tasks.add(
      UrgentPlantTask(
        id: '${plant.id}_sensor',
        plantId: plant.id,
        plantName: plant.name,
        title: 'Reconectar sensor de ${plant.name}',
        description: 'El sensor está desconectado y no recibe datos.',
        kind: UrgentTaskKind.sensor,
        urgency: ActionUrgency.today,
        icon: Icons.sensors_off_outlined,
      ),
    );
  }

  return tasks;
}

Plant applyUrgentTaskCompletion(Plant plant, UrgentPlantTask task) {
  switch (task.kind) {
    case UrgentTaskKind.water:
      final targetMoisture = plant.comfortZones.soilMoisture.max * 0.85;
      return plant.copyWith(
        mood: PlantMood.happy,
        lastWatered: 'Hoy',
        health: (plant.health + 12).clamp(0, 100),
        insights: ['Acabo de recibir agua, ¡me siento mucho mejor!'],
        sensors: plant.sensors.copyWith(
          soilMoisture: targetMoisture.clamp(
            plant.comfortZones.soilMoisture.min,
            plant.comfortZones.soilMoisture.max,
          ),
        ),
      );
    case UrgentTaskKind.light:
      final targetLight = plant.comfortZones.light.min * 1.2;
      return plant.copyWith(
        mood: PlantMood.happy,
        health: (plant.health + 10).clamp(0, 100),
        insights: ['La luz ya es suficiente, ¡gracias por cuidarme!'],
        sensors: plant.sensors.copyWith(
          light: targetLight.clamp(
            plant.comfortZones.light.min,
            plant.comfortZones.light.max,
          ),
        ),
      );
    case UrgentTaskKind.sensor:
      return plant.copyWith(
        sensorStatus: SensorStatus.online,
        confidence: ConfidenceLevel.medium,
        insights: plant.insights.isEmpty
            ? ['Sensor reconectado, vuelvo a enviar datos.']
            : [
                'Sensor reconectado, vuelvo a enviar datos.',
                ...plant.insights.skip(1),
              ],
      );
    case UrgentTaskKind.temperature:
      final isCold = plant.mood == PlantMood.cold;
      return plant.copyWith(
        mood: PlantMood.happy,
        health: (plant.health + 8).clamp(0, 100),
        insights: [
          isCold
              ? 'Ya estoy más calentita, gracias.'
              : 'El ambiente está más fresco, ¡qué alivio!',
        ],
        sensors: plant.sensors.copyWith(
          temperature: isCold
              ? (plant.sensors.temperature + 3)
                  .clamp(plant.comfortZones.temperature.min, 35)
              : (plant.sensors.temperature - 3)
                  .clamp(15, plant.comfortZones.temperature.max),
        ),
      );
  }
}
