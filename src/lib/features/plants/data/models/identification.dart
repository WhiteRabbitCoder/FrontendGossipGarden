// Modelos para los tres posibles resultados de POST /api/v1/identify.
// Ver backendGossipGarden/API_CONTRACT.md §3.

sealed class IdentifyResult {}

class NeedsMorePhotos extends IdentifyResult {
  NeedsMorePhotos({required this.reason, required this.topProbability});
  final String reason;
  final double topProbability;
}

class NeedsUserSelection extends IdentifyResult {
  NeedsUserSelection({required this.candidates});
  final List<SpeciesCandidate> candidates;
}

class IdentifyCompleted extends IdentifyResult {
  IdentifyCompleted({required this.profile, this.photoStoragePath});
  final CareProfile profile;
  final String? photoStoragePath;
}

// ─── Species candidate (para flujo needs_user_selection) ──────────────────────

class SpeciesCandidate {
  const SpeciesCandidate({
    required this.scientificName,
    required this.commonNames,
    required this.probability,
    this.gbifId,
    this.inaturalistId,
    this.family,
    this.genus,
    this.description,
  });

  final String scientificName;
  final List<String> commonNames;
  final double probability;
  final int? gbifId;
  final int? inaturalistId;
  final String? family;
  final String? genus;
  final String? description;

  factory SpeciesCandidate.fromJson(Map<String, dynamic> j) {
    final taxonomy = j['taxonomy'] as Map<String, dynamic>? ?? {};
    return SpeciesCandidate(
      scientificName: j['scientific_name'] as String? ?? '',
      commonNames: (j['common_names'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      probability: (j['probability'] as num?)?.toDouble() ?? 0.0,
      gbifId: j['gbif_id'] as int?,
      inaturalistId: j['inaturalist_id'] as int?,
      family: (taxonomy['family'] ?? j['family']) as String?,
      genus: (taxonomy['genus'] ?? j['genus']) as String?,
      description: j['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'scientific_name': scientificName,
        'common_names': commonNames,
        'probability': probability,
        if (gbifId != null) 'gbif_id': gbifId,
        if (inaturalistId != null) 'inaturalist_id': inaturalistId,
        'taxonomy': {
          if (family != null) 'family': family,
          if (genus != null) 'genus': genus,
        },
      };
}

// ─── Care profile (resultado de identificación completa) ──────────────────────

class CareRanges {
  const CareRanges({
    required this.minTempC,
    required this.maxTempC,
    required this.minLightLux,
    required this.maxLightLux,
    required this.minAirHumidityPct,
    required this.maxAirHumidityPct,
    required this.minSoilHumidityPct,
    required this.maxSoilHumidityPct,
  });

  final double minTempC;
  final double maxTempC;
  final double minLightLux;
  final double maxLightLux;
  final double minAirHumidityPct;
  final double maxAirHumidityPct;
  final double minSoilHumidityPct;
  final double maxSoilHumidityPct;

  factory CareRanges.fromJson(Map<String, dynamic> j) => CareRanges(
        minTempC: (j['min_temp_c'] as num).toDouble(),
        maxTempC: (j['max_temp_c'] as num).toDouble(),
        minLightLux: (j['min_light_lux'] as num).toDouble(),
        maxLightLux: (j['max_light_lux'] as num).toDouble(),
        minAirHumidityPct: (j['min_air_humidity_pct'] as num).toDouble(),
        maxAirHumidityPct: (j['max_air_humidity_pct'] as num).toDouble(),
        minSoilHumidityPct: (j['min_soil_humidity_pct'] as num).toDouble(),
        maxSoilHumidityPct: (j['max_soil_humidity_pct'] as num).toDouble(),
      );
}

class CareWeights {
  const CareWeights({
    required this.light,
    required this.soilHumidity,
    required this.airHumidity,
    required this.temperature,
  });

  final double light;
  final double soilHumidity;
  final double airHumidity;
  final double temperature;

  factory CareWeights.fromJson(Map<String, dynamic> j) => CareWeights(
        light: (j['light'] as num).toDouble(),
        soilHumidity: (j['soil_humidity'] as num).toDouble(),
        airHumidity: (j['air_humidity'] as num).toDouble(),
        temperature: (j['temperature'] as num).toDouble(),
      );
}

class SensitivityAssessment {
  const SensitivityAssessment({
    required this.light,
    required this.soilHumidity,
    required this.airHumidity,
    required this.temperature,
  });

  final String light;
  final String soilHumidity;
  final String airHumidity;
  final String temperature;

  factory SensitivityAssessment.fromJson(Map<String, dynamic> j) =>
      SensitivityAssessment(
        light: j['light'] as String,
        soilHumidity: j['soil_humidity'] as String,
        airHumidity: j['air_humidity'] as String,
        temperature: j['temperature'] as String,
      );
}

class FaqItem {
  const FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;

  factory FaqItem.fromJson(Map<String, dynamic> j) => FaqItem(
        question: j['question'] as String,
        answer: j['answer'] as String,
      );
}

class CareProfile {
  const CareProfile({
    required this.speciesId,
    required this.scientificName,
    required this.commonName,
    required this.family,
    required this.careRanges,
    this.careWeights,
    this.sensitivityAssessment,
    required this.careSummary,
    required this.aiPersonalityPrompt,
    required this.careTips,
    required this.funFacts,
    required this.faq,
    required this.proposalConfidence,
    required this.needsReview,
    required this.language,
    required this.cached,
  });

  final String speciesId;
  final String scientificName;
  final String commonName;
  final String family;
  final CareRanges careRanges;
  final CareWeights? careWeights;
  final SensitivityAssessment? sensitivityAssessment;
  final String careSummary;
  final String aiPersonalityPrompt;
  final List<String> careTips;
  final List<String> funFacts;
  final List<FaqItem> faq;
  final String proposalConfidence;
  final bool needsReview;
  final String language;
  final bool cached;

  factory CareProfile.fromJson(Map<String, dynamic> j) {
    final cwRaw = j['care_weights'] as Map<String, dynamic>?;
    final saRaw = j['sensitivity_assessment'] as Map<String, dynamic>?;
    return CareProfile(
      speciesId: j['species_id'] as String? ?? '',
      scientificName: j['scientific_name'] as String? ?? '',
      commonName: j['common_name'] as String? ?? '',
      family: j['family'] as String? ?? '',
      careRanges: CareRanges.fromJson(j['care_ranges'] as Map<String, dynamic>),
      careWeights: cwRaw != null ? CareWeights.fromJson(cwRaw) : null,
      sensitivityAssessment:
          saRaw != null ? SensitivityAssessment.fromJson(saRaw) : null,
      careSummary: j['care_summary'] as String? ?? '',
      aiPersonalityPrompt: j['ai_personality_prompt'] as String? ?? '',
      careTips: (j['care_tips'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      funFacts:
          (j['fun_facts'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      faq: (j['faq'] as List?)
              ?.map((e) => FaqItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      proposalConfidence: j['proposal_confidence'] as String? ?? 'low',
      needsReview: j['needs_review'] as bool? ?? false,
      language: j['language'] as String? ?? 'es',
      cached: j['cached'] as bool? ?? false,
    );
  }
}
