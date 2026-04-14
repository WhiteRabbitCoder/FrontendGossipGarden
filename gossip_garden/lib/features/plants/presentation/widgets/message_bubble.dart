import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String content;
  final String sender; // user | plant | system
  final String source; // sensor | ai | no-data
  final String confidence; // high | medium | low
  final DateTime timestamp;
  final List<MessageAction>? actions;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.source,
    required this.confidence,
    required this.timestamp,
    this.actions,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'source': source,
      'confidence': confidence,
      'timestampMs': timestamp.millisecondsSinceEpoch,
    };
  }

  static DateTime _parseTimestamp(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }

    return DateTime.now();
  }
}

class MessageAction {
  final String label;
  final VoidCallback onTap;

  MessageAction({
    required this.label,
    required this.onTap,
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  bool get isUser => message.sender == 'user';
  bool get isPlant => message.sender == 'plant';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPlant) _buildAvatar(),
          if (isPlant) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildBubble(context),
                const SizedBox(height: 6),
                if (!isUser) _buildMeta(),
                if (message.actions != null && message.actions!.isNotEmpty)
                  _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('🌿', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF4A6741) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        boxShadow: [
          if (!isUser)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            )
        ],
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildMeta() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSourceBadge(),
        const SizedBox(width: 8),
        _buildConfidence(),
      ],
    );
  }

  Widget _buildSourceBadge() {
    String label;
    Color color;

    switch (message.source) {
      case 'sensor':
        label = '📡 Sensor';
        color = Colors.green;
        break;
      case 'ai':
        label = '🧠 IA';
        color = Colors.blue;
        break;
      default:
        label = '⚠️ Sin datos';
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildConfidence() {
    String label;
    Color color;

    switch (message.confidence) {
      case 'high':
        label = 'Alta';
        color = Colors.green;
        break;
      case 'medium':
        label = 'Media';
        color = Colors.orange;
        break;
      default:
        label = 'Baja';
        color = Colors.red;
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: message.actions!
            .map(
              (action) => GestureDetector(
                onTap: action.onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6741).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    action.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4A6741),
                      fontWeight: FontWeight.w600,
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
