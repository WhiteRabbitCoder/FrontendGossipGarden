import 'package:flutter/material.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

class PlantFeedCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final bool isCelebrating;

  const PlantFeedCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.isCelebrating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GardenColors.dustLight),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Ícono de planta ────────────────────────────────────────
                Hero(
                  tag: 'plantHero_${plant.id}',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GardenColors.sageLight,
                    ),
                    child: plant.image.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              plant.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                _getPlantIcon(plant.species),
                                color: GardenColors.forest,
                                size: 26,
                              ),
                            ),
                          )
                        : Icon(
                            _getPlantIcon(plant.species),
                            color: GardenColors.forest,
                            size: 26,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // ── Nombre + badge + insight ───────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              plant.name,
                              style: GardenTextStyles.title.copyWith(
                                color: GardenColors.charcoal,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _MoodBadge(mood: plant.mood),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plant.insights.isNotEmpty
                            ? plant.insights.first
                            : 'Todo está bien.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GardenTextStyles.bodySmall.copyWith(
                          color: GardenColors.dust,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ── Chevron ────────────────────────────────────────────────
                const Icon(
                  Icons.chevron_right_rounded,
                  color: GardenColors.dust,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPlantIcon(String species) {
    final lower = species.toLowerCase();
    if (lower.contains('echeveria') || lower.contains('suculenta')) {
      return Icons.local_florist_outlined;
    }
    if (lower.contains('ficus')) {
      return Icons.park_outlined;
    }
    return Icons.eco_outlined;
  }
}

// ── Mood Badge ────────────────────────────────────────────────────────────────

class _MoodBadge extends StatelessWidget {
  final PlantMood mood;

  const _MoodBadge({required this.mood});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = _moodStyle(mood);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (String, Color, Color) _moodStyle(PlantMood mood) {
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
    }
  }
}
