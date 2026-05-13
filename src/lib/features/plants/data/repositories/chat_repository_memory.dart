import 'dart:async';

import '../../presentation/widgets/message_bubble.dart';
import 'chat_repository.dart';

class MemoryChatRepository implements ChatRepository {
  final Map<String, List<ChatMessage>> _messagesByPlant = {};
  final Map<String, StreamController<List<ChatMessage>>> _controllers = {};

  @override
  Stream<List<ChatMessage>> watchMessages(String plantId) {
    final controller = _controllers.putIfAbsent(
      plantId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );

    controller.add(_messagesByPlant[plantId] ?? _seedMessages(plantId));
    return controller.stream;
  }

  @override
  Future<void> sendMessage(String plantId, ChatMessage message) async {
    final current = List<ChatMessage>.from(
        _messagesByPlant[plantId] ?? _seedMessages(plantId));
    current.add(message);
    _messagesByPlant[plantId] = current;
    _controllers[plantId]?.add(current);
  }

  List<ChatMessage> _seedMessages(String plantId) {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'seed-$plantId',
        content:
            'Hola, soy la planta $plantId. ¿Me ayudas a revisar mi telemetria?',
        sender: 'plant',
        source: 'sensor',
        confidence: 'high',
        timestamp: now.subtract(const Duration(minutes: 10)),
      ),
    ];
  }
}
