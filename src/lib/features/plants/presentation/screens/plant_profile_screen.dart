import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';

import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../data/models/comfort_zones.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';
import 'sensor_settings_screen.dart';

// HARDCODE(demo): dueño, personalidad, cuidados y "Sobre la planta" por ID fijo ('1'..'3').
// TODO(backend): GET /plants/{id} con especie, dueño y guía de cuidados.
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
                icon: const GardenIcon(asset: GardenIcons.back, size: 20),
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
        final realtime = realtimeAsync.valueOrNull;

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
              icon: const GardenIcon(asset: GardenIcons.back, size: 20),
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
                  icon: const GardenIcon(asset: GardenIcons.chat, size: 20),
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

                // ── Estado del sensor ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SensorStatusCard(plant: plant),
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
                    const GardenIcon(
                      asset: GardenIcons.logroFavorita,
                      size: 12,
                    ),
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
                      errorBuilder: (_, __, ___) => GardenIcon(
                        asset: _getPlantIcon(plant.species),
                        size: 64,
                      ),
                    ),
                  )
                : GardenIcon(
                    asset: _getPlantIcon(plant.species),
                    size: 64,
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

  String _getPlantIcon(String species) =>
      GardenIcons.plantAssetForSpecies(species);
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

  // HARDCODE(demo): rasgos por ID de planta. TODO(backend): plant_species endpoint.
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

// ── Sensor Status Card ────────────────────────────────────────────────────────

class _SensorStatusCard extends StatelessWidget {
  final Plant plant;

  const _SensorStatusCard({required this.plant});

  void _openSensorSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SensorSettingsScreen(initialPlantId: plant.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, iconAsset, subtitle) = switch (plant.sensorStatus) {
      SensorStatus.online => (
          'En línea',
          GardenColors.okGreen,
          GardenIcons.wifi,
          'Recibiendo datos en tiempo real',
        ),
      SensorStatus.degraded => (
          'Señal débil',
          GardenColors.golden,
          GardenIcons.signal,
          'Datos con retraso o señal inestable',
        ),
      SensorStatus.offline => (
          'Sin conexión',
          GardenColors.heartRed,
          GardenIcons.sensorOffline,
          'No hay datos del sensor',
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado del sensor',
          style: GardenTextStyles.title.copyWith(
            color: GardenColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openSensorSettings(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: GardenIcon(asset: iconAsset, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GardenTextStyles.bodySmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GardenTextStyles.bodySmall.copyWith(
                            color: GardenColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plant.sensorStatus == SensorStatus.offline
                              ? 'Toca para reconectar o revisar la falla'
                              : 'Toca para ver detalles y configuración',
                          style: GardenTextStyles.label.copyWith(
                            color: GardenColors.leafDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
              iconAsset: GardenIcons.soilHumidity,
            ),
            _SensorTile(
              label: 'LUZ',
              value: '${light.toInt()}%',
              iconAsset: GardenIcons.sun,
            ),
            _SensorTile(
              label: 'TEMP.',
              value: '${temperature.toStringAsFixed(0)}°C',
              iconAsset: GardenIcons.thermostat,
            ),
            _SensorTile(
              label: 'HUMEDAD',
              value: '${humidity.toInt()}%',
              iconAsset: GardenIcons.humidity,
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
  final String iconAsset;

  const _SensorTile({
    required this.label,
    required this.value,
    required this.iconAsset,
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
          SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: GardenIcon(asset: iconAsset, size: 24),
            ),
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

  // HARDCODE(demo): origen, edad y ubicación por ID. TODO(backend): plants / plant_species.
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
      (GardenIcons.mountain, 'Origen', info.origin),
      (GardenIcons.calendar, 'Edad', info.age),
      (GardenIcons.map, 'Vive en', info.location),
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
                        GardenIcon(asset: row.$1, size: 18, opacity: 0.6),
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

  // HARDCODE(demo): guía de cuidados por ID. TODO(backend): plant_species endpoint.
  static const _careItems = {
    '1': [
      (GardenIcons.water, 'RIEGO', 'Cada 7 días, 250ml'),
      (GardenIcons.sun, 'LUZ', 'Luz indirecta brillante'),
      (GardenIcons.soil, 'SUSTRATO', 'Mezcla aireada con perlita'),
      (GardenIcons.humidity, 'HUMEDAD', 'Le encanta la humedad alta (60%+)'),
    ],
    '2': [
      (GardenIcons.water, 'RIEGO', 'Cada 14 días, 100ml'),
      (GardenIcons.sun, 'LUZ', 'Luz directa varias horas'),
      (GardenIcons.soil, 'SUSTRATO', 'Cactus y suculentas'),
      (GardenIcons.humidity, 'HUMEDAD', 'Prefiere ambiente seco (20-40%)'),
    ],
    '3': [
      (GardenIcons.water, 'RIEGO', 'Cada 10 días, 300ml'),
      (GardenIcons.sun, 'LUZ', 'Luz indirecta brillante'),
      (GardenIcons.soil, 'SUSTRATO', 'Tierra bien drenada'),
      (GardenIcons.humidity, 'HUMEDAD', 'Humedad moderada (40-60%)'),
    ],
  };

  // HARDCODE(demo): tips de cuidado por ID. TODO(backend): consejos desde backend/IA.
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
                          child: GardenIcon(asset: item.$1, size: 18),
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
                const GardenIcon(asset: GardenIcons.bulb, size: 18),
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
