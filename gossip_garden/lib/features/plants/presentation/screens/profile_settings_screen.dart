import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/plant_providers.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import 'package:gossip_garden/core/theme/app_design_system.dart';
import 'package:gossip_garden/features/auth/presentation/providers/auth_provider.dart';

final favoritePlantsProvider = StateProvider<List<String>>((ref) => ['1', '2']);
final viewModeProvider =
    StateProvider<bool>((ref) => true); // true = grid, false = list

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final favorites = ref.watch(favoritePlantsProvider);
    final viewMode = ref.watch(viewModeProvider);
    final authSession = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: Icon(viewMode ? Icons.grid_view : Icons.list),
            onPressed: () =>
                ref.read(viewModeProvider.notifier).state = !viewMode,
          ),
        ],
      ),
      body: plantsAsync.when(
        data: (plants) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeader(),
              const SizedBox(height: 24),
              _buildBadgesSection(),
              const SizedBox(height: 24),
              _buildFavoritePlants(context, plants, favorites, ref),
              const SizedBox(height: 24),
              _buildSensorStatusCards(plants),
              const SizedBox(height: 24),
              _buildSessionCard(context, ref, authSession),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesignSystem.shadowSoft,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF4A6741),
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jardinero Digital',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('7 plantas conectadas',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTag(
                        FaIcon(FontAwesomeIcons.seedling,
                            size: 12, color: const Color(0xFF4A6741)),
                        'Novato',
                        const Color(0xFF4A6741)),
                    _buildTag(
                        FaIcon(FontAwesomeIcons.towerBroadcast,
                            size: 12, color: Colors.blue),
                        '3 sensores',
                        Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
      BuildContext context, WidgetRef ref, AuthSession? authSession) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesignSystem.shadowSoft,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF4A6741).withOpacity(0.1),
            child: const Icon(Icons.person, color: Color(0xFF4A6741)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authSession?.profile?.displayName ?? 'Sesion activa',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  authSession?.profile?.email ?? 'Sesion local',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
            child: const Text('Cerrar sesion'),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    final badges = [
      (
        FontAwesomeIcons.seedling,
        'Primera planta',
        'Agregaste tu primera planta'
      ),
      (FontAwesomeIcons.commentDots, 'Conversador', 'Enviaste 10 mensajes'),
      (
        FontAwesomeIcons.chartLine,
        'Científico',
        'Monitoreo continuo por 7 días'
      ),
      (FontAwesomeIcons.robot, 'IA Amiga', 'Usaste insights de IA'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Insignias',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return GestureDetector(
                onTap: () =>
                    _showBadgeInfo(context, badge.$1, badge.$2, badge.$3),
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(
                      right: index == badges.length - 1 ? 0 : 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppDesignSystem.shadowSoft,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(badge.$1,
                          size: 28, color: const Color(0xFF4A6741)),
                      const SizedBox(height: 8),
                      Text(badge.$2,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritePlants(BuildContext context, List<Plant> plants,
      List<String> favorites, WidgetRef ref) {
    final favoritePlants =
        plants.where((p) => favorites.contains(p.id)).toList();
    final isGrid = ref.watch(viewModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Plantas favoritas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('${favorites.length}/3',
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 12),
        if (isGrid)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: favoritePlants.length,
            itemBuilder: (context, index) =>
                _buildFavoriteCard(favoritePlants[index], favorites, ref),
          )
        else
          Column(
            children: favoritePlants
                .map((plant) => _buildFavoriteCard(plant, favorites, ref))
                .toList(),
          ),
        if (favorites.length < 3)
          _buildAddFavoriteButton(context, plants, favorites, ref),
      ],
    );
  }

  Widget _buildFavoriteCard(
      Plant plant, List<String> favorites, WidgetRef ref) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppDesignSystem.shadowSoft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF4A6741).withOpacity(0.1),
                  image: plant.image.isNotEmpty
                      ? DecorationImage(
                          image: AssetImage(plant.image),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: plant.image.isEmpty
                    ? const Icon(Icons.local_florist,
                        size: 40, color: Color(0xFF4A6741))
                    : null,
              ),
              const SizedBox(height: 12),
              Text(plant.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(plant.species,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: plant.health / 100,
                backgroundColor: Colors.grey.shade200,
                color: plant.health > 70
                    ? Colors.green
                    : plant.health > 40
                        ? Colors.orange
                        : Colors.red,
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeFavorite(plant.id, ref),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppDesignSystem.shadowSoft,
              ),
              child: const Icon(Icons.close, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddFavoriteButton(BuildContext context, List<Plant> plants,
      List<String> favorites, WidgetRef ref) {
    final availablePlants =
        plants.where((p) => !favorites.contains(p.id)).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ElevatedButton(
        onPressed: availablePlants.isEmpty
            ? null
            : () => _showAddFavoriteModal(context, availablePlants, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4A6741),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: const Color(0xFF4A6741).withOpacity(0.2)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20),
            SizedBox(width: 8),
            Text('Agregar planta favorita'),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatusCards(List<Plant> plants) {
    final onlineCount =
        plants.where((p) => p.sensorStatus == SensorStatus.online).length;
    final offlineCount =
        plants.where((p) => p.sensorStatus == SensorStatus.offline).length;
    final degradedCount =
        plants.where((p) => p.sensorStatus == SensorStatus.degraded).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Estado de sensores',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSensorCard('En línea', onlineCount, Colors.green, Icons.wifi),
            const SizedBox(width: 12),
            _buildSensorCard(
                'Degradado', degradedCount, Colors.orange, Icons.warning),
            const SizedBox(width: 12),
            _buildSensorCard(
                'Offline', offlineCount, Colors.grey, Icons.wifi_off),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDesignSystem.shadowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: color),
            ),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(Widget icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showBadgeInfo(
      BuildContext context, IconData icon, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 42, color: const Color(0xFF4A6741)),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6741),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Genial'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFavoriteModal(
      BuildContext context, List<Plant> availablePlants, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona una planta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...availablePlants
                .map((plant) => ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A6741).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: plant.image.isNotEmpty
                            ? Image.asset(plant.image, fit: BoxFit.cover)
                            : const Icon(Icons.local_florist, size: 20),
                      ),
                      title: Text(plant.name),
                      subtitle: Text(plant.species),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          ref.read(favoritePlantsProvider.notifier).state = [
                            ...ref.read(favoritePlantsProvider),
                            plant.id
                          ];
                          Navigator.pop(context);
                        },
                      ),
                    ))
                ,
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.black54,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeFavorite(String plantId, WidgetRef ref) {
    final current = ref.read(favoritePlantsProvider);
    ref.read(favoritePlantsProvider.notifier).state =
        current.where((id) => id != plantId).toList();
  }
}
