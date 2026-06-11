import 'dart:convert';
import 'dart:io';

import '../models/achievement.dart';
import '../models/plant.dart';
import 'achievement_definitions.dart';

class AchievementProgressStorage {
  static const _fileName = 'gossip_garden_achievement_stats.json';

  File get _file => File('${Directory.systemTemp.path}/$_fileName');

  Future<AchievementStats> load() async {
    try {
      if (await _file.exists()) {
        final content = await _file.readAsString();
        return AchievementStats.fromJson(
          jsonDecode(content) as Map<String, dynamic>,
        );
      }
    } catch (_) {}

    final seed = AchievementStats.demoSeed;
    await save(seed);
    return seed;
  }

  Future<void> save(AchievementStats stats) async {
    try {
      await _file.writeAsString(jsonEncode(stats.toJson()));
    } catch (_) {}
  }

  List<AchievementProgress> buildProgressList({
    required AchievementStats stats,
    required List<Plant> plants,
    required List<String> favoritePlantIds,
  }) {
    final healthyCount =
        plants.where((plant) => plant.health >= 80).length;

    return kAchievementDefinitions.map((definition) {
      final current = _currentForMetric(
        definition.metric,
        stats: stats,
        plants: plants,
        favoritePlantIds: favoritePlantIds,
        healthyCount: healthyCount,
      );
      final unlocked = current >= definition.goal;

      return AchievementProgress(
        definition: definition,
        current: current,
        unlocked: unlocked,
      );
    }).toList();
  }

  int _currentForMetric(
    AchievementMetric metric, {
    required AchievementStats stats,
    required List<Plant> plants,
    required List<String> favoritePlantIds,
    required int healthyCount,
  }) {
    switch (metric) {
      case AchievementMetric.waterings:
        return stats.wateringsCount;
      case AchievementMetric.healthyPlants:
        return healthyCount;
      case AchievementMetric.identifications:
        return stats.identificationsCount;
      case AchievementMetric.chatMessages:
        return stats.chatMessagesCount;
      case AchievementMetric.plantsOwned:
        return plants.length;
      case AchievementMetric.sensorSetup:
        return stats.sensorSetupCompleted ? 1 : 0;
      case AchievementMetric.loginStreak:
        return stats.loginStreak;
      case AchievementMetric.gardenVisits:
        return stats.gardenVisitsCount;
      case AchievementMetric.favoritePlants:
        return favoritePlantIds.length;
    }
  }
}
