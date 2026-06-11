import 'package:flutter/material.dart';

import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';

class GardenPlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback? onTap;
  final bool showChevron;

  const GardenPlantCard({
    super.key,
    required this.plant,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = plant.sensorStatus == SensorStatus.online;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GardenColors.creamPaper),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: GardenColors.creamLight,
                    ),
                    child: plant.image.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              plant.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => GardenIcon(
                                asset: GardenIcons.plantAssetForSpecies(plant.species),
                                size: 26,
                              ),
                            ),
                          )
                        : GardenIcon(
                            asset: GardenIcons.plantAssetForSpecies(plant.species),
                            size: 26,
                          ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: GardenColors.creamPaper,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: GardenIcon(
                          asset: isOnline
                              ? GardenIcons.wifi
                              : GardenIcons.sensorOffline,
                          size: 10,
                          opacity: isOnline ? 1.0 : 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plant.name,
                            style: GardenTextStyles.title.copyWith(
                              color: GardenColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GardenMoodBadge(mood: plant.mood),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plant.species,
                            style: GardenTextStyles.bodySmall.copyWith(
                              color: GardenColors.inkSoft,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GardenPersonalityTag(personality: plant.personality),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: plant.health / 100,
                              minHeight: 6,
                              backgroundColor: _healthBgColor(plant.health),
                              color: _healthColor(plant.health),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${plant.health.toInt()}%',
                          style: GardenTextStyles.label.copyWith(
                            color: GardenColors.inkSoft,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showChevron && onTap != null) ...[
                const SizedBox(width: 8),
                const GardenIcon(
                  asset: GardenIcons.forward,
                  size: 22,
                  opacity: 0.6,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _healthColor(double health) {
    if (health >= 90) return GardenColors.leafDark;
    if (health >= 70) return GardenColors.leafGreen;
    return GardenColors.heartRed;
  }

  static Color _healthBgColor(double health) {
    if (health >= 70) return GardenColors.creamLight;
    return const Color(0xFFF6E8E8);
  }

}

class GardenMoodBadge extends StatelessWidget {
  final PlantMood mood;

  const GardenMoodBadge({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _style(mood);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
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
    }
  }
}

class GardenPersonalityTag extends StatelessWidget {
  final PlantPersonality personality;

  const GardenPersonalityTag({super.key, required this.personality});

  @override
  Widget build(BuildContext context) {
    final (label, bg) = _style(personality);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GardenTextStyles.label.copyWith(
          fontSize: 10,
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
