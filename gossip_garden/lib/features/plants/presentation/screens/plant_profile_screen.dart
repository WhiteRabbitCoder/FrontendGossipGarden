import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../widgets/telemetry_panel.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../data/models/comfort_zones.dart';
import 'package:gossip_garden/core/theme/app_design_system.dart';

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

    return plantsAsync.when(
      data: (plants) {
        if (plants.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDFCF8),
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              title: const Text('Perfil de planta'),
            ),
            body: const Center(
              child: Text(
                'Aun no hay plantas disponibles.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        final plant = plants.firstWhere((p) => p.id == plantId,
            orElse: () => plants.first);
        return Scaffold(
          backgroundColor: const Color(0xFFFDFCF8),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
            title: Text(plant.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => onOpenChat(plantId),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlantHeader(plant),
                const SizedBox(height: 24),
                _buildHealthBar(context, plant),
                const SizedBox(height: 24),
                _buildInsights(plant),
                const SizedBox(height: 24),
                TelemetryPanel(
                  telemetryData: [
                    _telemetryData(
                        'Humedad suelo',
                        plant.sensors.soilMoisture,
                        plant.comfortZones.soilMoisture,
                        '%',
                        Icons.water_drop,
                        const Color(0xFF4A6741)),
                    _telemetryData(
                        'Temperatura',
                        plant.sensors.temperature,
                        plant.comfortZones.temperature,
                        '°C',
                        Icons.thermostat,
                        Colors.orange),
                    _telemetryData(
                        'Luz',
                        plant.sensors.light,
                        plant.comfortZones.light,
                        'lux',
                        Icons.light_mode,
                        Colors.amber),
                    _telemetryData(
                        'Humedad aire',
                        plant.sensors.humidity,
                        plant.comfortZones.humidity,
                        '%',
                        Icons.cloud,
                        Colors.blue),
                  ],
                  initiallyExpanded: true,
                ),
                const SizedBox(height: 24),
                _buildActions(plant),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildPlantHeader(Plant plant) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
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
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plant.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700)),
              Text(plant.species,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _moodColor(plant.mood).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plant.mood.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _moodColor(plant.mood),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _personalityColor(plant.personality).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plant.personality.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _personalityColor(plant.personality),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthBar(BuildContext context, Plant plant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Salud',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('${plant.health.toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A6741))),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              height: 12,
              width: MediaQuery.of(context).size.width * (plant.health / 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    plant.health > 70
                        ? Colors.green
                        : plant.health > 40
                            ? Colors.orange
                            : Colors.red,
                    plant.health > 70
                        ? const Color(0xFF8BC34A)
                        : plant.health > 40
                            ? Colors.amber
                            : Colors.redAccent,
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Degradada',
                style: TextStyle(
                    color: plant.health < 50 ? Colors.red : Colors.black54)),
            Text('Óptima',
                style: TextStyle(
                    color: plant.health > 80 ? Colors.green : Colors.black54)),
          ],
        ),
      ],
    );
  }

  Widget _buildInsights(Plant plant) {
    if (plant.insights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppDesignSystem.shadowSoft,
        ),
        child: const Text('No hay insights aún',
            style: TextStyle(color: Colors.black54)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesignSystem.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 Insights recientes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...plant.insights
              .map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle,
                            size: 8, color: Color(0xFF4A6741)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(insight,
                                style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildActions(Plant plant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acciones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionButton('💬 Hablar con planta', () => onOpenChat(plantId)),
            _actionButton('💧 Regar', () {}),
            _actionButton('📊 Ver historial', () {}),
            _actionButton('⚙️ Ajustar sensores', () {}),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDesignSystem.shadowSoft,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }

  TelemetryData _telemetryData(String label, double value, Range range,
      String unit, IconData icon, Color color) {
    return TelemetryData(
      label: label,
      value: value,
      min: range.min,
      max: range.max,
      unit: unit,
      icon: icon,
      color: color,
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

  Color _personalityColor(PlantPersonality personality) {
    switch (personality) {
      case PlantPersonality.playful:
        return Colors.purple;
      case PlantPersonality.wise:
        return Colors.brown;
      case PlantPersonality.dramatic:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
