import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../providers/navigation_provider.dart';
import '../widgets/plant_feed_card.dart';
import '../widgets/summary_banner.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
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
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Toggle visual lista/cuadrícula — no afecta lógica de navegación
  bool _isListView = true;

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final authSession = ref.watch(authStateProvider).value;
    final displayName = authSession?.profile?.displayName;
    final userName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName
        : (authSession?.profile?.email?.split('@').first ?? 'Usuario');

    return Scaffold(
      backgroundColor: GardenColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buenos días, $userName',
                            style: GardenTextStyles.bodySmall.copyWith(
                              color: GardenColors.dust,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text('🪴', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 6),
                              Text(
                                'Tu Jardín',
                                style: GardenTextStyles.display.copyWith(
                                  color: GardenColors.charcoal,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Resumen de hoy',
                            style: GardenTextStyles.bodySmall.copyWith(
                              color: GardenColors.dust,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _NotificationBell(count: 4),
                  ],
                ),
              ),
            ),
          ),

          // ── Summary Banner ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: SummaryBanner(
                onAction: () => navNotifier.changeTab(TabId.garden),
              ),
            ),
          ),

          // ── Sensor Alert (solo si hay sensor offline) ────────────────────────
          plantsAsync.maybeWhen(
            data: (plants) {
              final Plant? offline = plants
                  .where((p) => p.sensorStatus == SensorStatus.offline)
                  .firstOrNull;
              if (offline == null) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SensorAlertRow(
                    plantName: offline.name,
                    onTap: () => widget.onSelectPlant(offline.id),
                  ),
                ),
              );
            },
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // ── "Estado Actual" header con toggle ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Estado Actual',
                    style: GardenTextStyles.title.copyWith(
                      color: GardenColors.charcoal,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _isListView = false),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color:
                          !_isListView ? GardenColors.forest : GardenColors.dust,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _isListView = true),
                    child: Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 20,
                      color:
                          _isListView ? GardenColors.forest : GardenColors.dust,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de plantas ─────────────────────────────────────────────────
          plantsAsync.when(
            data: (plants) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PlantFeedCard(
                    plant: plants[index],
                    onTap: () => widget.onSelectPlant(plants[index].id),
                  ),
                ),
                childCount: plants.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: CircularProgressIndicator(color: GardenColors.moss)),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                  child: Text('Error: $e',
                      style: GardenTextStyles.bodySmall)),
            ),
          ),

          // ── Próximos Cuidados ────────────────────────────────────────────────
          plantsAsync.maybeWhen(
            data: (plants) {
              final Plant? withCare =
                  plants.where((p) => p.insights.length > 1).firstOrNull;
              if (withCare == null) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _UpcomingCareSection(
                    plantName: withCare.name,
                    careText: withCare.insights.last,
                  ),
                ),
              );
            },
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// ── Notification Bell ─────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  final int count;
  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: GardenColors.dustLight),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: GardenColors.charcoal,
            size: 22,
          ),
        ),
        if (count > 0)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: GardenColors.errorRose,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Sensor Alert Row ──────────────────────────────────────────────────────────

class _SensorAlertRow extends StatelessWidget {
  final String plantName;
  final VoidCallback onTap;

  const _SensorAlertRow({required this.plantName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GardenColors.dustLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 18, color: GardenColors.dust),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GardenTextStyles.bodySmall
                    .copyWith(color: GardenColors.dust),
                children: [
                  const TextSpan(text: 'Sensor desconectado en '),
                  TextSpan(
                    text: plantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: GardenColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Revisar',
              style: GardenTextStyles.label.copyWith(
                color: GardenColors.forest,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming Care Section ─────────────────────────────────────────────────────

class _UpcomingCareSection extends StatelessWidget {
  final String plantName;
  final String careText;

  const _UpcomingCareSection({
    required this.plantName,
    required this.careText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: GardenColors.golden, size: 20),
            const SizedBox(width: 8),
            Text(
              'Próximos Cuidados',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.charcoal,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GardenColors.dustLight),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: GardenColors.golden,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RichText(
                      text: TextSpan(
                        style: GardenTextStyles.bodySmall
                            .copyWith(color: GardenColors.dust, height: 1.5),
                        children: [
                          TextSpan(
                            text: '$plantName ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: GardenColors.charcoal,
                            ),
                          ),
                          TextSpan(text: careText),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}