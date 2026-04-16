import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_providers.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/telemetry_panel.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';

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

  Plant? _plant;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _plant == null) return;

    ref.read(chatMessagesProvider(widget.plantId).notifier).addMessage(text);
    _textController.clear();
    setState(() {});

    // Simular respuesta de la planta después de un retraso
    Future.delayed(const Duration(seconds: 1), () {
      ref.read(chatMessagesProvider(widget.plantId).notifier).addMessage(
            '¡Gracias por tu mensaje! Mi sensor de humedad marca ${_plant?.sensors.soilMoisture.toStringAsFixed(1)}%.',
            sender: 'plant',
            source: 'sensor',
            confidence: 'high',
          );
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final messages = ref.watch(chatMessagesProvider(widget.plantId));
    final realtimeAsync = ref.watch(
      plantRealtimeSensorProvider(int.tryParse(widget.plantId) ?? 0),
    );

    return plantsAsync.when(
      data: (plants) {
        if (plants.isEmpty) {
          _plant = null;
          return Scaffold(
            backgroundColor: const Color(0xFFFDFCF8),
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
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
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4A6741).withOpacity(0.1),
                  child: Text(_plant?.name.substring(0, 1) ?? 'P'),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  // Mostrar panel de telemetría
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      MessageBubble(message: messages[index]),
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
                      icon: Icons.water_drop,
                      color: const Color(0xFF4A6741),
                    ),
                    TelemetryData(
                      label: 'Temperatura',
                      value: temperature,
                      min: _plant!.comfortZones.temperature.min,
                      max: _plant!.comfortZones.temperature.max,
                      unit: '°C',
                      icon: Icons.thermostat,
                      color: Colors.orange,
                    ),
                    TelemetryData(
                      label: 'Luz',
                      value: light,
                      min: _plant!.comfortZones.light.min,
                      max: _plant!.comfortZones.light.max,
                      unit: 'lux',
                      icon: Icons.light_mode,
                      color: Colors.amber,
                    ),
                    TelemetryData(
                      label: 'Humedad aire',
                      value: humidity,
                      min: _plant!.comfortZones.humidity.min,
                      max: _plant!.comfortZones.humidity.max,
                      unit: '%',
                      icon: Icons.cloud,
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
                      onTap: _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A6741),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.send, color: Colors.white),
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
}
