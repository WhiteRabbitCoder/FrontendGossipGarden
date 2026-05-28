import 'package:flutter/widgets.dart';
import '../../data/models/plant_enums.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

extension PlantMoodX on PlantMood {
  IconData get icon {
    switch (this) {
      case PlantMood.happy:
        return FontAwesomeIcons.faceSmile;
      case PlantMood.thirsty:
        return FontAwesomeIcons.droplet;
      case PlantMood.cold:
        return FontAwesomeIcons.snowflake;
      case PlantMood.hot:
        return FontAwesomeIcons.temperatureHigh;
      case PlantMood.stressed:
        return FontAwesomeIcons.triangleExclamation;
      case PlantMood.perfect:
        return FontAwesomeIcons.solidStar;
    }
  }

  String get label {
    switch (this) {
      case PlantMood.happy:
        return 'Feliz';
      case PlantMood.thirsty:
        return 'Sedienta';
      case PlantMood.cold:
        return 'Con frío';
      case PlantMood.hot:
        return 'Acalorada';
      case PlantMood.stressed:
        return 'Estresada';
      case PlantMood.perfect:
        return 'Radiante';
    }
  }
}

extension ConfidenceLevelX on ConfidenceLevel {
  String get label {
    switch (this) {
      case ConfidenceLevel.high:
        return 'Alta precisión';
      case ConfidenceLevel.medium:
        return 'Media precisión';
      case ConfidenceLevel.low:
        return 'Baja precisión';
    }
  }
}
