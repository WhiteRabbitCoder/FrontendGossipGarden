import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../providers/chat_providers.dart';
import '../providers/navigation_provider.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    return Scaffold(
      backgroundColor: GardenColors.cream,
      appBar: AppBar(
        title: Text('Murmullos', style: GardenTextStyles.display.copyWith(color: GardenColors.forest, fontSize: 32)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: GardenColors.sageLight,
              shape: BoxShape.circle,
              border: Border.all(color: GardenColors.sage, width: 2),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: GardenColors.forest),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: plantsAsync.when(
        data: (plants) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plants.length + 1, // +1 para el espacio del nav
          itemBuilder: (context, index) {
            if (index == plants.length) {
              return const SizedBox(height: 120); // Espacio para el nav flotante
            }
            return _buildChatItem(context, ref, plants[index], navNotifier);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: GardenColors.moss)),
        error: (e, _) => Center(child: Text('Error: $e', style: GardenTextStyles.bodySmall)),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, WidgetRef ref, Plant plant,
      NavigationNotifier nav) {
    final messages = ref.read(chatMessagesProvider(plant.id));
    final lastMessage =
        messages.isNotEmpty ? messages.last.content : 'Sin murmullos recientes';
    final isOnline = plant.sensorStatus == SensorStatus.online;
    final unread = messages.isNotEmpty && messages.last.sender == 'plant';

    return GestureDetector(
      onTap: () => nav.openChat(plant.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GardenColors.parchment,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: GardenColors.sageLight, width: 2),
          boxShadow: [
            BoxShadow(
              color: GardenColors.forest.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GardenColors.sageLight,
                    border: Border.all(color: GardenColors.sage, width: 2),
                  ),
                  child: plant.image.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            plant.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.park_rounded, color: GardenColors.forest),
                          ),
                        )
                      : const Icon(Icons.park_rounded, size: 30, color: GardenColors.forest),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: GardenColors.okGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: GardenColors.parchment, width: 2),
                      ),
                    ),
                  ),
              ],
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
                          style: GardenTextStyles.title.copyWith(fontSize: 18, color: GardenColors.charcoal),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(messages.isNotEmpty
                            ? messages.last.timestamp
                            : DateTime.now()),
                        style: GardenTextStyles.label.copyWith(fontSize: 12, color: GardenColors.dust),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: GardenTextStyles.bodySmall.copyWith(
                      fontSize: 14,
                      color: unread ? GardenColors.forest : GardenColors.dust,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _moodColor(plant.mood).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _moodColor(plant.mood).withOpacity(0.3)),
                        ),
                        child: Text(
                          plant.mood.name.toUpperCase(),
                          style: GardenTextStyles.label.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _moodColor(plant.mood),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: GardenColors.sageLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: GardenColors.sage),
                        ),
                        child: Text(
                          '${plant.health.toInt()}% salud',
                          style: GardenTextStyles.label.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: GardenColors.forest,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (unread)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: GardenColors.forest,
                            shape: BoxShape.circle,
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
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }

  Color _moodColor(PlantMood mood) {
    switch (mood) {
      case PlantMood.happy:
        return GardenColors.moss;
      case PlantMood.thirsty:
        return GardenColors.golden;
      case PlantMood.stressed:
        return GardenColors.errorRose;
      case PlantMood.cold:
        return GardenColors.waterBlue;
      case PlantMood.hot:
        return GardenColors.earth;
      case PlantMood.perfect:
        return GardenColors.forest;
      default:
        return GardenColors.dust;
    }
  }
}
