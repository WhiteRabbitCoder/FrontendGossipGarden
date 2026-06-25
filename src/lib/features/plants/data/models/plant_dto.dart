import 'dart:convert';

class PlantResponse {
  final String plantId;
  final String userId;
  final String speciesId;
  final String nickname;
  final String healthStatus;
  final double healthScore;
  final String? photoStoragePath;
  final String? photoUrl;
  final String? commonName;
  final String? scientificName;
  final DateTime createdAt;
  final DateTime? lastHealthCheck;
  final DateTime? lastWatered;
  final int? estimatedAgeMonths;
  final String? location;
  final Map<String, dynamic>? specificCareTips;

  PlantResponse({
    required this.plantId,
    required this.userId,
    required this.speciesId,
    required this.nickname,
    required this.healthStatus,
    required this.healthScore,
    this.photoStoragePath,
    this.photoUrl,
    this.commonName,
    this.scientificName,
    required this.createdAt,
    this.lastHealthCheck,
    this.lastWatered,
    this.estimatedAgeMonths,
    this.location,
    this.specificCareTips,
  });

  factory PlantResponse.fromJson(Map<String, dynamic> json) {
    return PlantResponse(
      plantId: json['plant_id'],
      userId: json['user_id'],
      speciesId: json['species_id'],
      nickname: json['nickname'],
      healthStatus: json['health_status'] ?? 'unknown',
      healthScore: (json['health_score'] ?? 0.0).toDouble(),
      photoStoragePath: json['photo_storage_path'],
      photoUrl: json['photo_url'],
      commonName: json['common_name'],
      scientificName: json['scientific_name'],
      createdAt: DateTime.parse(json['created_at']),
      lastHealthCheck: json['last_health_check'] != null 
          ? DateTime.parse(json['last_health_check']) 
          : null,
      lastWatered: json['last_watered'] != null
          ? DateTime.parse(json['last_watered'])
          : null,
      estimatedAgeMonths: json['estimated_age_months'],
      location: json['location'],
      specificCareTips: json['specific_care_tips'] is String
          ? _tryDecodeJson(json['specific_care_tips'])
          : json['specific_care_tips'],
    );
  }

  static Map<String, dynamic>? _tryDecodeJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}

class CareRangesDTO {
  final double minTempC;
  final double maxTempC;
  final double minLightLux;
  final double maxLightLux;
  final double minAirHumidityPct;
  final double maxAirHumidityPct;
  final double minSoilHumidityPct;
  final double maxSoilHumidityPct;

  CareRangesDTO({
    required this.minTempC,
    required this.maxTempC,
    required this.minLightLux,
    required this.maxLightLux,
    required this.minAirHumidityPct,
    required this.maxAirHumidityPct,
    required this.minSoilHumidityPct,
    required this.maxSoilHumidityPct,
  });

  factory CareRangesDTO.fromJson(Map<String, dynamic> json) {
    return CareRangesDTO(
      minTempC: (json['min_temp_c'] as num?)?.toDouble() ?? 0.0,
      maxTempC: (json['max_temp_c'] as num?)?.toDouble() ?? 0.0,
      minLightLux: (json['min_light_lux'] as num?)?.toDouble() ?? 0.0,
      maxLightLux: (json['max_light_lux'] as num?)?.toDouble() ?? 0.0,
      minAirHumidityPct: (json['min_air_humidity_pct'] as num?)?.toDouble() ?? 0.0,
      maxAirHumidityPct: (json['max_air_humidity_pct'] as num?)?.toDouble() ?? 0.0,
      minSoilHumidityPct: (json['min_soil_humidity_pct'] as num?)?.toDouble() ?? 0.0,
      maxSoilHumidityPct: (json['max_soil_humidity_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SpeciesInfoDTO {
  final String? careSummary;
  final String? aiPersonalityPrompt;
  final List<String> personalityTraits;
  final String? personalityDescription;
  final List<String> careTips;
  final List<String> funFacts;
  final CareRangesDTO? careRanges;

  SpeciesInfoDTO({
    this.careSummary,
    this.aiPersonalityPrompt,
    this.personalityTraits = const [],
    this.personalityDescription,
    this.careTips = const [],
    this.funFacts = const [],
    this.careRanges,
  });

  factory SpeciesInfoDTO.fromJson(Map<String, dynamic> json) {
    return SpeciesInfoDTO(
      careSummary: json['care_summary'],
      aiPersonalityPrompt: json['ai_personality_prompt'],
      personalityTraits: (json['personality_traits'] as List?)?.map((e) => e.toString()).toList() ?? [],
      personalityDescription: json['personality_description'],
      careTips: (json['care_tips'] as List?)?.map((e) => e.toString()).toList() ?? [],
      funFacts: (json['fun_facts'] as List?)?.map((e) => e.toString()).toList() ?? [],
      careRanges: json['care_ranges'] != null ? CareRangesDTO.fromJson(json['care_ranges']) : null,
    );
  }
}

class PlantProfileResponse extends PlantResponse {
  final SpeciesInfoDTO speciesInfo;

  PlantProfileResponse({
    required super.plantId,
    required super.userId,
    required super.speciesId,
    required super.nickname,
    required super.healthStatus,
    required super.healthScore,
    super.photoStoragePath,
    super.photoUrl,
    super.commonName,
    super.scientificName,
    required super.createdAt,
    super.lastHealthCheck,
    super.lastWatered,
    super.estimatedAgeMonths,
    super.location,
    super.specificCareTips,
    required this.speciesInfo,
  });

  factory PlantProfileResponse.fromJson(Map<String, dynamic> json) {
    final base = PlantResponse.fromJson(json);
    return PlantProfileResponse(
      plantId: base.plantId,
      userId: base.userId,
      speciesId: base.speciesId,
      nickname: base.nickname,
      healthStatus: base.healthStatus,
      healthScore: base.healthScore,
      photoStoragePath: base.photoStoragePath,
      photoUrl: base.photoUrl,
      commonName: base.commonName,
      scientificName: base.scientificName,
      createdAt: base.createdAt,
      lastHealthCheck: base.lastHealthCheck,
      lastWatered: base.lastWatered,
      estimatedAgeMonths: base.estimatedAgeMonths,
      location: base.location,
      specificCareTips: base.specificCareTips,
      speciesInfo: SpeciesInfoDTO.fromJson(json['species_info'] ?? {}),
    );
  }
}

class PlantCreate {
  final String speciesId;
  final String nickname;
  final String? photoStoragePath;
  final int? estimatedAgeMonths;
  final String? location;

  PlantCreate({
    required this.speciesId,
    required this.nickname,
    this.photoStoragePath,
    this.estimatedAgeMonths,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'species_id': speciesId,
      'nickname': nickname,
      if (photoStoragePath != null) 'photo_storage_path': photoStoragePath,
      if (estimatedAgeMonths != null) 'estimated_age_months': estimatedAgeMonths,
      if (location != null) 'location': location,
    };
  }
}
