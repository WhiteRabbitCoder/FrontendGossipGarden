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
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Buenos dias, Gabriela",
                      style: TextStyle(color: Colors.black45, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text("Gossip Garden",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                  const Text("Tus plantas tienen algo que contarte...",
                      style: TextStyle(color: Colors.black38, fontSize: 15)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SummaryBanner(onAction: () => onOpenChat('1')),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 40, 24, 16),
              child: Text('HOY TE DICEN...',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black26,
                      letterSpacing: 1.2)),
            ),
          ),
          plantsAsync.when(
            data: (plants) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: PlantFeedCard(
                      plant: plants[index],
                      onTap: () => onSelectPlant(plants[index].id)),
                ),
                childCount: plants.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
