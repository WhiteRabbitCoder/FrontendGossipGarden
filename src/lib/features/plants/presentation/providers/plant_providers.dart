import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/wifi_setup_datasource.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../data/models/sensors.dart';
import '../../data/models/comfort_zones.dart';
import '../../data/models/realtime_sensor_snapshot.dart';
import '../../data/models/urgent_plant_task.dart';

// ── Demo plants ──────────────────────────────────────────────────────────────
// HARDCODE(demo): tres plantas locales con sensores y moods inventados.
// TODO(backend): Reemplazar el cuerpo del FutureProvider con:
//   PlantApiDatasource().getPlants()
// cuando el backend esté disponible. Los modelos Plant ya están mapeados al contrato.

const _demoMonstera = Plant(
  id: '1',
  name: 'Monstera',
  species: 'Monstera Deliciosa',
  image: '',
  personality: PlantPersonality.dramatic,
  health: 78.0,
  mood: PlantMood.thirsty,
  lastWatered: 'Hace 3 días',
  sensors: Sensors(
    humidity: 25.0,
    temperature: 22.0,
    light: 1500.0,
    soilMoisture: 15.0,
  ),
  sensorStatus: SensorStatus.offline,
  confidence: ConfidenceLevel.low,
  actions: [],
  insights: ['Necesito agua, la tierra está muy seca.'],
  comfortZones: ComfortZones(
    humidity: Range(40, 70),
    temperature: Range(18, 27),
    light: Range(500, 2000),
    soilMoisture: Range(30, 60),
  ),
);

const _demoSuculenta = Plant(
  id: '2',
  name: 'Suculenta Luna',
  species: 'Echeveria Elegans',
  image: '',
  personality: PlantPersonality.wise,
  health: 95.0,
  mood: PlantMood.perfect,
  lastWatered: 'Hace 1 semana',
  sensors: Sensors(
    humidity: 45.0,
    temperature: 23.0,
    light: 4000.0,
    soilMoisture: 35.0,
  ),
  sensorStatus: SensorStatus.online,
  confidence: ConfidenceLevel.high,
  actions: [],
  insights: [
    'Todo perfecto, luz y humedad en nivel...',
    'Suculenta Luna querrá un poquito de agua en 4 días según sus proyecciones de humedad.',
  ],
  comfortZones: ComfortZones(
    humidity: Range(20, 60),
    temperature: Range(15, 35),
    light: Range(2000, 6000),
    soilMoisture: Range(10, 40),
  ),
);

const _demoFicus = Plant(
  id: '3',
  name: 'Ficus Maestro',
  species: 'Ficus Lyrata',
  image: '',
  personality: PlantPersonality.playful,
  health: 55.0,
  mood: PlantMood.stressed,
  lastWatered: 'Hace 2 días',
  sensors: Sensors(
    humidity: 30.0,
    temperature: 19.0,
    light: 800.0,
    soilMoisture: 40.0,
  ),
  sensorStatus: SensorStatus.online,
  confidence: ConfidenceLevel.medium,
  actions: [],
  insights: ['La luz no es suficiente para mantener un crecimiento saludable.'],
  comfortZones: ComfortZones(
    humidity: Range(30, 65),
    temperature: Range(18, 30),
    light: Range(1500, 4000),
    soilMoisture: Range(30, 60),
  ),
);

// ── Providers ───────────────────────────────────────────────────────────────

class PlantsNotifier extends StateNotifier<AsyncValue<List<Plant>>> {
  PlantsNotifier() : super(const AsyncValue.loading()) {
    state = const AsyncValue.data([
      _demoMonstera,
      _demoSuculenta,
      _demoFicus,
    ]);
  }

  // HARDCODE(demo): actualiza mood/health en memoria al marcar checklist. TODO(backend): PATCH planta.
  void completeUrgentTask(UrgentPlantTask task) {
    state.whenData((plants) {
      final updated = plants
          .map(
            (plant) => plant.id == task.plantId
                ? applyUrgentTaskCompletion(plant, task)
                : plant,
          )
          .toList();
      state = AsyncValue.data(updated);
    });
  }
}

final plantsProvider =
    StateNotifierProvider<PlantsNotifier, AsyncValue<List<Plant>>>(
  (ref) => PlantsNotifier(),
);

// HARDCODE(demo): IDs iniciales de favoritas. TODO(backend): persistir en perfil de usuario.
final favoritePlantsProvider =
    StateProvider<List<String>>((ref) => ['1', '2']);

final localAvatarBytesProvider = StateProvider<Uint8List?>((ref) => null);

final wifiSetupDatasourceProvider = Provider<WifiSetupDatasource>(
  (ref) => const WifiSetupDatasource(),
);

// HARDCODE(demo): lecturas aleatorias simuladas cada 5 s. TODO(backend): stream MQTT/WebSocket del sensor.
final plantRealtimeSensorProvider =
    StreamProvider.family<RealtimeSensorSnapshot, String>((ref, plantId) {
  final rng = Random();
  return Stream.periodic(const Duration(seconds: 5), (_) {
    return RealtimeSensorSnapshot(
      sensorDataId: null,
      plantId: 0,
      timestamp: DateTime.now(),
      temperature: 24.5 + (rng.nextDouble() - 0.5) * 0.6,
      humidity: 38.0 + (rng.nextDouble() - 0.5) * 1.5,
      soilMoisture: 31.0 + (rng.nextDouble() - 0.5) * 0.8,
      light: 3400.0 + (rng.nextDouble() - 0.5) * 120,
    );
  });
});
