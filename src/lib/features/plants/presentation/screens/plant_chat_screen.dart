import 'dart:math' as math;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gossip_garden/core/services/audio_helper.dart';
import '../../../../core/widgets/in_app_camera_screen.dart';
import '../providers/plant_providers.dart';
import '../providers/chat_providers.dart';
import '../providers/achievement_providers.dart';
import '../widgets/message_bubble.dart';
import '../../data/models/plant.dart';
import '../../data/models/plant_enums.dart';
import '../../../../../core/theme/garden_colors.dart';
import '../../../../../core/theme/garden_icons.dart';
import '../../../../../core/theme/garden_text_styles.dart';
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

class _PlantChatScreenState extends ConsumerState<PlantChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _waitingForPlant = false;
  bool _isRecording = false;
  bool _hasText = false;

  late final AnimationController _floatController;
  late final AnimationController _micPulseController;
  late final AudioHelper _audioHelper;

  Plant? _plant;

  @override
  void initState() {
    super.initState();
    _audioHelper = AudioHelper();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _floatController.dispose();
    _micPulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _sendMessage({String? text, String? audioUrl, String? imageBase64}) async {
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty && imageBase64 == null) return;
    if (_plant == null || _waitingForPlant) return;

    if (text == null && imageBase64 == null) _textController.clear();
    setState(() => _waitingForPlant = true);

    try {
      await ref
          .read(chatMessagesProvider(widget.plantId).notifier)
          .sendMessage(
            messageText.isNotEmpty ? messageText : 'Te envío esta foto de la planta.',
            responseFormat: audioUrl != null ? 'audio' : 'text',
            audioUrl: audioUrl,
            imageBase64: imageBase64,
          );
      ref.read(achievementStatsProvider.notifier).recordChatMessage();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al enviar el mensaje'),
            backgroundColor: GardenColors.heartRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _waitingForPlant = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      // Detener grabación y procesar audio
      setState(() {
        _isRecording = false;
        _waitingForPlant = true;
      });
      _micPulseController.stop();
      _micPulseController.reset();

      try {
        final result = await _audioHelper.stopRecording();
        if (mounted) {
          _textController.clear();
          if (result.audioUrl.isNotEmpty) {
            await _sendMessage(
              text: result.transcription,
              audioUrl: result.audioUrl,
            );
          } else {
            setState(() => _waitingForPlant = false);
          }
        }
      } catch (e) {
        print('Error al detener la grabación: $e');
        if (mounted) {
          setState(() => _waitingForPlant = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al procesar la grabación de voz'),
              backgroundColor: GardenColors.heartRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
      }
    } else {
      // Iniciar grabación real
      try {
        setState(() => _isRecording = true);
        _micPulseController.repeat(reverse: true);
        
        await _audioHelper.startRecording(
          onTranscriptionUpdated: (interimText) {
            if (mounted) {
              setState(() {
                _textController.text = interimText;
              });
            }
          },
        );
      } catch (e) {
        print('Error al iniciar la grabación: $e');
        if (mounted) {
          setState(() {
            _isRecording = false;
            _micPulseController.stop();
            _micPulseController.reset();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No se pudo acceder al micrófono. Verifica los permisos.'),
              backgroundColor: GardenColors.heartRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    File? file;
    if (source == ImageSource.camera) {
      file = await Navigator.push<File?>(
        context,
        MaterialPageRoute(builder: (_) => const InAppCameraScreen()),
      );
    } else {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        file = File(pickedFile.path);
      }
    }

    if (file != null && mounted) {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // Enviar la foto con un mensaje predeterminado si el usuario no escribe nada
      final currentText = _textController.text.trim();
      _textController.clear();
      
      await _sendMessage(
        text: currentText.isNotEmpty ? currentText : 'Aquí tienes una foto de mi planta, ¿cómo la ves?',
        imageBase64: base64String,
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachmentSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
      ),
    );
  }

  void _showChatSettings(Plant plant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatSettingsSheet(plant: plant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.plantId));
    final messages = messagesAsync.value ?? [];
    final realtimeAsync =
        ref.watch(plantRealtimeSensorProvider(widget.plantId));

    return plantsAsync.when(
      data: (plants) {
        if (plants.isEmpty) {
          return Scaffold(
            backgroundColor: GardenColors.creamPaper,
            appBar: _buildAppBar(null),
            body: const Center(child: Text('Aún no hay plantas disponibles.')),
          );
        }

        _plant = plants.firstWhere((p) => p.id == widget.plantId,
            orElse: () => plants.first);

        final realtime = realtimeAsync.value;
        final soilMoisture =
            realtime?.soilMoisture ?? _plant!.sensors.soilMoisture;
        final temperature =
            realtime?.temperature ?? _plant!.sensors.temperature;
        final humidity = realtime?.humidity ?? _plant!.sensors.humidity;

        return Scaffold(
          backgroundColor: GardenColors.creamPaper,
          appBar: _buildAppBar(_plant, soilMoisture: soilMoisture, temperature: temperature, humidity: humidity),
          body: Column(
            children: [
              // ── Lista de mensajes con fondo animado ─────────────────────
              Expanded(
                child: Stack(
                  children: [
                    // Fondo de imagen
                    Positioned.fill(
                      child: Image.asset(
                        'images/FondoChatGossipGarden.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Mensajes
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                      itemCount:
                          messages.length + (_waitingForPlant ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length && _waitingForPlant) {
                          return _ThinkingBubble(plant: _plant);
                        }
                        return MessageBubble(message: messages[index]);
                      },
                    ),
                  ],
                ),
              ),

              // ── Input bar ────────────────────────────────────────────────
              _ChatInputBar(
                controller: _textController,
                hasText: _hasText,
                isWaiting: _waitingForPlant,
                isRecording: _isRecording,
                micPulseController: _micPulseController,
                onSend: () => _sendMessage(),
                onMicToggle: _toggleRecording,
                onAttachmentTap: _showAttachmentOptions,
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: GardenColors.creamPaper,
        body: Center(
            child:
                CircularProgressIndicator(color: GardenColors.leafGreen)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: GardenColors.creamPaper,
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Plant? plant, {double? soilMoisture, double? temperature, double? humidity}) {
    final isOnline = plant?.sensorStatus == SensorStatus.online;
    return AppBar(
      backgroundColor: GardenColors.creamPaper,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: GardenColors.ink),
      leading: IconButton(
        icon: const GardenIcon(asset: GardenIcons.back, size: 20),
        onPressed: widget.onBack,
      ),
      title: GestureDetector(
        onTap: plant != null ? () => _showChatSettings(plant) : null,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GardenColors.creamLight,
                shape: BoxShape.circle,
                border: Border.all(color: GardenColors.dustLight, width: 1.5),
              ),
              child: ClipOval(
                child: plant?.image.isNotEmpty == true
                    ? Image.network(
                        plant!.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => GardenIcon(
                          asset: GardenIcons.plantAssetForSpecies(
                              plant.species),
                          size: 22,
                        ),
                      )
                    : GardenIcon(
                        asset: GardenIcons.plantAssetForSpecies(
                            plant?.species ?? ''),
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            // Nombre + estado
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant?.name ?? 'Planta',
                    style: GardenTextStyles.title.copyWith(
                      color: GardenColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (soilMoisture != null && temperature != null && humidity != null)
                    Row(
                      children: [
                        Text(
                          '💧 ${soilMoisture.toStringAsFixed(0)}%  🌡️ ${temperature.toStringAsFixed(1)}°C  🌧️ ${humidity.toStringAsFixed(0)}%',
                          style: GardenTextStyles.label.copyWith(
                            color: GardenColors.inkSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? GardenColors.leafGreen
                                : GardenColors.dustLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isOnline ? 'En línea' : 'Sin conexión',
                          style: GardenTextStyles.label.copyWith(
                            color: GardenColors.inkSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Chevron hint -> 3 dots
            if (plant != null)
              const Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: GardenColors.inkSoft,
              ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: GardenColors.dustLight),
      ),
    );
  }
}

// ── Animated Chat Background (WOW Effect) ───────────────────────────────────

// Animacion borrada

// ── Thinking bubble ───────────────────────────────────────────────────────────

class _ThinkingBubble extends StatefulWidget {
  final Plant? plant;
  const _ThinkingBubble({this.plant});

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 60, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: GardenColors.creamLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('🌿', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: GardenColors.creamLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: GardenColors.dustLight),
            ),
            child: AnimatedBuilder(
              animation: _dotController,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i / 3;
                    final t = (_dotController.value - delay).clamp(0.0, 1.0);
                    final opacity = math.sin(t * math.pi).clamp(0.3, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: GardenColors.inkSoft,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Input Bar ────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final bool isWaiting;
  final bool isRecording;
  final AnimationController micPulseController;
  final VoidCallback onSend;
  final VoidCallback onMicToggle;
  final VoidCallback onAttachmentTap;

  const _ChatInputBar({
    required this.controller,
    required this.hasText,
    required this.isWaiting,
    required this.isRecording,
    required this.micPulseController,
    required this.onSend,
    required this.onMicToggle,
    required this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: GardenColors.cream,
        border: Border(top: BorderSide(color: GardenColors.dustLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Botón Adjuntar Foto ───────────────────────────────────────────
          GestureDetector(
            onTap: onAttachmentTap,
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(bottom: 2, right: 8),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: GardenColors.inkSoft,
                size: 24,
              ),
            ),
          ),
          
          // ── Campo de texto ───────────────────────────────────────────
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                enabled: !isWaiting,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: isRecording
                      ? 'Escuchando...'
                      : 'Escribe algo a tu planta…',
                  hintStyle: GardenTextStyles.bodySmall.copyWith(
                    color: GardenColors.inkSoft.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                ),
                style: GardenTextStyles.bodySmall.copyWith(
                  color: GardenColors.ink,
                  fontSize: 15,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Botón: enviar (si hay texto) o micrófono ─────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: (hasText && !isRecording)
                ? _SendButton(key: const ValueKey('send'), onTap: onSend)
                : _MicButton(
                    key: const ValueKey('mic'),
                    isRecording: isRecording,
                    pulseController: micPulseController,
                    onTap: onMicToggle,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: GardenColors.leafGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: GardenColors.leafGreen.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isRecording;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const _MicButton({
    super.key,
    required this.isRecording,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (_, child) {
          final scale = isRecording
              ? 1.0 + pulseController.value * 0.12
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isRecording
                ? GardenColors.heartRed
                : GardenColors.creamLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: isRecording
                  ? GardenColors.heartRed
                  : GardenColors.dustLight,
            ),
            boxShadow: isRecording
                ? [
                    BoxShadow(
                      color: GardenColors.heartRed.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Icon(
            isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            color: isRecording ? Colors.white : GardenColors.inkSoft,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── Chat Settings Sheet ───────────────────────────────────────────────────────

class _ChatSettingsSheet extends StatelessWidget {
  final Plant plant;
  const _ChatSettingsSheet({required this.plant});

  @override
  Widget build(BuildContext context) {
    final isOnline = plant.sensorStatus == SensorStatus.online;

    return Container(
      decoration: const BoxDecoration(
        color: GardenColors.creamPaper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: GardenColors.dustLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar grande
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: GardenColors.creamLight,
              shape: BoxShape.circle,
              border: Border.all(color: GardenColors.dustLight, width: 2),
            ),
            child: ClipOval(
              child: plant.image.isNotEmpty
                  ? Image.network(
                      plant.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => GardenIcon(
                        asset: GardenIcons.plantAssetForSpecies(plant.species),
                        size: 36,
                      ),
                    )
                  : GardenIcon(
                      asset: GardenIcons.plantAssetForSpecies(plant.species),
                      size: 36,
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Nombre
          Text(
            plant.name,
            style: GardenTextStyles.display.copyWith(
              color: GardenColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plant.species,
            style: GardenTextStyles.bodySmall.copyWith(
              color: GardenColors.inkSoft,
            ),
          ),
          const SizedBox(height: 20),

          // Info básica en lista
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GardenColors.dustLight),
            ),
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.circle,
                  iconColor: isOnline ? GardenColors.leafGreen : GardenColors.dust,
                  label: 'Sensor',
                  value: isOnline ? 'En línea' : 'Sin conexión',
                ),
                _Divider(),
                _SettingsRow(
                  icon: Icons.favorite_rounded,
                  iconColor: GardenColors.heartRed,
                  label: 'Salud',
                  value: '${plant.health.toInt()}%',
                ),
                _Divider(),
                _SettingsRow(
                  icon: Icons.tag_rounded,
                  iconColor: GardenColors.potOrange,
                  label: 'ID de planta',
                  value: '${plant.id.substring(0, 8)}…',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: GardenColors.creamLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GardenColors.dustLight),
                ),
                child: Text(
                  'Cerrar',
                  style: GardenTextStyles.label.copyWith(
                    color: GardenColors.inkSoft,
                    fontWeight: FontWeight.w600,
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

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 12),
          Text(
            label,
            style: GardenTextStyles.bodySmall.copyWith(
              color: GardenColors.inkSoft,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GardenTextStyles.bodySmall.copyWith(
              color: GardenColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: GardenColors.dustLight,
        margin: const EdgeInsets.symmetric(horizontal: 16),
      );
}

// ── Opciones de adjuntar ──────────────────────────────────────────────────────

class _AttachmentSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _AttachmentSheet({
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: GardenColors.creamPaper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: GardenColors.dustLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachmentOption(
                icon: Icons.camera_alt_rounded,
                label: 'Cámara',
                color: GardenColors.heartRed,
                onTap: onCamera,
              ),
              _AttachmentOption(
                icon: Icons.photo_library_rounded,
                label: 'Galería',
                color: GardenColors.waterBlue,
                onTap: onGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GardenTextStyles.bodySmall.copyWith(
              color: GardenColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
