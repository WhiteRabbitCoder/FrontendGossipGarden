import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../providers/chat_providers.dart';
import '../providers/navigation_provider.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mensajes',
                            style: GardenTextStyles.display.copyWith(
                              color: GardenColors.ink,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Tus plantas quieren hablar contigo',
                            style: GardenTextStyles.bodySmall
                                .copyWith(color: GardenColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          plantsAsync.when(
            data: (plants) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == plants.length) return const SizedBox(height: 120);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ChatCard(
                      plant: plants[index],
                      ref: ref,
                      onTap: () => navNotifier.openChat(plants[index].id),
                    ),
                  );
                },
                childCount: plants.length + 1,
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: GardenColors.leafGreen))),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                  child: Text('Error: $e',
                      style: GardenTextStyles.bodySmall)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final Plant plant;
  final WidgetRef ref;
  final VoidCallback onTap;
  const _ChatCard(
      {required this.plant, required this.ref, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final messages = ref.read(chatMessagesProvider(plant.id));
    final hasUnread = messages.isNotEmpty && messages.last.sender == 'plant';
    final lastMessage =
        messages.isNotEmpty ? messages.last.content : 'Sin mensajes recientes';
    final unreadCount =
        hasUnread ? (plant.id == '1' || plant.id == '3' ? 2 : 0) : 0;

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
                        color: GardenColors.creamLight,
                        shape: BoxShape.circle),
                    child: GardenIcon(
                      asset: GardenIcons.plantAssetForSpecies(plant.species),
                      size: 26,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      left: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                            color: GardenColors.leafDark,
                            shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800),
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
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MoodBadge(mood: plant.mood),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GardenTextStyles.bodySmall.copyWith(
                          color: GardenColors.inkSoft, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const GardenIcon(
                asset: GardenIcons.forward,
                size: 22,
                opacity: 0.6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  final PlantMood mood;
  const _MoodBadge({required this.mood});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _style(mood);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  static (String, Color, Color) _style(PlantMood m) {
    switch (m) {
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
