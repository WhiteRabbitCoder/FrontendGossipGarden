import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gossip_garden/core/services/backend_chat_service.dart';
import '../widgets/message_bubble.dart';

final backendChatServiceProvider =
    Provider<BackendChatService>((_) => BackendChatService());

final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier,
    List<ChatMessage>, String>(
  (ref, plantId) => ChatMessagesNotifier(plantId),
);

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final String plantId;

  ChatMessagesNotifier(this.plantId) : super(const []);

  void addMessage(
    String content, {
    String sender = 'user',
    String source = 'no-data',
    String confidence = 'high',
  }) {
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

  void loadHistory(List<ChatMessage> messages) {
    state = messages;
  }
}
