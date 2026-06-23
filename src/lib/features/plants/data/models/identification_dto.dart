class IdentifyResponse {
  final String status; // 'needs_more_photos', 'needs_user_selection', 'completed'
  final String? reason;
  final double? topProbability;
  final List<PlantCandidate>? candidates;
  final String? photoStoragePath;
  final SpeciesProfile? profile;

  IdentifyResponse({
    required this.status,
    this.reason,
    this.topProbability,
    this.candidates,
    this.photoStoragePath,
    this.profile,
  });

  factory IdentifyResponse.fromJson(Map<String, dynamic> json) {
    return IdentifyResponse(
      status: json['status'],
      reason: json['reason'],
      topProbability: (json['top_probability'] as num?)?.toDouble(),
      candidates: (json['candidates'] as List?)
          ?.map((e) => PlantCandidate.fromJson(e))
          .toList(),
      photoStoragePath: json['photo_storage_path'],
      profile: json['profile'] != null
          ? SpeciesProfile.fromJson(json['profile'])
          : null,
    );
  }
}

class PlantCandidate {
  final String scientificName;
  final List<String> commonNames;
  final double probability;
  final int? gbifId;
  final int? inaturalistId;
  final Map<String, dynamic>? taxonomy;
  final String? description;

  PlantCandidate({
    required this.scientificName,
    required this.commonNames,
    required this.probability,
    this.gbifId,
    this.inaturalistId,
    this.taxonomy,
    this.description,
  });

  factory PlantCandidate.fromJson(Map<String, dynamic> json) {
    return PlantCandidate(
      scientificName: json['scientific_name'],
      commonNames: List<String>.from(json['common_names'] ?? []),
      probability: (json['probability'] ?? 0.0).toDouble(),
      gbifId: json['gbif_id'],
      inaturalistId: json['inaturalist_id'],
      taxonomy: json['taxonomy'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scientific_name': scientificName,
      'common_names': commonNames,
      'probability': probability,
      'gbif_id': gbifId,
      'inaturalist_id': inaturalistId,
      'taxonomy': taxonomy,
      'description': description,
    };
  }
}

class SpeciesProfile {
  final String speciesId;
  final String scientificName;
  final String? commonName;
  final String? family;
  final CareRanges? careRanges;
  final Map<String, dynamic>? careWeights;
  final Map<String, dynamic>? sensitivityAssessment;
  final Map<String, dynamic>? evalIntervals;
  final String? careSummary;
  final String? aiPersonalityPrompt;
  final List<String> careTips;
  final List<String> funFacts;
  final List<Map<String, dynamic>> faq;
  final String? proposalConfidence;
  final bool needsReview;
  final String language;
  final bool cached;

  SpeciesProfile({
    required this.speciesId,
    required this.scientificName,
    this.commonName,
    this.family,
    this.careRanges,
    this.careWeights,
    this.sensitivityAssessment,
    this.evalIntervals,
    this.careSummary,
    this.aiPersonalityPrompt,
    required this.careTips,
    required this.funFacts,
    required this.faq,
    this.proposalConfidence,
    required this.needsReview,
    required this.language,
    required this.cached,
  });

  factory SpeciesProfile.fromJson(Map<String, dynamic> json) {
    return SpeciesProfile(
      speciesId: json['species_id'],
      scientificName: json['scientific_name'],
      commonName: json['common_name'],
      family: json['family'],
      careRanges: json['care_ranges'] != null
          ? CareRanges.fromJson(json['care_ranges'])
          : null,
      careWeights: json['care_weights'],
      sensitivityAssessment: json['sensitivity_assessment'],
      evalIntervals: json['eval_intervals'],
      careSummary: json['care_summary'],
      aiPersonalityPrompt: json['ai_personality_prompt'],
      careTips: List<String>.from(json['care_tips'] ?? []),
      funFacts: List<String>.from(json['fun_facts'] ?? []),
      faq: List<Map<String, dynamic>>.from(json['faq'] ?? []),
      proposalConfidence: json['proposal_confidence'],
      needsReview: json['needs_review'] ?? false,
      language: json['language'] ?? 'es',
      cached: json['cached'] ?? false,
    );
  }
}

class CareRanges {
  final double minTempC;
  final double maxTempC;
  final double minLightLux;
  final double maxLightLux;
  final double minAirHumidityPct;
  final double maxAirHumidityPct;
  final double minSoilHumidityPct;
  final double maxSoilHumidityPct;

  CareRanges({
    required this.minTempC,
    required this.maxTempC,
    required this.minLightLux,
    required this.maxLightLux,
    required this.minAirHumidityPct,
    required this.maxAirHumidityPct,
    required this.minSoilHumidityPct,
    required this.maxSoilHumidityPct,
  });

  factory CareRanges.fromJson(Map<String, dynamic> json) {
    return CareRanges(
      minTempC: (json['min_temp_c'] ?? 0).toDouble(),
      maxTempC: (json['max_temp_c'] ?? 0).toDouble(),
      minLightLux: (json['min_light_lux'] ?? 0).toDouble(),
      maxLightLux: (json['max_light_lux'] ?? 0).toDouble(),
      minAirHumidityPct: (json['min_air_humidity_pct'] ?? 0).toDouble(),
      maxAirHumidityPct: (json['max_air_humidity_pct'] ?? 0).toDouble(),
      minSoilHumidityPct: (json['min_soil_humidity_pct'] ?? 0).toDouble(),
      maxSoilHumidityPct: (json['max_soil_humidity_pct'] ?? 0).toDouble(),
    );
  }
}

class CandidateSelectionRequest {
  final PlantCandidate candidate;
  final String outputLanguage;

  CandidateSelectionRequest({
    required this.candidate,
    this.outputLanguage = 'es',
  });

  Map<String, dynamic> toJson() {
    return {
      'candidate': candidate.toJson(),
      'output_language': outputLanguage,
    };
  }
}
