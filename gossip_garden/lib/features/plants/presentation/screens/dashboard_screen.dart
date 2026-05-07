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
            toolbarHeight: 70,
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade100,
                    image: const DecorationImage(
                      image: NetworkImage(''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¡Hola, Juliana!', 
                      style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('Tu jardín está vivo', 
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
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
                  const Text('HOY TE DICEN...', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 1.2)),
                  const SizedBox(width: 12),
                  Expanded(child: Divider(color: Colors.grey.shade200)),
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
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}