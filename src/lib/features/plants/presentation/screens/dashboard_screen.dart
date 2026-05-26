import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';
import '../providers/plant_providers.dart';
import '../widgets/plant_feed_card.dart';
import '../widgets/summary_banner.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(String) onSelectPlant;
  final Function(String) onOpenChat;
  final Function(String) onOpenFriendGarden;

  const DashboardScreen({
    super.key,
    required this.onSelectPlant,
    required this.onOpenChat,
    required this.onOpenFriendGarden,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final authSession = ref.watch(authStateProvider).value;
    final displayName = authSession?.profile?.displayName;
    final userName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName
        : (authSession?.profile?.email?.split('@').first ?? 'Jardinero');

    return Scaffold(
      backgroundColor: GardenColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: GardenColors.cream,
            elevation: 0,
            toolbarHeight: 80,
            title: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GardenColors.sageLight,
                    border: Border.all(color: GardenColors.sage, width: 2),
                  ),
                  child: const Icon(Icons.person, color: GardenColors.forest),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, $userName!',
                        style: GardenTextStyles.title.copyWith(color: GardenColors.charcoal, fontSize: 24),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tu jardín está susurrando...',
                        style: GardenTextStyles.bodySmall.copyWith(color: GardenColors.dust, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: GardenColors.forest),
                )
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SummaryBanner(onAction: () => onOpenChat('1')),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text('HOY TE DICEN...', 
                    style: GardenTextStyles.label.copyWith(color: GardenColors.dust, letterSpacing: 1.5)),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: GardenColors.dustLight, thickness: 1)),
                ],
              ),
            ),
          ),
          plantsAsync.when(
            data: (plants) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PlantFeedCard(plant: plants[index], onTap: () => onSelectPlant(plants[index].id)),
                ),
                childCount: plants.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: GardenColors.moss))),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e', style: GardenTextStyles.bodySmall))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}