import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../providers/navigation_provider.dart';
import '../providers/achievement_providers.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../widgets/garden_plant_card.dart';
import 'invite_friend_screen.dart';
import 'plant_identify_screen.dart';

class GardenViewScreen extends ConsumerStatefulWidget {
  const GardenViewScreen({super.key});

  @override
  ConsumerState<GardenViewScreen> createState() => _GardenViewScreenState();
}

class _GardenViewScreenState extends ConsumerState<GardenViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(achievementStatsProvider.notifier).recordGardenVisit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
      body: plantsAsync.when(
        data: (plants) => CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi Jardín',
                              style: GardenTextStyles.display.copyWith(
                                color: GardenColors.ink,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${plants.length} plantas en tu colección',
                              style: GardenTextStyles.bodySmall.copyWith(
                                color: GardenColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _GardenHeaderAction(
                        icon: Icons.add_rounded,
                        tooltip: 'Agregar nueva planta',
                        backgroundColor: GardenColors.leafDark,
                        iconColor: Colors.white,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PlantIdentifyScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _GardenHeaderAction(
                        icon: Icons.person_add_alt_1_rounded,
                        tooltip: 'Invitar amigo jardinero',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const InviteFriendScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Lista de plantas del usuario ─────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GardenPlantCard(
                    plant: plants[index],
                    onTap: () => navNotifier.selectPlant(plants[index].id),
                  ),
                ),
                childCount: plants.length,
              ),
            ),

            // ── Plantas de amigos ────────────────────────────────────────────
            // TODO(backend): conectar endpoint de amigos cuando esté disponible
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _FriendPlantsSection(
                  onOpenFriendGarden: navNotifier.openFriendGarden,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: GardenColors.leafGreen),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: GardenTextStyles.bodySmall),
        ),
      ),
    );
  }
}

// ── Header action icon ────────────────────────────────────────────────────────

class _GardenHeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  const _GardenHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor = GardenColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: backgroundColor == Colors.white
                    ? GardenColors.creamPaper
                    : Colors.transparent,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}

// ── Friend Plants Section ─────────────────────────────────────────────────────
// TODO(backend): reemplazar datos demo con endpoint de amigos cuando esté disponible

class _FriendPlantsSection extends StatelessWidget {
  final void Function(String friendId) onOpenFriendGarden;

  const _FriendPlantsSection({required this.onOpenFriendGarden});

  // Demo data — estructurado para fácil integración con endpoint de amigos
  static const _friendPlants = [
    (
      friendId: 'mateo',
      friendName: 'Mateo',
      plantName: 'Potos de Mateo',
      species: 'Epipremnum Aureum',
      moodLabel: 'Feliz',
      quote: '"Mateo me cuida muy bien, ¡crezco rápido!"',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_outline_rounded,
                size: 20, color: GardenColors.inkSoft),
            const SizedBox(width: 8),
            Text(
              'Plantas de amigos',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._friendPlants.map((fp) => _FriendPlantCard(
              friendName: fp.friendName,
              plantName: fp.plantName,
              species: fp.species,
              moodLabel: fp.moodLabel,
              quote: fp.quote,
              onTap: () => onOpenFriendGarden(fp.friendId),
            )),
      ],
    );
  }
}

class _FriendPlantCard extends StatelessWidget {
  final String friendName;
  final String plantName;
  final String species;
  final String moodLabel;
  final String quote;
  final VoidCallback onTap;

  const _FriendPlantCard({
    required this.friendName,
    required this.plantName,
    required this.species,
    required this.moodLabel,
    required this.quote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GardenColors.creamLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: GardenColors.leafDark,
                  size: 24,
                ),
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
                            plantName,
                            style: GardenTextStyles.title.copyWith(
                              color: GardenColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            moodLabel,
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: GardenTextStyles.bodySmall.copyWith(
                          color: GardenColors.inkSoft,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: 'de $friendName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: GardenColors.ink,
                            ),
                          ),
                          TextSpan(text: ' · $species'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quote,
                      style: GardenTextStyles.bodySmall.copyWith(
                        color: GardenColors.inkSoft,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: GardenColors.inkSoft,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
