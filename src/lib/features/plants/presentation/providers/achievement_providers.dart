import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/achievements/achievement_progress_storage.dart';
import '../../data/achievements/watering_detection.dart';
import '../../data/models/achievement.dart';
import '../../data/models/realtime_sensor_snapshot.dart';
import 'plant_providers.dart';

// HARDCODE(demo): progreso en JSON temporal + detección de riego sobre stream simulado.
// TODO(backend): sincronizar stats con backend y sensores reales.
final achievementStorageProvider =
    Provider<AchievementProgressStorage>((_) => AchievementProgressStorage());

class AchievementStatsNotifier extends StateNotifier<AsyncValue<AchievementStats>> {
  AchievementStatsNotifier(this._storage) : super(const AsyncValue.loading()) {
    _load();
  }

  final AchievementProgressStorage _storage;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _storage.load());
  }

  Future<void> _persist(AchievementStats stats) async {
    await _storage.save(stats);
    state = AsyncValue.data(stats);
  }

  String _todayKey() => DateTime.now().toIso8601String().split('T').first;

  String _yesterdayKey() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.toIso8601String().split('T').first;
  }

  AchievementStats? get _stats => state.value;

  Future<void> processSensorReading(
    String plantId,
    RealtimeSensorSnapshot snapshot,
  ) async {
    final current = _stats;
    if (current == null || snapshot.soilMoisture == null) return;

    final baselines = Map<String, Map<String, dynamic>>.from(
      current.sensorBaselines,
    );
    final wateringTimes = Map<String, String>.from(
      current.lastWateringDetectedAt,
    );
    final nextBaseline = baselineFromSnapshot(snapshot);

    final previousRaw = baselines[plantId];
    if (previousRaw == null) {
      baselines[plantId] = nextBaseline.toJson();
      await _persist(current.copyWith(sensorBaselines: baselines));
      return;
    }

    final previous = PlantSensorBaseline.fromJson(previousRaw);
    final detection = detectWateringFromSensorVariation(
      previous: previous,
      current: snapshot,
    );

    baselines[plantId] = nextBaseline.toJson();

    if (!detection.detected ||
        isWateringCooldownActive(wateringTimes[plantId])) {
      await _persist(current.copyWith(sensorBaselines: baselines));
      return;
    }

    wateringTimes[plantId] = DateTime.now().toIso8601String();
    await _persist(
      current.copyWith(
        wateringsCount: current.wateringsCount + 1,
        sensorBaselines: baselines,
        lastWateringDetectedAt: wateringTimes,
      ),
    );
  }

  Future<void> recordIdentification() async {
    final current = _stats;
    if (current == null) return;
    await _persist(
      current.copyWith(identificationsCount: current.identificationsCount + 1),
    );
  }

  Future<void> recordChatMessage() async {
    final current = _stats;
    if (current == null) return;
    await _persist(
      current.copyWith(chatMessagesCount: current.chatMessagesCount + 1),
    );
  }

  Future<void> recordSensorSetup() async {
    final current = _stats;
    if (current == null) return;
    if (current.sensorSetupCompleted) return;
    await _persist(current.copyWith(sensorSetupCompleted: true));
  }

  Future<void> recordGardenVisit() async {
    final current = _stats;
    if (current == null) return;

    final today = _todayKey();
    if (current.lastGardenVisitDate == today) return;

    await _persist(
      current.copyWith(
        gardenVisitsCount: current.gardenVisitsCount + 1,
        lastGardenVisitDate: today,
      ),
    );
  }

  Future<void> recordLoginSession() async {
    final current = _stats;
    if (current == null) return;

    final today = _todayKey();
    if (current.lastLoginDate == today) return;

    final yesterday = _yesterdayKey();
    final nextStreak = current.lastLoginDate == yesterday
        ? current.loginStreak + 1
        : 1;

    await _persist(
      current.copyWith(
        loginStreak: nextStreak,
        lastLoginDate: today,
      ),
    );
  }
}

final achievementStatsProvider =
    StateNotifierProvider<AchievementStatsNotifier, AsyncValue<AchievementStats>>(
  (ref) => AchievementStatsNotifier(ref.read(achievementStorageProvider)),
);

final achievementProgressListProvider =
    Provider<AsyncValue<List<AchievementProgress>>>((ref) {
  final statsAsync = ref.watch(achievementStatsProvider);
  final plantsAsync = ref.watch(plantsProvider);
  final favorites = ref.watch(favoritePlantsProvider);

  return statsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (stats) {
      return plantsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (plants) {
          final storage = ref.read(achievementStorageProvider);
          return AsyncValue.data(
            storage.buildProgressList(
              stats: stats,
              plants: plants,
              favoritePlantIds: favorites,
            ),
          );
        },
      );
    },
  );
});

AchievementProgress? findAchievementProgress(
  List<AchievementProgress> list,
  String id,
) {
  for (final item in list) {
    if (item.definition.id == id) return item;
  }
  return null;
}

/// Escucha el stream de sensores de cada planta y detecta riegos por variación.
final achievementWateringWatcherProvider = Provider.family<void, String>(
  (ref, plantId) {
    ref.listen(plantRealtimeSensorProvider(plantId), (previous, next) {
      next.whenData((snapshot) {
        if (snapshot != null) {
          ref
              .read(achievementStatsProvider.notifier)
              .processSensorReading(plantId, snapshot!);
        }
      });
    });
  },
);

/// Proveedor centralizado para observar los sensores de todas las plantas simultáneamente.
final allWateringWatchersProvider = Provider<void>((ref) {
  final plants = ref.watch(plantsProvider).valueOrNull;
  if (plants != null) {
    for (final plant in plants) {
      ref.watch(achievementWateringWatcherProvider(plant.id));
    }
  }
});
