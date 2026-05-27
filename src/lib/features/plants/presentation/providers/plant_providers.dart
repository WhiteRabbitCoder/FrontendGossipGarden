import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/identification_api_datasource.dart';
import '../../data/datasources/plant_api_datasource.dart';
import '../../data/datasources/plant_create_datasource.dart';
import '../../data/datasources/wifi_setup_datasource.dart';
import '../../data/models/plant.dart';
import '../../data/models/realtime_sensor_snapshot.dart';

// ── Auth-aware datasource providers ─────────────────────────────────────────

final plantApiDatasourceProvider = Provider<PlantApiDatasource>((ref) {
  final token = ref.watch(backendTokenProvider);
  return PlantApiDatasource(authToken: token);
});

final identificationApiDatasourceProvider =
    Provider<IdentificationApiDatasource>((ref) {
  final token = ref.watch(backendTokenProvider);
  return IdentificationApiDatasource(authToken: token);
});

final plantCreateDatasourceProvider = Provider<PlantCreateDatasource>((ref) {
  final token = ref.watch(backendTokenProvider);
  return PlantCreateDatasource(authToken: token);
});

// ── Plants list (polling cada 30 s) ──────────────────────────────────────────

final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  final datasource = ref.watch(plantApiDatasourceProvider);

  // Refresca automáticamente cada 30 segundos.
  final timer = Timer(const Duration(seconds: 30), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);

  return datasource.getPlants();
});

// ── Realtime sensor polling (cada 15 s) ───────────────────────────────────────

final plantRealtimeSensorProvider =
    StreamProvider.family<RealtimeSensorSnapshot, String>((ref, plantId) {
  final datasource = ref.watch(plantApiDatasourceProvider);

  return Stream.periodic(const Duration(seconds: 15), (_) => null)
      .asyncMap((_) async {
    try {
      final snapshot = await datasource.getSensorSnapshot(plantId);
      final latest = snapshot.latestSensorData;
      if (latest == null) {
        return RealtimeSensorSnapshot(
          sensorDataId: null,
          plantId: 0,
          timestamp: DateTime.now(),
          temperature: 0,
          humidity: 0,
          soilMoisture: 0,
          light: 0,
        );
      }
      return RealtimeSensorSnapshot(
        sensorDataId: null,
        plantId: 0,
        timestamp: DateTime.tryParse(
                latest['timestamp']?.toString() ?? '') ??
            DateTime.now(),
        temperature: (latest['temperature'] as num?)?.toDouble() ?? 0,
        humidity: (latest['humidity'] as num?)?.toDouble() ?? 0,
        soilMoisture: (latest['soil_moisture'] as num?)?.toDouble() ?? 0,
        light: (latest['light'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return RealtimeSensorSnapshot(
        sensorDataId: null,
        plantId: 0,
        timestamp: DateTime.now(),
        temperature: 0,
        humidity: 0,
        soilMoisture: 0,
        light: 0,
      );
    }
  });
});

// ── Misc ──────────────────────────────────────────────────────────────────────

final wifiSetupDatasourceProvider = Provider<WifiSetupDatasource>(
  (ref) => const WifiSetupDatasource(),
);
