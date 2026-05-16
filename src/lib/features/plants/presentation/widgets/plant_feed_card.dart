import 'package:flutter/material.dart';
import '../../data/models/plant.dart';
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
    final bool hasAlert = plant.insights.isNotEmpty && plant.insights.first != 'Todo esta bien';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: GardenColors.parchment,
          borderRadius: BorderRadius.circular(36), // Más redondo, estilo crayola/orgánico
          border: Border.all(
            color: hasAlert ? GardenColors.errorRose.withValues(alpha: 0.3) : GardenColors.sageLight,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: GardenColors.forest.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(36),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Hero(
                    tag: 'plantHero_${plant.id}',
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasAlert ? GardenColors.errorRose.withValues(alpha: 0.1) : GardenColors.sageLight,
                        border: Border.all(
                          color: hasAlert ? GardenColors.errorRose.withValues(alpha: 0.5) : GardenColors.sage,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: plant.image.isNotEmpty
                          ? Image.network(
                              plant.image,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.park_rounded, color: hasAlert ? GardenColors.errorRose : GardenColors.moss, size: 32),
                            )
                          : Icon(Icons.park_rounded, color: hasAlert ? GardenColors.errorRose : GardenColors.moss, size: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                plant.name,
                                style: GardenTextStyles.title.copyWith(
                                  color: GardenColors.charcoal,
                                  fontSize: 22,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (hasAlert)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: GardenColors.errorRose,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plant.insights.isNotEmpty
                              ? plant.insights.first
                              : 'Todo esta bien',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GardenTextStyles.bodySmall.copyWith(
                            color: hasAlert ? GardenColors.errorRose : GardenColors.dust,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: GardenColors.dust,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
