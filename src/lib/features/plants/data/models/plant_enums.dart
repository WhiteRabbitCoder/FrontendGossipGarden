enum PlantPersonality { wise, playful, dramatic }
enum PlantMood { happy, thirsty, cold, hot, stressed, perfect }
enum SensorStatus { online, offline, degraded, unlinked }
enum ConfidenceLevel { high, medium, low }
enum PlantActionType { water, light, move, fertilize, prune }
enum ActionUrgency { today, soon, later }

/// 🔥 SAFE PARSER (CLAVE SENIOR)
T enumFromString<T>(List<T> values, String? value, T fallback) {
  return values.firstWhere(
    (e) => e.toString().split('.').last == value,
    orElse: () => fallback,
  );
}