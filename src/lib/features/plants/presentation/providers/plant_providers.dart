import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/wifi_setup_datasource.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../data/models/sensors.dart';
import '../../data/models/comfort_zones.dart';
import '../../data/models/realtime_sensor_snapshot.dart';

// ── Demo plant ──────────────────────────────────────────────────────────────

const _demoPlant = Plant(
  id: 'demo-001',
  name: 'Monducuru',
  species: 'Opuntia monacantha',
  image: '',
  personality: PlantPersonality.dramatic,
  health: 82.0,
  mood: PlantMood.happy,
  lastWatered: 'Hace 2 días',
  sensors: Sensors(
    humidity: 38.0,
    temperature: 24.5,
    light: 3400.0,
    soilMoisture: 31.0,
  ),
  sensorStatus: SensorStatus.online,
  confidence: ConfidenceLevel.high,
  actions: [],
  insights: [
    'Mi tierra está al 31% — perfectamente seca para alguien de mi linaje.',
    'Luz en 3400 lux. Estoy en modo cactus zen. No me molestes.',
    'Temperatura ideal. Aunque podría estar más cálido, no me quejo... mucho.',
  ],
  comfortZones: ComfortZones(
    humidity: Range(20, 60),
    temperature: Range(15, 35),
    light: Range(2000, 6000),
    soilMoisture: Range(10, 40),
  ),
);

// ── Providers ───────────────────────────────────────────────────────────────

final plantsProvider = FutureProvider<List<Plant>>((_) async => [_demoPlant]);

final wifiSetupDatasourceProvider = Provider<WifiSetupDatasource>(
  (ref) => const WifiSetupDatasource(),
);

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
