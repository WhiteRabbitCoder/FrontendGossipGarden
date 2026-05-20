import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../providers/navigation_provider.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';
import 'plant_identify_screen.dart';

class GardenViewScreen extends ConsumerWidget {
  const GardenViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    return Scaffold(
      backgroundColor: GardenColors.cream,
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
                                color: GardenColors.charcoal,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${plants.length} plantas en tu colección',
                              style: GardenTextStyles.bodySmall.copyWith(
                                color: GardenColors.dust,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0, right: 8.0),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: GardenColors.charcoal,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Acciones rápidas ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    _QuickActionRow(
                      icon: Icons.add_rounded,
                      iconBgColor: GardenColors.forest,
                      iconColor: Colors.white,
                      bgColor: const Color(0xFFF1F8F5),
                      borderColor: GardenColors.sage,
                      title: 'Agregar nueva planta',
                      subtitle: 'Reconócela con la cámara o búscala por nombre',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PlantIdentifyScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _QuickActionRow(
                      icon: Icons.person_add_alt_1_rounded,
                      iconBgColor: GardenColors.sageLight,
                      iconColor: GardenColors.forest,
                      title: 'Invita a un amigo jardinero',
                      subtitle: 'Comparte tu jardín o únete con un link',
                      onTap: () {
                        // TODO(backend): conectar flujo de invitación
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Lista de plantas del usuario ─────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _GardenPlantCard(
                    plant: plants[index],
                    onTap: () => navNotifier.selectPlant(plants[index].id),
                  ),
                ),
                childCount: plants.length,
              ),
            ),

            // ── Plantas de amigos ────────────────────────────────────────────
            // TODO(backend): conectar endpoint de amigos cuando esté disponible
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _FriendPlantsSection(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: GardenColors.moss),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: GardenTextStyles.bodySmall),
        ),
      ),
    );
  }
}

// ── Quick Action Row ──────────────────────────────────────────────────────────

class _QuickActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color bgColor;
  final Color borderColor;

  const _QuickActionRow({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.bgColor = Colors.white,
    this.borderColor = GardenColors.dustLight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GardenTextStyles.title.copyWith(
                        color: GardenColors.charcoal,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GardenTextStyles.bodySmall.copyWith(
                        color: GardenColors.dust,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: GardenColors.dust,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Garden Plant Card ─────────────────────────────────────────────────────────

class _GardenPlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const _GardenPlantCard({required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = plant.sensorStatus == SensorStatus.online;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GardenColors.dustLight),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── Ícono + wifi indicator ──────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GardenColors.sageLight,
                    ),
                    child: plant.image.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              plant.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                _getPlantIcon(plant.species),
                                color: GardenColors.forest,
                                size: 26,
                              ),
                            ),
                          )
                        : Icon(
                            _getPlantIcon(plant.species),
                            color: GardenColors.forest,
                            size: 26,
                          ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: GardenColors.dustLight, width: 1.5),
                      ),
                      child: Center(
                        child: Icon(
                          isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          size: 10,
                          color: isOnline ? GardenColors.forest : GardenColors.dust,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // ── Nombre + badges + barra ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + mood badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plant.name,
                            style: GardenTextStyles.title.copyWith(
                              color: GardenColors.charcoal,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _MoodBadge(mood: plant.mood),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Especie + personalidad tag
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plant.species,
                            style: GardenTextStyles.bodySmall.copyWith(
                              color: GardenColors.dust,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _PersonalityTag(personality: plant.personality),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Barra de salud + porcentaje
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: plant.health / 100,
                              minHeight: 6,
                              backgroundColor: _healthBgColor(plant.health),
                              color: _healthColor(plant.health),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${plant.health.toInt()}%',
                          style: GardenTextStyles.label.copyWith(
                            color: GardenColors.dust,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: GardenColors.dust,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _healthColor(double health) {
    if (health >= 90) return GardenColors.forest;
    if (health >= 70) return GardenColors.sage;
    return GardenColors.errorRose;
  }

  Color _healthBgColor(double health) {
    if (health >= 70) return GardenColors.sageLight;
    return const Color(0xFFF6E8E8);
  }

  IconData _getPlantIcon(String species) {
    final lower = species.toLowerCase();
    if (lower.contains('echeveria') || lower.contains('suculenta')) {
      return Icons.local_florist_outlined;
    }
    if (lower.contains('ficus')) {
      return Icons.park_outlined;
    }
    return Icons.eco_outlined;
  }
}

// ── Mood Badge ────────────────────────────────────────────────────────────────

class _MoodBadge extends StatelessWidget {
  final PlantMood mood;
  const _MoodBadge({required this.mood});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _style(mood);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (String, Color, Color) _style(PlantMood mood) {
    switch (mood) {
      case PlantMood.thirsty:
        return ('Sedienta', const Color(0xFFFFEDED), const Color(0xFFD94040));
      case PlantMood.stressed:
        return ('Estresada', const Color(0xFFFFF1E0), const Color(0xFFB85C00));
      case PlantMood.cold:
        return ('Fría', const Color(0xFFE0F0FF), const Color(0xFF2563EB));
      case PlantMood.hot:
        return ('Acalorada', const Color(0xFFFFF1E0), const Color(0xFFB85C00));
      case PlantMood.perfect:
      case PlantMood.happy:
        return ('Óptimo', const Color(0xFFE6F4EA), const Color(0xFF2E7D32));
    }
  }
}

// ── Personality Tag ───────────────────────────────────────────────────────────

class _PersonalityTag extends StatelessWidget {
  final PlantPersonality personality;
  const _PersonalityTag({required this.personality});

  @override
  Widget build(BuildContext context) {
    final (label, bg) = _style(personality);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GardenTextStyles.label.copyWith(
          fontSize: 10,
          color: GardenColors.charcoal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (String, Color) _style(PlantPersonality p) {
    switch (p) {
      case PlantPersonality.dramatic:
        return ('🎭 La dramática', const Color(0xFFFFEDF4));
      case PlantPersonality.wise:
        return ('🧘 La zen', const Color(0xFFE8F5E9));
      case PlantPersonality.playful:
        return ('🎩 El filósofo', const Color(0xFFF3E8FF));
    }
  }
}

// ── Friend Plants Section ─────────────────────────────────────────────────────
// TODO(backend): reemplazar datos demo con endpoint de amigos cuando esté disponible

class _FriendPlantsSection extends StatelessWidget {
  const _FriendPlantsSection();

  // Demo data — estructurado para fácil integración con endpoint de amigos
  static const _friendPlants = [
    (
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
                size: 20, color: GardenColors.dust),
            const SizedBox(width: 8),
            Text(
              'Plantas de amigos',
              style: GardenTextStyles.title.copyWith(
                color: GardenColors.charcoal,
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

  const _FriendPlantCard({
    required this.friendName,
    required this.plantName,
    required this.species,
    required this.moodLabel,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO(backend): navegar al jardín del amigo
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GardenColors.dustLight),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GardenColors.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: GardenColors.forest,
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
                              color: GardenColors.charcoal,
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
                          color: GardenColors.dust,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: 'de $friendName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: GardenColors.charcoal,
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
                        color: GardenColors.dust,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: GardenColors.dust,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
