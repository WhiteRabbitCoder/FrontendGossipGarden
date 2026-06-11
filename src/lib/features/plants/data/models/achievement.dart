enum AchievementMetric {
  waterings,
  healthyPlants,
  identifications,
  chatMessages,
  plantsOwned,
  sensorSetup,
  loginStreak,
  gardenVisits,
  favoritePlants,
}

class AchievementDefinition {
  final String id;
  final String icon;
  final String title;
  final String description;
  final String howToEarn;
  final String trackingSource;
  final int goal;
  final AchievementMetric metric;

  const AchievementDefinition({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.howToEarn,
    required this.trackingSource,
    required this.goal,
    required this.metric,
  });
}

class AchievementProgress {
  final AchievementDefinition definition;
  final int current;
  final bool unlocked;

  const AchievementProgress({
    required this.definition,
    required this.current,
    required this.unlocked,
  });

  int get goal => definition.goal;

  double get ratio =>
      goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

  int get displayCurrent => unlocked ? goal : current.clamp(0, goal);
}

class AchievementStats {
  final int wateringsCount;
  final int identificationsCount;
  final int chatMessagesCount;
  final int gardenVisitsCount;
  final int loginStreak;
  final bool sensorSetupCompleted;
  final String? lastGardenVisitDate;
  final String? lastLoginDate;
  final Map<String, Map<String, dynamic>> sensorBaselines;
  final Map<String, String> lastWateringDetectedAt;

  const AchievementStats({
    this.wateringsCount = 0,
    this.identificationsCount = 0,
    this.chatMessagesCount = 0,
    this.gardenVisitsCount = 0,
    this.loginStreak = 0,
    this.sensorSetupCompleted = false,
    this.lastGardenVisitDate,
    this.lastLoginDate,
    this.sensorBaselines = const {},
    this.lastWateringDetectedAt = const {},
  });

  AchievementStats copyWith({
    int? wateringsCount,
    int? identificationsCount,
    int? chatMessagesCount,
    int? gardenVisitsCount,
    int? loginStreak,
    bool? sensorSetupCompleted,
    String? lastGardenVisitDate,
    String? lastLoginDate,
    Map<String, Map<String, dynamic>>? sensorBaselines,
    Map<String, String>? lastWateringDetectedAt,
  }) {
    return AchievementStats(
      wateringsCount: wateringsCount ?? this.wateringsCount,
      identificationsCount: identificationsCount ?? this.identificationsCount,
      chatMessagesCount: chatMessagesCount ?? this.chatMessagesCount,
      gardenVisitsCount: gardenVisitsCount ?? this.gardenVisitsCount,
      loginStreak: loginStreak ?? this.loginStreak,
      sensorSetupCompleted: sensorSetupCompleted ?? this.sensorSetupCompleted,
      lastGardenVisitDate: lastGardenVisitDate ?? this.lastGardenVisitDate,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      sensorBaselines: sensorBaselines ?? this.sensorBaselines,
      lastWateringDetectedAt:
          lastWateringDetectedAt ?? this.lastWateringDetectedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'wateringsCount': wateringsCount,
        'identificationsCount': identificationsCount,
        'chatMessagesCount': chatMessagesCount,
        'gardenVisitsCount': gardenVisitsCount,
        'loginStreak': loginStreak,
        'sensorSetupCompleted': sensorSetupCompleted,
        'lastGardenVisitDate': lastGardenVisitDate,
        'lastLoginDate': lastLoginDate,
        'sensorBaselines': sensorBaselines,
        'lastWateringDetectedAt': lastWateringDetectedAt,
      };

  factory AchievementStats.fromJson(Map<String, dynamic> json) {
    final baselinesRaw = json['sensorBaselines'];
    final wateringRaw = json['lastWateringDetectedAt'];

    return AchievementStats(
      wateringsCount: json['wateringsCount'] as int? ?? 0,
      identificationsCount: json['identificationsCount'] as int? ?? 0,
      chatMessagesCount: json['chatMessagesCount'] as int? ?? 0,
      gardenVisitsCount: json['gardenVisitsCount'] as int? ?? 0,
      loginStreak: json['loginStreak'] as int? ?? 0,
      sensorSetupCompleted: json['sensorSetupCompleted'] as bool? ?? false,
      lastGardenVisitDate: json['lastGardenVisitDate'] as String?,
      lastLoginDate: json['lastLoginDate'] as String?,
      sensorBaselines: baselinesRaw is Map
          ? baselinesRaw.map(
              (key, value) => MapEntry(
                key.toString(),
                Map<String, dynamic>.from(value as Map),
              ),
            )
          : const {},
      lastWateringDetectedAt: wateringRaw is Map
          ? wateringRaw.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const {},
    );
  }

  static const demoSeed = AchievementStats(
    wateringsCount: 4,
    identificationsCount: 12,
    chatMessagesCount: 8,
    gardenVisitsCount: 5,
    loginStreak: 3,
    sensorSetupCompleted: false,
  );
}
