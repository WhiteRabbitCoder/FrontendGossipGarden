import 'package:flutter/material.dart';

import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import 'plant_badges.dart';

class GardenPlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback? onTap;
  const GardenPlantCard({
    super.key,
    required this.plant,
    this.onTap,
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
                        PlantMoodBadge(mood: plant.mood, horizontalPadding: 8, fontSize: 10),
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
                        PlantPersonalityTag(personality: plant.personality),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: plant.health != null ? plant.health! / 100 : 0.0,
                              minHeight: 6,
                              backgroundColor: _healthBgColor(plant.health),
                              color: _healthColor(plant.health),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          plant.health != null ? '${plant.health!.toInt()}%' : 'N/A',
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
            ],
          ),
        ),
      ),
    );
  }

  static Color _healthColor(double? health) {
    if (health == null) return GardenColors.dust;
    if (health >= 90) return GardenColors.leafDark;
    if (health >= 70) return GardenColors.leafGreen;
    return GardenColors.heartRed;
  }

  static Color _healthBgColor(double? health) {
    if (health == null) return GardenColors.dustLight;
    if (health >= 70) return GardenColors.creamLight;
    return const Color(0xFFF6E8E8);
  }

}

