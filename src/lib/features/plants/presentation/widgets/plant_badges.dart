import 'package:flutter/material.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

/// Badge de humor de planta. Compartido entre dashboard, jardín, chat y perfil.
class PlantMoodBadge extends StatelessWidget {
  final PlantMood mood;
  /// Padding horizontal. Por defecto 10, se puede reducir a 8 para vistas compactas.
  final double horizontalPadding;
  /// Tamaño de fuente. Por defecto 11.
  final double fontSize;

  const PlantMoodBadge({
    super.key,
    required this.mood,
    this.horizontalPadding = 10,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _style(mood);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (String, Color, Color) _style(PlantMood mood) {
    switch (mood) {
      case PlantMood.thirsty:
        return ('Sedienta', const Color(0xFFFFEDED), const Color(0xFFD94040));
      case PlantMood.stressed:
        return ('Estresada', const Color(0xFFFFF1E0), const Color(0xFFB85C00));
      case PlantMood.cold:
        return ('Fría', const Color(0xFFE0F0FF), const Color(0xFF2563EB));
      case PlantMood.hot:
        return ('Acalorada', const Color(0xFFFFF1E0), const Color(0xFFB85C00));
      case PlantMood.perfect:
      case PlantMood.happy:
        return ('Óptimo', const Color(0xFFE6F4EA), const Color(0xFF2E7D32));
      case PlantMood.offline:
        return ('Sin conexión', const Color(0xFFE5E2DC), const Color(0xFF8E8278)); // GardenColors.dustLight and GardenColors.dust
    }
  }
}

/// Badge de personalidad de planta. Compartido entre jardín y perfil.
class PlantPersonalityTag extends StatelessWidget {
  final PlantPersonality personality;
  final double horizontalPadding;
  final double fontSize;

  const PlantPersonalityTag({
    super.key,
    required this.personality,
    this.horizontalPadding = 8,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final (label, bg) = _style(personality);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GardenTextStyles.label.copyWith(
          fontSize: fontSize,
          color: GardenColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (String, Color) _style(PlantPersonality p) {
    switch (p) {
      case PlantPersonality.dramatic:
        return ('🎭 La dramática', const Color(0xFFFFEDF4));
      case PlantPersonality.wise:
        return ('🧘 La zen', const Color(0xFFE8F5E9));
      case PlantPersonality.playful:
        return ('🎩 El filósofo', const Color(0xFFF3E8FF));
    }
  }
}
