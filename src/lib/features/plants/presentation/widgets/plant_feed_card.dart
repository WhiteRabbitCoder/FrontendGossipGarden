import 'package:flutter/material.dart';
import '../../data/models/plant.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import 'plant_badges.dart';

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
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GardenColors.dustLight, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: GardenColors.ink.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
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
                      color: GardenColors.creamLight,
                      border: Border.all(color: GardenColors.dustLight),
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
                                color: GardenColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PlantMoodBadge(mood: plant.mood),
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
                          color: GardenColors.inkSoft,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta compacta para la vista en cuadrícula del dashboard.
class PlantFeedGridCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const PlantFeedGridCard({
    super.key,
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GardenColors.dustLight, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: GardenColors.ink.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Hero(
                  tag: 'plantHero_${plant.id}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GardenColors.creamLight,
                      border: Border.all(color: GardenColors.dustLight),
                    ),
                    child: plant.image.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              plant.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => GardenIcon(
                                asset: GardenIcons.plantAssetForSpecies(plant.species),
                                size: 28,
                              ),
                            ),
                          )
                        : GardenIcon(
                            asset: GardenIcons.plantAssetForSpecies(plant.species),
                            size: 28,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                plant.name,
                style: GardenTextStyles.title.copyWith(
                  color: GardenColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              PlantMoodBadge(mood: plant.mood, horizontalPadding: 10, fontSize: 11),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  plant.insights.isNotEmpty
                      ? plant.insights.first
                      : 'Todo está bien.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GardenTextStyles.bodySmall.copyWith(
                    color: GardenColors.inkSoft,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

