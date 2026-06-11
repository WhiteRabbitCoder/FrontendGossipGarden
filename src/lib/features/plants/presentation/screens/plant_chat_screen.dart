import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../providers/chat_providers.dart';
import '../providers/achievement_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/telemetry_panel.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../../core/theme/garden_colors.dart';
import '../../../../../core/theme/garden_icons.dart';
import '../../../../../core/widgets/garden_icon.dart';

class PlantChatScreen extends ConsumerStatefulWidget {
  final String plantId;
  final VoidCallback onBack;

  const PlantChatScreen({
    super.key,
    required this.plantId,
    required this.onBack,
  });

  @override
  ConsumerState<PlantChatScreen> createState() => _PlantChatScreenState();
}

class _PlantChatScreenState extends ConsumerState<PlantChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _waitingForPlant = false;

  Plant? _plant;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _plant == null || _waitingForPlant) return;

    _textController.clear();

    // 1. Añadir mensaje del usuario al estado local
    ref.read(chatMessagesProvider(widget.plantId).notifier).addMessage(text);
    ref.read(achievementStatsProvider.notifier).recordChatMessage();
    setState(() => _waitingForPlant = true);

    // 2. Llamar al backend
    final token = ref.read(backendTokenProvider);
    final chatService = ref.read(backendChatServiceProvider);

    try {
      final response = await chatService.chat(
        plantId: widget.plantId,
        message: text,
        token: token,
      );

      if (mounted) {
        ref.read(chatMessagesProvider(widget.plantId).notifier).addMessage(
              response,
              sender: 'plant',
              source: 'ai',
              confidence: 'high',
            );
      }
    } catch (e) {
      if (mounted) {
        ref.read(chatMessagesProvider(widget.plantId).notifier).addMessage(
              'No pude conectar con el servidor. Intenta de nuevo.',
              sender: 'plant',
              source: 'error',
              confidence: 'low',
            );
      }
    } finally {
      if (mounted) {
        setState(() => _waitingForPlant = false);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final messages = ref.watch(chatMessagesProvider(widget.plantId));
    final realtimeAsync =
        ref.watch(plantRealtimeSensorProvider(widget.plantId));

    return plantsAsync.when(
      data: (plants) {
        if (plants.isEmpty) {
          _plant = null;
          return Scaffold(
            backgroundColor: const Color(0xFFFDFCF8),
            appBar: AppBar(
              leading: IconButton(
                icon: const GardenIcon(asset: GardenIcons.back, size: 22),
                onPressed: widget.onBack,
              ),
              title: const Text('Chat de planta'),
            ),
            body: const Center(
              child: Text(
                'Aun no hay plantas disponibles.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        _plant = plants.firstWhere((p) => p.id == widget.plantId,
            orElse: () => plants.first);
        final realtime = realtimeAsync.value;
        final soilMoisture =
            realtime?.soilMoisture ?? _plant!.sensors.soilMoisture;
        final temperature =
            realtime?.temperature ?? _plant!.sensors.temperature;
        final light = realtime?.light ?? _plant!.sensors.light;
        final humidity = realtime?.humidity ?? _plant!.sensors.humidity;

        return Scaffold(
          backgroundColor: const Color(0xFFFDFCF8),
          appBar: AppBar(
            leading: IconButton(
              icon: const GardenIcon(asset: GardenIcons.back, size: 22),
              onPressed: widget.onBack,
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: GardenColors.creamLight, // GardenColors.creamLight
                  child: _plant?.image.isNotEmpty == true
                      ? ClipOval(
                          child: Image.network(
                            _plant!.image,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (_, __, ___) => GardenIcon(
                              asset: _getPlantIcon(_plant?.species ?? ''),
                              size: 20,
                            ),
                          ),
                        )
                      : GardenIcon(
                          asset: _getPlantIcon(_plant?.species ?? ''),
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plant?.name ?? 'Planta',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _plant?.sensorStatus == SensorStatus.online
                          ? 'En línea'
                          : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: _plant?.sensorStatus == SensorStatus.online
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: messages.length + (_waitingForPlant ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _waitingForPlant) {
                      return const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('La planta está pensando...',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    return MessageBubble(message: messages[index]);
                  },
                ),
              ),
              if (_plant != null) ...[
                TelemetryPanel(
                  telemetryData: [
                    TelemetryData(
                      label: 'Humedad suelo',
                      value: soilMoisture,
                      min: _plant!.comfortZones.soilMoisture.min,
                      max: _plant!.comfortZones.soilMoisture.max,
                      unit: '%',
                      iconAsset: GardenIcons.water,
                      color: const Color(0xFF4A6741),
                    ),
                    TelemetryData(
                      label: 'Temperatura',
                      value: temperature,
                      min: _plant!.comfortZones.temperature.min,
                      max: _plant!.comfortZones.temperature.max,
                      unit: '°C',
                      iconAsset: GardenIcons.thermostat,
                      color: Colors.orange,
                    ),
                    TelemetryData(
                      label: 'Luz',
                      value: light,
                      min: _plant!.comfortZones.light.min,
                      max: _plant!.comfortZones.light.max,
                      unit: 'lux',
                      iconAsset: GardenIcons.sun,
                      color: Colors.amber,
                    ),
                    TelemetryData(
                      label: 'Humedad aire',
                      value: humidity,
                      min: _plant!.comfortZones.humidity.min,
                      max: _plant!.comfortZones.humidity.max,
                      unit: '%',
                      iconAsset: GardenIcons.humidity,
                      color: Colors.blue,
                    ),
                  ],
                  initiallyExpanded: false,
                ),
                const SizedBox(height: 8),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        enabled: !_waitingForPlant,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _waitingForPlant ? null : _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _waitingForPlant
                              ? Colors.grey.shade300
                              : const Color(0xFF4A6741),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const GardenIcon(asset: GardenIcons.forward, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  String _getPlantIcon(String species) =>
      GardenIcons.plantAssetForSpecies(species);
}
