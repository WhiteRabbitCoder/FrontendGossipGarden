import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/plant_providers.dart';
import '../providers/navigation_provider.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

class GardenViewScreen extends ConsumerWidget {
  const GardenViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    return Scaffold(
      backgroundColor: GardenColors.cream,
      appBar: AppBar(
        title: Text('Mi Jardín', style: GardenTextStyles.display.copyWith(color: GardenColors.forest, fontSize: 32)),
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
              icon: const Icon(Icons.add_rounded, color: GardenColors.forest),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: plantsAsync.when(
        data: (plants) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGardenStats(plants),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildPlantCard(plants[index], navNotifier),
                  childCount: plants.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: GardenColors.moss)),
        error: (e, _) => Center(child: Text('Error: $e', style: GardenTextStyles.bodySmall)),
      ),
    );
  }

  Widget _buildGardenStats(List<Plant> plants) {
    final totalPlants = plants.length;
    final healthyCount = plants.where((p) => p.health > 70).length;
    final onlineCount =
        plants.where((p) => p.sensorStatus == SensorStatus.online).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GardenColors.parchment,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: GardenColors.sageLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: GardenColors.forest.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(FontAwesomeIcons.seedling, '$totalPlants', 'Plantas'),
          _buildStatItem(
              FontAwesomeIcons.heartPulse, '$healthyCount', 'Saludables'),
          _buildStatItem(
              FontAwesomeIcons.towerBroadcast, '$onlineCount', 'En línea'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        FaIcon(icon, size: 28, color: GardenColors.forest),
        const SizedBox(height: 12),
        Text(value,
            style: GardenTextStyles.title.copyWith(fontSize: 28, color: GardenColors.charcoal)),
        Text(label,
            style: GardenTextStyles.label.copyWith(fontSize: 14, color: GardenColors.dust)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acciones rápidas',
            style: GardenTextStyles.title.copyWith(fontSize: 22, color: GardenColors.charcoal)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionButton('Regar', Icons.water_drop_rounded, GardenColors.waterBlue),
            _actionButton('Reporte', Icons.assessment_rounded, GardenColors.moss),
            _actionButton('Luz', Icons.light_mode_rounded, GardenColors.golden),
            _actionButton('Alertas', Icons.notifications_rounded, GardenColors.errorRose),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(label, style: GardenTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantCard(Plant plant, NavigationNotifier nav) {
    return GestureDetector(
      onTap: () => nav.selectPlant(plant.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  color: GardenColors.sageLight,
                ),
                child: Center(
                  child: plant.image.isNotEmpty
                    ? Image.network(
                        plant.image,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.park_rounded, size: 48, color: GardenColors.forest),
                      )
                    : const Icon(Icons.park_rounded, size: 48, color: GardenColors.forest),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.name,
                      style: GardenTextStyles.title.copyWith(fontSize: 18, color: GardenColors.charcoal),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(plant.species,
                      style: GardenTextStyles.bodySmall.copyWith(fontSize: 12, color: GardenColors.dust),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: plant.health / 100,
                      backgroundColor: GardenColors.sageLight,
                      color: plant.health > 70
                          ? GardenColors.moss
                          : plant.health > 40
                              ? GardenColors.golden
                              : GardenColors.errorRose,
                      minHeight: 8,
                    ),
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
