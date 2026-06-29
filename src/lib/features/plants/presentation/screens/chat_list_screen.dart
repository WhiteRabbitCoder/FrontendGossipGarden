import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../providers/chat_providers.dart';
import '../providers/navigation_provider.dart';
import '../../data/models/plant.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import '../widgets/plant_badges.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
    final messagesAsync = ref.watch(chatMessagesProvider(plant.id));
    final messages = messagesAsync.value ?? [];
    final hasUnread = messages.isNotEmpty && messages.last.sender == 'plant';
    final lastMessage =
        messages.isNotEmpty ? messages.last.content : 'Sin mensajes recientes';
    final unreadCount =
        hasUnread ? (plant.id == '1' || plant.id == '3' ? 2 : 0) : 0;
        
    final sensorAsync = ref.watch(plantRealtimeSensorProvider(plant.id));
    final lastDataTime = sensorAsync.value?.timestamp;
    
    String formatTimeAgo(DateTime? time) {
      if (time == null) return 'Sin datos';
      final diff = DateTime.now().difference(time);
      if (diff.inDays > 0) return 'Hace ${diff.inDays}d';
      if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
      if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes}m';
      return 'Ahora';
    }
    
    String getPersonality(dynamic p) {
      final str = p.toString().toLowerCase();
      if (str.contains('wise')) return 'Sabia';
      if (str.contains('playful')) return 'Juguetona';
      if (str.contains('dramatic')) return 'Dramática';
      return 'Tranquila';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: GardenColors.creamSolid,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GardenColors.ink, width: 2),
          boxShadow: const [
            BoxShadow(
              color: GardenColors.ink,
              blurRadius: 0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: GardenColors.creamPaper,
                    shape: BoxShape.circle,
                    border: Border.all(color: GardenColors.ink, width: 1.5),
                    image: plant.image.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(plant.image),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: plant.image.isEmpty
                      ? GardenIcon(
                          asset: GardenIcons.plantAssetForSpecies(plant.species),
                          size: 30,
                        )
                      : null,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: GardenColors.potOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: GardenColors.ink, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                              color: GardenColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w900),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          plant.name,
                          style: GardenTextStyles.title.copyWith(
                              color: GardenColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formatTimeAgo(lastDataTime),
                        style: GardenTextStyles.label.copyWith(
                          fontSize: 11,
                          color: GardenColors.leafDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GardenColors.sageLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GardenColors.ink, width: 1),
                        ),
                        child: Text(
                          getPersonality(plant.personality),
                          style: GardenTextStyles.label.copyWith(
                            fontSize: 10,
                            color: GardenColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PlantMoodBadge(mood: plant.mood),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GardenTextStyles.bodySmall.copyWith(
                        color: GardenColors.inkSoft, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

