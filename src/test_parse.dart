import 'dart:convert';
import 'package:gossip_garden/features/plants/data/models/identification_dto.dart';

void main() {
  const jsonStr = '''
  {
    "status": "completed",
    "profile": {
      "species_id": "1d0d1fb1-0ce8-4f29-9760-f409aaffb4d4",
      "scientific_name": "Anthemis cotula",
      "common_name": "manzanilla hedionda",
      "family": "Asteraceae",
      "care_ranges": {
        "min_temp_c": 4.0,
        "max_temp_c": 32.0,
        "min_light_lux": 12000.0,
        "max_light_lux": 85000.0,
        "min_air_humidity_pct": 30.0,
        "max_air_humidity_pct": 75.0,
        "min_soil_humidity_pct": 18.0,
        "max_soil_humidity_pct": 55.0
      },
      "care_weights": {
        "light": 0.35,
        "soil_humidity": 0.3,
        "air_humidity": 0.15,
        "temperature": 0.2
      },
      "sensitivity_assessment": {
        "light": "high",
        "soil_humidity": "medium",
        "air_humidity": "low",
        "temperature": "low"
      },
      "eval_intervals": {
        "temperature": 240,
        "light": 120,
        "air_humidity": 480,
        "soil_humidity": 180
      },
      "care_summary": "Anthemis cotula es una anual...",
      "ai_personality_prompt": "1. IDENTIDAD...",
      "care_tips": ["Colócala en exterior"],
      "fun_facts": ["Su nombre común"],
      "faq": [{"question": "¿Sirve para té?", "answer": "No."}],
      "proposal_confidence": "medium",
      "needs_review": false,
      "language": "es",
      "cached": true,
      "created_at": "2026-06-24T16:58:07.706476Z"
    },
    "photo_storage_path": null
  }
  ''';

  try {
    final parsed = jsonDecode(jsonStr);
    final response = IdentifyResponse.fromJson(parsed);
    print("Success! Status: \${response.status}");
  } catch (e, stack) {
    print("Error: \$e");
    print(stack);
  }
}
