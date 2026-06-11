import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friend_garden_providers.dart';
import '../widgets/garden_plant_card.dart';
import 'achievement_detail_screen.dart';
import 'profile_settings_screen.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';

// HARDCODE(demo): consume friendGardenProvider (datos de Mateo). TODO(backend): jardín por friendId real.
class FriendGardenScreen extends ConsumerWidget {
  final String friendId;
  final VoidCallback onBack;

  const FriendGardenScreen({
    super.key,
    required this.friendId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garden = ref.watch(friendGardenProvider(friendId));

    if (garden == null) {
      return Scaffold(
        backgroundColor: GardenColors.creamPaper,
        appBar: AppBar(
          leading: IconButton(
            icon: const GardenIcon(asset: GardenIcons.back, size: 20),
            onPressed: onBack,
          ),
          title: const Text('Jardín del amigo'),
        ),
        body: const Center(child: Text('No se encontró este jardín.')),
      );
    }

    final unlockedCount =
        garden.achievements.where((a) => a.unlocked).length;

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const GardenIcon(asset: GardenIcons.back, size: 20),
                      onPressed: onBack,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: GardenColors.creamLight,
                                child: Text(
                                  garden.displayName[0].toUpperCase(),
                                  style: GardenTextStyles.title.copyWith(
                                    color: GardenColors.leafDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Jardín de ${garden.displayName}',
                                  style: GardenTextStyles.display.copyWith(
                                    color: GardenColors.ink,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 46),
                            child: Text(
                              '${garden.featuredPlants.length} plantas en su colección · $unlockedCount logros',
                              style: GardenTextStyles.bodySmall.copyWith(
                                color: GardenColors.inkSoft,
                              ),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GardenColors.leafGreen),
                ),
                child: Row(
                  children: [
                    const GardenIcon(asset: GardenIcons.eyeOpen, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Estás viendo el jardín de ${garden.displayName}. '
                        'Explora sus plantas destacadas y logros.',
                        style: GardenTextStyles.bodySmall.copyWith(
                          color: GardenColors.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                'Plantas destacadas',
                style: GardenTextStyles.title.copyWith(
                  color: GardenColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final plant = garden.featuredPlants[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: GardenPlantCard(
                    plant: plant,
                    showChevron: false,
                  ),
                );
              },
              childCount: garden.featuredPlants.length,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logros de ${garden.displayName}',
                    style: GardenTextStyles.title.copyWith(
                      color: GardenColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: garden.achievements.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final progress = garden.achievements[index];
                        return AchievementCard(
                          progress: progress,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AchievementDetailScreen(
                                  progress: progress,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
