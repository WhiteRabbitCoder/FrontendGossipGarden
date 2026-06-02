import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';

import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../data/models/comfort_zones.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

class PlantProfileScreen extends ConsumerWidget {
  final String plantId;
  final VoidCallback onBack;
  final Function(String) onOpenChat;

  const PlantProfileScreen({
    super.key,
    required this.plantId,
    required this.onBack,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final realtimeAsync = ref.watch(plantRealtimeSensorProvider(plantId));

    return plantsAsync.when(
      data: (plants) {
        if (plants.isEmpty) {
          return Scaffold(
            backgroundColor: GardenColors.creamPaper,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: onBack,
              ),
              title: const Text('Perfil de planta'),
            ),
            body: const Center(child: Text('Aún no hay plantas disponibles.')),
          );
        }

        final plant = plants.firstWhere(
          (p) => p.id == plantId,
          orElse: () => plants.first,
        );
        final realtime = realtimeAsync.value;

        // Sensor values: realtime if available, fallback to static
        final soilMoisture =
            realtime?.soilMoisture ?? plant.sensors.soilMoisture;
        final temperature = realtime?.temperature ?? plant.sensors.temperature;
        final light = realtime?.light ?? plant.sensors.light;
        final humidity = realtime?.humidity ?? plant.sensors.humidity;

        return Scaffold(
          backgroundColor: GardenColors.creamPaper,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: GardenColors.ink),
              onPressed: onBack,
            ),
            title: Column(
              children: [
                Text(
                  plant.name,
                  style: GardenTextStyles.title.copyWith(
                    color: GardenColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  plant.species,
                  style: GardenTextStyles.label.copyWith(
                    color: GardenColors.inkSoft,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: GardenColors.creamLight,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      color: GardenColors.leafDark, size: 20),
                  onPressed: () => onOpenChat(plantId),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero card ──────────────────────────────────────────────
                _PlantHeroCard(plant: plant),
                const SizedBox(height: 28),

                // ── Personalidad ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _PersonalitySection(plant: plant),
                ),
                const SizedBox(height: 24),

                // ── Cómo se siente ahora (sensores grid) ───────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SensorGrid(
                    soilMoisture: soilMoisture,
                    light: light,
                    temperature: temperature,
                    humidity: humidity,
                    comfortZones: plant.comfortZones,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Sobre la planta ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _AboutSection(plant: plant),
                ),
                const SizedBox(height: 24),

                // ── Cuidados generales ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CareSection(plant: plant),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: GardenColors.leafGreen)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e', style: GardenTextStyles.bodySmall)),
      ),
    );
  }
}

// ── Plant Hero Card ───────────────────────────────────────────────────────────

