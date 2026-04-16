import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/plant_providers.dart';
import '../providers/navigation_provider.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import 'package:gossip_garden/core/theme/app_design_system.dart';

class GardenViewScreen extends ConsumerWidget {
  const GardenViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        title: const Text('Mi Jardín'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
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
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildPlantCard(plants[index], navNotifier),
                  childCount: plants.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesignSystem.shadowSoft,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(FontAwesomeIcons.seedling, '$totalPlants', 'Plantas'),
          _buildStatItem(
              FontAwesomeIcons.heartPulse, '$healthyCount', 'Saludables'),
          _buildStatItem(
              FontAwesomeIcons.towerBroadcast, '$onlineCount', 'En linea'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        FaIcon(icon, size: 24, color: const Color(0xFF4A6741)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acciones rápidas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionButton('Regar todas', Icons.water_drop, Colors.blue),
            _actionButton('Reporte', Icons.assessment, Colors.green),
            _actionButton('Luz', Icons.light_mode, Colors.amber),
            _actionButton('Alertas', Icons.notifications, Colors.orange),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDesignSystem.shadowSoft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppDesignSystem.shadowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                color: const Color(0xFF4A6741).withOpacity(0.1),
                image: plant.image.isNotEmpty
                    ? DecorationImage(
                        image: AssetImage(plant.image),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: plant.image.isEmpty
                  ? const Center(
                      child: Icon(Icons.local_florist,
                          size: 60, color: Color(0xFF4A6741)))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(plant.species,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: plant.health / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: plant.health > 70
                        ? Colors.green
                        : plant.health > 40
                            ? Colors.orange
                            : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _moodColor(plant.mood).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plant.mood.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _moodColor(plant.mood),
                          ),
                        ),
                      ),
                      Text('${plant.health.toInt()}%',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
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

  Color _moodColor(PlantMood mood) {
    switch (mood) {
      case PlantMood.happy:
        return Colors.green;
      case PlantMood.thirsty:
        return Colors.orange;
      case PlantMood.stressed:
        return Colors.red;
      case PlantMood.cold:
        return Colors.blue;
      case PlantMood.hot:
        return Colors.deepOrange;
      case PlantMood.perfect:
        return const Color(0xFF8BC34A);
      default:
        return Colors.grey;
    }
  }
}
