import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../providers/navigation_provider.dart';
import '../providers/urgent_tasks_provider.dart';
import '../widgets/plant_feed_card.dart';
import '../widgets/summary_banner.dart';
import '../widgets/urgent_tasks_sheet.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';

// HARDCODE(demo): banner, campana y cuidados se alimentan de plantsProvider (plantas locales).
// TODO(backend): conectar dashboard a API de inicio con resumen y alertas reales.
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
  bool _isListView = true;

  Widget _buildPlantsSliver(List<Plant> plants) {
    if (_isListView) {
      return SliverList(
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
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => PlantFeedGridCard(
            plant: plants[index],
            onTap: () => widget.onSelectPlant(plants[index].id),
          ),
          childCount: plants.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final urgentCount = ref.watch(pendingUrgentTasksCountProvider);
    final navNotifier = ref.read(navigationProvider.notifier);
    final authSession = ref.watch(authStateProvider).value;
    final displayName = authSession?.profile?.displayName;
    final userName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName
        : (authSession?.profile?.email?.split('@').first ?? 'Usuario');

    return Scaffold(
      backgroundColor: GardenColors.creamPaper,
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
                              color: GardenColors.inkSoft,
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
                                  color: GardenColors.ink,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Resumen de hoy',
                            style: GardenTextStyles.bodySmall.copyWith(
                              color: GardenColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _NotificationBell(
                      count: urgentCount,
                      onTap: () => showUrgentTasksSheet(context),
                    ),
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
                  Expanded(
                    child: Text(
                      'Estado Actual',
                      style: GardenTextStyles.title.copyWith(
                        color: GardenColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GardenColors.creamPaper),
                    ),
                    child: Row(
                      children: [
                        _ViewModeToggle(
                          asset: GardenIcons.viewGrid,
                          tooltip: 'Vista en cuadrícula',
                          isSelected: !_isListView,
                          onTap: () => setState(() => _isListView = false),
                        ),
                        _ViewModeToggle(
                          asset: GardenIcons.viewList,
                          tooltip: 'Vista en lista',
                          isSelected: _isListView,
                          onTap: () => setState(() => _isListView = true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista o cuadrícula de plantas ────────────────────────────────────
          plantsAsync.when(
            data: (plants) => _buildPlantsSliver(plants),
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: CircularProgressIndicator(
                        color: GardenColors.leafGreen)),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                  child: Text('Error: $e', style: GardenTextStyles.bodySmall)),
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

// ── View mode toggle ──────────────────────────────────────────────────────────

class _ViewModeToggle extends StatelessWidget {
  final String asset;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeToggle({
    required this.asset,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected ? GardenColors.creamLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GardenIcon(
              asset: asset,
              size: 20,
              opacity: isSelected ? 1.0 : 0.45,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Notification Bell ─────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationBell({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: GardenColors.creamPaper),
          ),
          child: const GardenIcon(
            asset: GardenIcons.notification,
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
                color: GardenColors.heartRed,
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
    ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GardenColors.dustLight, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: GardenColors.ink.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const GardenIcon(
            asset: GardenIcons.sensorOffline,
            size: 18,
            opacity: 0.7,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GardenTextStyles.bodySmall
                    .copyWith(color: GardenColors.inkSoft),
                children: [
                  const TextSpan(text: 'Sensor desconectado en '),
                  TextSpan(
                    text: plantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: GardenColors.ink,
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
                color: GardenColors.leafDark,
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
            const GardenIcon(
              asset: GardenIcons.bulb,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Próximos Cuidados',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.ink,
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GardenColors.dustLight, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: GardenColors.ink.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
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
                        left: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RichText(
                      text: TextSpan(
                        style: GardenTextStyles.bodySmall
                            .copyWith(color: GardenColors.inkSoft, height: 1.5),
                        children: [
                          TextSpan(
                            text: '$plantName ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: GardenColors.ink,
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