class _PlantHeroCard extends StatelessWidget {
  final Plant plant;
  const _PlantHeroCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final bgColor = _moodBgColor(plant.mood);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GardenColors.creamPaper),
      ),
      child: Column(
        children: [
          // owner tag + mood badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GardenColors.creamLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 12, color: GardenColors.leafDark),
                    const SizedBox(width: 4),
                    Text(
                      'Montse', // TODO(backend): conectar nombre del dueño desde perfil
                      style: GardenTextStyles.label.copyWith(
                        color: GardenColors.leafDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _MoodBadge(mood: plant.mood),
            ],
          ),
          const SizedBox(height: 16),
          // Imagen circular con fondo de color mood
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
            ),
            child: plant.image.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      plant.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        _getPlantIcon(plant.species),
                        size: 64,
                        color: GardenColors.leafDark,
                      ),
                    ),
                  )
                : Icon(
                    _getPlantIcon(plant.species),
                    size: 64,
                    color: GardenColors.leafDark,
                  ),
          ),
          const SizedBox(height: 16),
          // Personality tag
          _PersonalityTag(personality: plant.personality),
          const SizedBox(height: 12),
          // Salud
          Text(
            '${plant.health.toInt()}% Salud',
            style: GardenTextStyles.display.copyWith(
              color: GardenColors.ink,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          // Quote
          if (plant.insights.isNotEmpty)
            Text(
              '"${plant.insights.first}"',
              textAlign: TextAlign.center,
              style: GardenTextStyles.bodySmall.copyWith(
                color: GardenColors.inkSoft,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Color _moodBgColor(PlantMood mood) {
    switch (mood) {
      case PlantMood.thirsty:
        return const Color(0xFFFFEDED);
      case PlantMood.stressed:
        return const Color(0xFFFFF1E0);
      case PlantMood.cold:
        return const Color(0xFFE0F0FF);
      case PlantMood.hot:
        return const Color(0xFFFFF1E0);
      case PlantMood.perfect:
      case PlantMood.happy:
        return const Color(0xFFE6F4EA);
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GardenTextStyles.label.copyWith(
          fontWeight: FontWeight.w600,
          color: GardenColors.ink,
        ),
      ),
    );
  }

  static (String, Color) _style(PlantPersonality p) {
    switch (p) {
      case PlantPersonality.dramatic:
        return ('🌹 La dramática', const Color(0xFFFFEDF4));
      case PlantPersonality.wise:
        return ('🧘 La zen', const Color(0xFFE8F5E9));
      case PlantPersonality.playful:
        return ('🦋 El filósofo', const Color(0xFFF3E8FF));
    }
  }
}

// ── Personality Section ───────────────────────────────────────────────────────

class _PersonalitySection extends StatelessWidget {
  final Plant plant;
  const _PersonalitySection({required this.plant});

  // Demo hardcoded — TODO(backend): traer rasgos desde plant_species endpoint
  static const _personalityTraits = {
    PlantPersonality.dramatic: (
      description: 'Te avisará con suspiros si algo no le gusta.',
      traits: ['Expresiva', 'Sensible', 'Curiosa'],
    ),
    PlantPersonality.wise: (
      description: 'Paciente y serena, raramente pide atención.',
      traits: ['Tranquila', 'Resistente', 'Reflexiva'],
    ),
    PlantPersonality.playful: (
      description: 'Adaptable y curioso, disfruta los cambios.',
      traits: ['Adaptable', 'Curioso', 'Tolerante'],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final info = _personalityTraits[plant.personality]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Personalidad',
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GardenColors.creamPaper),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.description,
                style: GardenTextStyles.bodySmall.copyWith(
                  color: GardenColors.inkSoft,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: info.traits
                    .map(
                      (trait) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: GardenColors.creamLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          trait,
                          style: GardenTextStyles.label.copyWith(
                            color: GardenColors.leafDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sensor Grid ───────────────────────────────────────────────────────────────

class _SensorGrid extends StatelessWidget {
  final double soilMoisture;
  final double light;
  final double temperature;
  final double humidity;
  final ComfortZones comfortZones;

  const _SensorGrid({
    required this.soilMoisture,
    required this.light,
    required this.temperature,
    required this.humidity,
    required this.comfortZones,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cómo se siente ahora',
          style: GardenTextStyles.title.copyWith(
            color: GardenColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _SensorTile(
              label: 'TIERRA',
              value: '${soilMoisture.toInt()}%',
              icon: Icons.water_drop_outlined,
              iconBg: const Color(0xFFE0F0FF),
              iconColor: const Color(0xFF2563EB),
            ),
            _SensorTile(
              label: 'LUZ',
              value: '${light.toInt()}%',
              icon: Icons.wb_sunny_outlined,
              iconBg: const Color(0xFFFFF8E0),
              iconColor: const Color(0xFFD97706),
            ),
            _SensorTile(
              label: 'TEMP.',
              value: '${temperature.toStringAsFixed(0)}°C',
              icon: Icons.thermostat_outlined,
              iconBg: const Color(0xFFFFEDED),
              iconColor: const Color(0xFFD94040),
            ),
            _SensorTile(
              label: 'HUMEDAD',
              value: '${humidity.toInt()}%',
              icon: Icons.air_outlined,
              iconBg: const Color(0xFFE0F0FF),
              iconColor: const Color(0xFF2563EB),
            ),
          ],
        ),
      ],
    );
  }
}

class _SensorTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _SensorTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GardenColors.creamPaper),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GardenTextStyles.label.copyWith(
                  color: GardenColors.inkSoft,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                value,
                style: GardenTextStyles.title.copyWith(
                  color: GardenColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── About Section ─────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final Plant plant;
  const _AboutSection({required this.plant});

  // Demo hardcoded — TODO(backend): traer desde plant_species / plants endpoints
  static const _plantAbout = {
    '1': (
      origin: 'Bosques tropicales del sur de México',
      age: '2 años · adoptada en Mar 2024',
      location: 'Sala — junto a la ventana',
    ),
    '2': (
      origin: 'Zonas áridas de México y Centro América',
      age: '1 año · adoptada en Jun 2024',
      location: 'Ventana sur — luz directa',
    ),
    '3': (
      origin: 'África tropical occidental',
      age: '3 años · adoptada en Ene 2023',
      location: 'Sala — luz indirecta',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final info = _plantAbout[plant.id] ??
        (
          origin: 'Origen desconocido',
          age: 'Desconocido',
          location: 'No especificado',
        );

    final rows = [
      (Icons.landscape_outlined, 'Origen', info.origin),
      (Icons.calendar_today_outlined, 'Edad', info.age),
      (Icons.location_on_outlined, 'Vive en', info.location),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre ${plant.name}',
          style: GardenTextStyles.title.copyWith(
            color: GardenColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GardenColors.creamPaper),
          ),
          child: Column(
            children: rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(row.$1,
                            size: 18, color: GardenColors.inkSoft),
                        const SizedBox(width: 12),
                        Text(
                          row.$2,
                          style: GardenTextStyles.bodySmall.copyWith(
                            color: GardenColors.inkSoft,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          row.$3,
                          style: GardenTextStyles.bodySmall.copyWith(
                            color: GardenColors.ink,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                  if (i < rows.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: GardenColors.creamPaper,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Care Section ──────────────────────────────────────────────────────────────

class _CareSection extends StatelessWidget {
  final Plant plant;
  const _CareSection({required this.plant});

  // Demo hardcoded — TODO(backend): traer desde plant_species endpoint
  static const _careItems = {
    '1': [
      (Icons.water_drop_outlined, 'RIEGO', 'Cada 7 días, 250ml'),
      (Icons.wb_sunny_outlined, 'LUZ', 'Luz indirecta brillante'),
      (Icons.grass_outlined, 'SUSTRATO', 'Mezcla aireada con perlita'),
      (Icons.air_outlined, 'HUMEDAD', 'Le encanta la humedad alta (60%+)'),
    ],
    '2': [
      (Icons.water_drop_outlined, 'RIEGO', 'Cada 14 días, 100ml'),
      (Icons.wb_sunny_outlined, 'LUZ', 'Luz directa varias horas'),
      (Icons.grass_outlined, 'SUSTRATO', 'Cactus y suculentas'),
      (Icons.air_outlined, 'HUMEDAD', 'Prefiere ambiente seco (20-40%)'),
    ],
    '3': [
      (Icons.water_drop_outlined, 'RIEGO', 'Cada 10 días, 300ml'),
      (Icons.wb_sunny_outlined, 'LUZ', 'Luz indirecta brillante'),
      (Icons.grass_outlined, 'SUSTRATO', 'Tierra bien drenada'),
      (Icons.air_outlined, 'HUMEDAD', 'Humedad moderada (40-60%)'),
    ],
  };

  static const _tips = {
    '1': 'Limpia sus hojas con un paño húmedo cada 2 semanas para que respire mejor.',
    '2': 'Evita el exceso de agua — es mejor poco y bien drenado.',
    '3': 'Gira el macetero cada 2 semanas para un crecimiento uniforme.',
  };

  @override
  Widget build(BuildContext context) {
    final items = _careItems[plant.id] ?? _careItems['1']!;
    final tip = _tips[plant.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuidados generales',
          style: GardenTextStyles.title.copyWith(
            color: GardenColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GardenColors.creamPaper),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: GardenColors.creamLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.$1,
                              size: 18, color: GardenColors.leafDark),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: GardenTextStyles.label.copyWith(
                                color: GardenColors.inkSoft,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              item.$3,
                              style: GardenTextStyles.bodySmall.copyWith(
                                color: GardenColors.ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: GardenColors.creamPaper,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        if (tip != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 18, color: Color(0xFFD94040)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GardenTextStyles.bodySmall.copyWith(
                        color: GardenColors.ink,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Tip: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: tip),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
