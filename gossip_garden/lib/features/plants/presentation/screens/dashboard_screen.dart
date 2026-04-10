import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../widgets/plant_feed_card.dart';
import '../widgets/summary_banner.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFFFDFCF8),
            elevation: 0,
            title: const Text('Gossip Garden', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SummaryBanner(onAction: () => onOpenChat('1')),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('HOY TE DICEN...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
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
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}