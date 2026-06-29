import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/plant.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import '../providers/chat_providers.dart';
import 'plant_badges.dart';

class PlantFeedCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(plant.id));
    final messages = messagesAsync.value ?? [];
    final lastMessage = messages.isNotEmpty 
        ? messages.last.content 
        : '¡Envía tu primer mensaje!';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: GardenColors.creamLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GardenColors.ink, width: 1.5),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Ícono de planta ────────────────────────────────────────
                Hero(
                  tag: 'plantHero_${plant.id}',
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: GardenColors.creamPaper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GardenColors.ink, width: 1.2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: plant.image.isNotEmpty
                          ? Image.network(
                              plant.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: GardenIcon(
                                  asset: GardenIcons.plantAssetForSpecies(plant.species),
                                  size: 44,
                                ),
                              ),
                            )
                          : Center(
                              child: GardenIcon(
                                asset: GardenIcons.plantAssetForSpecies(plant.species),
                                size: 44,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // ── Nombre + badge + insight ───────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        plant.name,
                        style: GardenTextStyles.title.copyWith(
                          color: GardenColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Transform.translate(
                            offset: const Offset(-10, 0),
                            child: PlantMoodBadge(mood: plant.mood),
                          ),
                          if (plant.health != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('💚', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  '${plant.health!.toInt()}%',
                                  style: GardenTextStyles.label.copyWith(
                                    color: GardenColors.inkSoft,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GardenTextStyles.bodySmall.copyWith(
                          color: GardenColors.inkSoft,
                          fontSize: 13,
                          height: 1.2,
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
class PlantFeedGridCard extends ConsumerWidget {
  final Plant plant;
  final VoidCallback onTap;

  const PlantFeedGridCard({
    super.key,
    required this.plant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(plant.id));
    final messages = messagesAsync.value ?? [];
    final lastMessage = messages.isNotEmpty 
        ? messages.last.content 
        : '¡Envía tu primer mensaje!';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: GardenColors.creamLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GardenColors.ink, width: 1.5),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Hero(
                  tag: 'plantHero_${plant.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: GardenColors.creamLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GardenColors.ink, width: 1.2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: plant.image.isNotEmpty
                          ? Image.network(
                              plant.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: GardenIcon(
                                  asset: GardenIcons.plantAssetForSpecies(plant.species),
                                  size: 40,
                                ),
                              ),
                            )
                          : Center(
                              child: GardenIcon(
                                asset: GardenIcons.plantAssetForSpecies(plant.species),
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plant.name,
                            style: GardenTextStyles.title.copyWith(
                              color: GardenColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        PlantMoodBadge(mood: plant.mood, horizontalPadding: 6, fontSize: 10),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GardenTextStyles.bodySmall.copyWith(
                        color: GardenColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

