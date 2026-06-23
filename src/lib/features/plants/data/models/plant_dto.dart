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
      estimatedAgeMonths: json['estimated_age_months'],
      location: json['location'],
      specificCareTips: json['specific_care_tips'],
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
