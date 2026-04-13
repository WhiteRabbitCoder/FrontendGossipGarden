import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/message_bubble.dart';

final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier,
    List<ChatMessage>, String>(
  (ref, plantId) => ChatMessagesNotifier(plantId),
);

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final String plantId;

  ChatMessagesNotifier(this.plantId) : super(_generateMockMessages(plantId));

  static List<ChatMessage> _generateMockMessages(String plantId) {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: '1',
        content:
            '¡Hola! Soy tu planta. Mi humedad del suelo está al 28%, tengo sed.',
        sender: 'plant',
        source: 'sensor',
        confidence: 'high',
        timestamp: now.subtract(const Duration(minutes: 5)),
        actions: [
          MessageAction(label: 'Regar ahora', onTap: () {}),
          MessageAction(label: 'Más detalles', onTap: () {}),
        ],
      ),
      ChatMessage(
        id: '2',
        content: 'Vale, voy a regarte ahora mismo.',
        sender: 'user',
        source: 'no-data',
        confidence: 'high',
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
      ChatMessage(
        id: '3',
        content: '¡Gracias! La humedad ya subió al 45%. Me siento mejor.',
        sender: 'plant',
        source: 'ai',
        confidence: 'medium',
        timestamp: now.subtract(const Duration(minutes: 1)),
        actions: [
          MessageAction(label: 'Ver telemetría', onTap: () {}),
        ],
      ),
    ];
  }

  void addMessage(String content,
      {String sender = 'user',
      String source = 'no-data',
      String confidence = 'high'}) {
    final newMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      sender: sender,
      source: source,
      confidence: confidence,
      timestamp: DateTime.now(),
    );
    state = [...state, newMessage];
  }

  void clearMessages() {
    state = [];
  }
}
