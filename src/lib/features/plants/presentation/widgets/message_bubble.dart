import 'package:flutter/material.dart';
import '../../../../../core/theme/garden_colors.dart';
import '../../../../../core/theme/garden_text_styles.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'voice_note_bubble.dart';

// ── Modelos ───────────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String content;
  final String sender; // user | plant | system
  final String source; // sensor | ai | backend | no-data
  final String confidence; // high | medium | low
  final DateTime timestamp;
  final List<MessageAction>? actions;
  final String? audioUrl;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.source,
    required this.confidence,
    required this.timestamp,
    this.actions,
    this.audioUrl,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> json) {
    final timestampRaw = json['timestampMs'] ?? json['timestamp'];
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      sender: json['sender']?.toString() ?? 'system',
      source: json['source']?.toString() ?? 'no-data',
      confidence: json['confidence']?.toString() ?? 'low',
      timestamp: _parseTimestamp(timestampRaw),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'sender': sender,
        'source': source,
        'confidence': confidence,
        'timestampMs': timestamp.millisecondsSinceEpoch,
      };

  static DateTime _parseTimestamp(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}

class MessageAction {
  final String label;
  final VoidCallback onTap;
  MessageAction({required this.label, required this.onTap});
}

// ── MessageBubble ─────────────────────────────────────────────────────────────

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  bool get isUser => message.sender == 'user';
  bool get isPlant => message.sender == 'plant';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isUser ? 48 : 0,
        3,
        isUser ? 0 : 48,
        3,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isPlant) _PlantAvatar(),
          if (isPlant) const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.audioUrl != null)
                  VoiceNoteBubble(
                    isUser: isUser,
                    durationSeconds: 15,
                    timestamp: "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                    transcription: message.content,
                    audioUrl: message.audioUrl,
                  )
                else
                  _Bubble(message: message, isUser: isUser),
                const SizedBox(height: 3),
                _TimestampRow(message: message, isUser: isUser),
                if (message.actions != null && message.actions!.isNotEmpty)
                  _ActionsRow(actions: message.actions!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Burbuja ───────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  const _Bubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? GardenColors.leafGreen.withValues(alpha: 0.2) : Colors.white,
        border: Border.all(color: GardenColors.ink, width: 1.5),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 0),
          bottomRight: Radius.circular(isUser ? 0 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: GardenColors.ink.withValues(alpha: 0.15),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet(
          p: GardenTextStyles.bodySmall.copyWith(
            color: const Color(0xFF2E382E), // Gris oscuro botánico
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
          strong: GardenTextStyles.bodySmall.copyWith(
            color: const Color(0xFF2E382E),
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Avatar planta ─────────────────────────────────────────────────────────────

class _PlantAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: GardenColors.leafGreen.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(color: GardenColors.ink, width: 1.5),
      ),
      child: const Center(
        child: Text('✿', style: TextStyle(fontSize: 14)),
      ),
    );
  }
}


// ── Timestamp + badge de fuente ───────────────────────────────────────────────

class _TimestampRow extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  const _TimestampRow({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (isUser) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SourceBadge(source: message.source),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      'sensor' => ('Sensor', GardenColors.leafGreen),
      'ai' || 'backend' => ('IA', GardenColors.waterBlue),
      _ => ('Sin datos', GardenColors.potOrange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GardenTextStyles.label.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Acciones rápidas ──────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  final List<MessageAction> actions;
  const _ActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: actions
            .map(
              (a) => GestureDetector(
                onTap: a.onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: GardenColors.creamLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: GardenColors.leafGreen),
                  ),
                  child: Text(
                    a.label,
                    style: GardenTextStyles.label.copyWith(
                      color: GardenColors.leafDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
