import '../../data/models/plant_enums.dart';

extension PlantMoodX on PlantMood {
  String get emoji {
    switch (this) {
      case PlantMood.happy: return '😊';
      case PlantMood.thirsty: return '🥺';
      case PlantMood.cold: return '🥶';
      case PlantMood.hot: return '🥵';
      case PlantMood.stressed: return '😰';
      case PlantMood.perfect: return '✨';
    }
  }

  String get label {
    switch (this) {
      case PlantMood.happy: return 'Feliz';
      case PlantMood.thirsty: return 'Sedienta';
      case PlantMood.cold: return 'Con frío';
      case PlantMood.hot: return 'Acalorada';
      case PlantMood.stressed: return 'Estresada';
      case PlantMood.perfect: return 'Radiante';
    }
  }
}

extension ConfidenceLevelX on ConfidenceLevel {
  String get label {
    switch (this) {
      case ConfidenceLevel.high: return 'Alta precisión';
      case ConfidenceLevel.medium: return 'Media precisión';
      case ConfidenceLevel.low: return 'Baja precisión';
    }
  }
}