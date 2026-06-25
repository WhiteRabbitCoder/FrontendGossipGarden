import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/core/services/api_client.dart';

import '../../data/datasources/wifi_setup_datasource.dart';
import '../../data/models/plant.dart';
import '../../data/models/realtime_sensor_snapshot.dart';
import '../../data/models/urgent_plant_task.dart';
import '../../data/models/plant_dto.dart';
import '../../data/datasources/plant_api_datasource.dart';

// ── Providers ───────────────────────────────────────────────────────────────

class PlantsNotifier extends StateNotifier<AsyncValue<List<Plant>>> {
  final PlantApiDatasource _apiDatasource;

  PlantsNotifier(this._apiDatasource) : super(const AsyncValue.loading()) {
    _fetchPlants();
  }

  Future<void> _fetchPlants() async {
    try {
      final plants = await _apiDatasource.getPlants();
      state = AsyncValue.data(plants);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeUrgentTask(UrgentPlantTask task) async {
    try {
      await _apiDatasource.completeUrgentTask(task.plantId, task.kind.name);
      await _fetchPlants();
    } catch (e) {
      // Ignorar fallo por ahora, pero la planta se recargará la próxima vez
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _fetchPlants();
  }
}

final plantsProvider =
    StateNotifierProvider<PlantsNotifier, AsyncValue<List<Plant>>>(
  (ref) => PlantsNotifier(PlantApiDatasource()),
);

// TODO(backend): persistir en perfil de usuario.
final favoritePlantsProvider = StateProvider<List<String>>((ref) => []);

final localAvatarBytesProvider = StateProvider<Uint8List?>((ref) => null);

final wifiSetupDatasourceProvider = Provider<WifiSetupDatasource>(
  (ref) => WifiSetupDatasource(),
);

// Adaptado al backend actual: Polling cada 10 segundos al endpoint latest
final plantRealtimeSensorProvider =
    StreamProvider.family<RealtimeSensorSnapshot?, String>((ref, plantId) async* {
  final apiClient = ApiClient();

  while (true) {
    try {
      final response = await apiClient.dio.get('/plants/$plantId/sensor-data/latest');
      final data = response.data;
      if (data != null) {
        yield RealtimeSensorSnapshot(
          sensorDataId: data['id'] is int ? data['id'] as int : int.tryParse(data['id']?.toString() ?? ''),
          plantId: plantId,
          timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
          temperature: (data['temperature_c'] as num?)?.toDouble() ?? 0.0,
          humidity: (data['humidity_pct'] as num?)?.toDouble() ?? 0.0,
          soilMoisture: (data['soil_moisture_pct'] as num?)?.toDouble() ?? 0.0,
          light: (data['light_lux'] as num?)?.toDouble() ?? 0.0,
        );
      }
    } catch (_) {
      // Si falla, emitimos null para no dejar el stream bloqueado en 'loading'
      yield null;
    }
    // Esperamos 10 segundos antes del siguiente polling para no saturar el backend
    await Future.delayed(const Duration(seconds: 10));
  }
});

// Provider to fetch the rich plant profile (including AI content and care ranges)
final plantProfileProvider = FutureProvider.family<PlantProfileResponse, String>((ref, plantId) async {
  final api = PlantApiDatasource();
  return api.getPlantProfile(plantId);
});
