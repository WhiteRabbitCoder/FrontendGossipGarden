import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:gossip_garden/features/plants/data/models/identification.dart';

import '../../../../helpers/fixture_loader.dart';

void main() {
  group('NeedsMorePhotos', () {
    test('construye correctamente', () {
      final result = NeedsMorePhotos(reason: 'Baja confianza', topProbability: 0.18);
      expect(result.reason, 'Baja confianza');
      expect(result.topProbability, 0.18);
    });

    test('es subtype de IdentifyResult', () {
      final IdentifyResult result =
          NeedsMorePhotos(reason: 'r', topProbability: 0.1);
      expect(result, isA<NeedsMorePhotos>());
    });
  });

  group('NeedsUserSelection', () {
    test('construye con lista de candidatos', () {
      final candidates = [
        SpeciesCandidate(
          scientificName: 'Monstera deliciosa',
          commonNames: const ['Costilla de Adán'],
          probability: 0.62,
        ),
      ];
      final result = NeedsUserSelection(candidates: candidates);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.first.scientificName, 'Monstera deliciosa');
    });

    test('parsea desde fixture needs_user_selection', () {
      final json = jsonDecode(loadFixture('identify_needs_selection.json'))
          as Map<String, dynamic>;
      final candidates = (json['candidates'] as List)
          .map((e) => SpeciesCandidate.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(candidates, hasLength(3));
      expect(candidates.first.scientificName, 'Monstera deliciosa');
      expect(candidates.first.probability, 0.62);
      expect(candidates.first.commonNames, contains('Costilla de Adán'));
      expect(candidates.first.family, 'Araceae');
      expect(candidates.first.genus, 'Monstera');
      expect(candidates.first.gbifId, 2684241);
      expect(candidates.first.inaturalistId, 119838);
      expect(candidates.first.referenceImages, hasLength(1));

      // Candidato sin image_url ni reference_images
      expect(candidates[1].imageUrl, isNull);
      expect(candidates[1].referenceImages, isEmpty);
    });
  });

  group('IdentifyCompleted', () {
    test('construye con profile y photoStoragePath', () {
      final profile = _buildMinimalCareProfile();
      final result = IdentifyCompleted(
        profile: profile,
        photoStoragePath: 'path/to/photo.jpeg',
      );
      expect(result.profile.scientificName, 'Test species');
      expect(result.photoStoragePath, 'path/to/photo.jpeg');
    });

    test('photoStoragePath puede ser null', () {
      final result = IdentifyCompleted(profile: _buildMinimalCareProfile());
      expect(result.photoStoragePath, isNull);
    });
  });

  group('SpeciesCandidate.fromJson', () {
    test('parsea campos completos', () {
      final json = {
        'scientific_name': 'Dracaena trifasciata',
        'common_names': ['Lengua de suegra', 'Sanseveria'],
        'probability': 0.85,
        'gbif_id': 12345,
        'inaturalist_id': 67890,
        'taxonomy': {'family': 'Asparagaceae', 'genus': 'Dracaena'},
        'description': 'Planta resistente.',
        'image_url': 'https://example.com/img.jpg',
        'reference_images': ['https://ref1.jpg', 'https://ref2.jpg'],
      };

      final candidate = SpeciesCandidate.fromJson(json);

      expect(candidate.scientificName, 'Dracaena trifasciata');
      expect(candidate.commonNames, hasLength(2));
      expect(candidate.probability, 0.85);
      expect(candidate.gbifId, 12345);
      expect(candidate.inaturalistId, 67890);
      expect(candidate.family, 'Asparagaceae');
      expect(candidate.genus, 'Dracaena');
      expect(candidate.description, 'Planta resistente.');
      expect(candidate.imageUrl, 'https://example.com/img.jpg');
      expect(candidate.referenceImages, hasLength(2));
    });

    test('maneja campos ausentes con defaults seguros', () {
      final candidate = SpeciesCandidate.fromJson({});

      expect(candidate.scientificName, '');
      expect(candidate.commonNames, isEmpty);
      expect(candidate.probability, 0.0);
      expect(candidate.gbifId, isNull);
      expect(candidate.inaturalistId, isNull);
      expect(candidate.family, isNull);
      expect(candidate.genus, isNull);
      expect(candidate.referenceImages, isEmpty);
    });

    test('lee taxonomy desde campo de primer nivel como fallback', () {
      final json = {
        'scientific_name': 'Aloe vera',
        'common_names': ['Aloe'],
        'probability': 0.9,
        'family': 'Asphodelaceae',
        'genus': 'Aloe',
      };

      final candidate = SpeciesCandidate.fromJson(json);
      expect(candidate.family, 'Asphodelaceae');
      expect(candidate.genus, 'Aloe');
    });

    test('toJson produce JSON correcto', () {
      const candidate = SpeciesCandidate(
        scientificName: 'Monstera deliciosa',
        commonNames: ['Costilla de Adán'],
        probability: 0.62,
        gbifId: 2684241,
        family: 'Araceae',
        genus: 'Monstera',
      );

      final json = candidate.toJson();

      expect(json['scientific_name'], 'Monstera deliciosa');
      expect(json['probability'], 0.62);
      expect(json['gbif_id'], 2684241);
      expect(json['taxonomy']['family'], 'Araceae');
      expect(json['taxonomy']['genus'], 'Monstera');
    });
  });

  group('CareRanges.fromJson', () {
    test('parsea todos los rangos correctamente', () {
      final json = {
        'min_temp_c': 18.0,
        'max_temp_c': 27.0,
        'min_light_lux': 500.0,
        'max_light_lux': 2000.0,
        'min_air_humidity_pct': 40.0,
        'max_air_humidity_pct': 70.0,
        'min_soil_humidity_pct': 30.0,
        'max_soil_humidity_pct': 60.0,
      };

      final ranges = CareRanges.fromJson(json);

      expect(ranges.minTempC, 18.0);
      expect(ranges.maxTempC, 27.0);
      expect(ranges.minLightLux, 500.0);
      expect(ranges.maxLightLux, 2000.0);
      expect(ranges.minAirHumidityPct, 40.0);
      expect(ranges.maxAirHumidityPct, 70.0);
      expect(ranges.minSoilHumidityPct, 30.0);
      expect(ranges.maxSoilHumidityPct, 60.0);
    });

    test('acepta int y convierte a double', () {
      final json = {
        'min_temp_c': 15,
        'max_temp_c': 30,
        'min_light_lux': 5000,
        'max_light_lux': 10000,
        'min_air_humidity_pct': 30,
        'max_air_humidity_pct': 50,
        'min_soil_humidity_pct': 20,
        'max_soil_humidity_pct': 40,
      };

      final ranges = CareRanges.fromJson(json);
      expect(ranges.minTempC, 15.0);
      expect(ranges.minTempC, isA<double>());
    });
  });

  group('CareWeights.fromJson', () {
    test('parsea pesos correctamente', () {
      final json = {
        'light': 0.40,
        'soil_humidity': 0.35,
        'air_humidity': 0.05,
        'temperature': 0.20,
      };

      final weights = CareWeights.fromJson(json);

      expect(weights.light, 0.40);
      expect(weights.soilHumidity, 0.35);
      expect(weights.airHumidity, 0.05);
      expect(weights.temperature, 0.20);
    });
  });

  group('SensitivityAssessment.fromJson', () {
    test('parsea sensibilidades', () {
      final json = {
        'light': 'high',
        'soil_humidity': 'high',
        'air_humidity': 'low',
        'temperature': 'medium',
      };

      final sa = SensitivityAssessment.fromJson(json);

      expect(sa.light, 'high');
      expect(sa.soilHumidity, 'high');
      expect(sa.airHumidity, 'low');
      expect(sa.temperature, 'medium');
    });
  });

  group('CareProfile.fromJson', () {
    test('parsea desde fixture identify_completed', () {
      final json = jsonDecode(loadFixture('identify_completed.json'))
          as Map<String, dynamic>;
      final profile = CareProfile.fromJson(json['profile'] as Map<String, dynamic>);

      expect(profile.speciesId, 'species789-uuid');
      expect(profile.scientificName, 'Monstera deliciosa');
      expect(profile.commonName, 'Costilla de Adán');
      expect(profile.family, 'Araceae');
      expect(profile.proposalConfidence, 'high');
      expect(profile.needsReview, isFalse);
      expect(profile.language, 'es');
      expect(profile.cached, isFalse);
      expect(profile.careTips, hasLength(2));
      expect(profile.funFacts, hasLength(2));
      expect(profile.faq, hasLength(2));
      expect(profile.careWeights, isNotNull);
      expect(profile.careWeights!.light, 0.30);
      expect(profile.sensitivityAssessment, isNotNull);
      expect(profile.sensitivityAssessment!.soilHumidity, 'high');
    });

    test('maneja care_weights null (fichas legacy)', () {
      final json = {
        'species_id': 'id123',
        'scientific_name': 'Aloe vera',
        'common_name': 'Aloe',
        'family': 'Asphodelaceae',
        'care_ranges': {
          'min_temp_c': 15.0, 'max_temp_c': 30.0,
          'min_light_lux': 500.0, 'max_light_lux': 2000.0,
          'min_air_humidity_pct': 30.0, 'max_air_humidity_pct': 50.0,
          'min_soil_humidity_pct': 20.0, 'max_soil_humidity_pct': 40.0,
        },
        'care_summary': 'Resumen.',
        'ai_personality_prompt': 'Prompt.',
        'proposal_confidence': 'medium',
        'needs_review': true,
        'language': 'es',
        'cached': true,
        // care_weights y sensitivity_assessment ausentes
      };

      final profile = CareProfile.fromJson(json);

      expect(profile.careWeights, isNull);
      expect(profile.sensitivityAssessment, isNull);
      expect(profile.needsReview, isTrue);
      expect(profile.cached, isTrue);
    });

    test('defaults seguros para campos opcionales', () {
      final json = {
        'care_ranges': {
          'min_temp_c': 0.0, 'max_temp_c': 0.0,
          'min_light_lux': 0.0, 'max_light_lux': 0.0,
          'min_air_humidity_pct': 0.0, 'max_air_humidity_pct': 0.0,
          'min_soil_humidity_pct': 0.0, 'max_soil_humidity_pct': 0.0,
        },
      };

      final profile = CareProfile.fromJson(json);

      expect(profile.speciesId, '');
      expect(profile.careTips, isEmpty);
      expect(profile.funFacts, isEmpty);
      expect(profile.faq, isEmpty);
      expect(profile.language, 'es');
      expect(profile.proposalConfidence, 'low');
    });
  });

  group('FaqItem.fromJson', () {
    test('parsea pregunta y respuesta', () {
      final item = FaqItem.fromJson({
        'question': '¿Con qué frecuencia regarla?',
        'answer': 'Cada 7-10 días.',
      });

      expect(item.question, '¿Con qué frecuencia regarla?');
      expect(item.answer, 'Cada 7-10 días.');
    });
  });
}

CareProfile _buildMinimalCareProfile() => CareProfile(
      speciesId: 'test-id',
      scientificName: 'Test species',
      commonName: 'Test',
      family: 'Testaceae',
      careRanges: const CareRanges(
        minTempC: 18, maxTempC: 27,
        minLightLux: 500, maxLightLux: 2000,
        minAirHumidityPct: 40, maxAirHumidityPct: 70,
        minSoilHumidityPct: 30, maxSoilHumidityPct: 60,
      ),
      careSummary: 'Resumen.',
      aiPersonalityPrompt: 'Prompt.',
      careTips: const [],
      funFacts: const [],
      faq: const [],
      proposalConfidence: 'high',
      needsReview: false,
      language: 'es',
      cached: false,
    );
