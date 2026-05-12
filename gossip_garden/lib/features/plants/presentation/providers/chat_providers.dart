import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gossip_garden/core/config/firebase_environment.dart';
import 'package:gossip_garden/core/services/backend_chat_service.dart';

import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_firestore.dart';
import '../../data/repositories/chat_repository_memory.dart';
import '../widgets/message_bubble.dart';

final backendChatServiceProvider =
    Provider<BackendChatService>((_) => BackendChatService());

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (FirebaseEnvironment.isConfigured) {
    return FirestoreChatRepository(FirebaseFirestore.instance);
  }

  return MemoryChatRepository();
});

final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier,
    List<ChatMessage>, String>(
  (ref, plantId) => ChatMessagesNotifier(
    plantId,
    ref.read(chatRepositoryProvider),
  ),
);

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final String plantId;
  final ChatRepository _repository;
  StreamSubscription<List<ChatMessage>>? _subscription;

  ChatMessagesNotifier(this.plantId, this._repository)
      : super(_generateMockMessages(plantId)) {
    _subscription = _repository.watchMessages(plantId).listen((messages) {
      syncMessages(messages);
    });
  }

  static List<ChatMessage> _generateMockMessages(String plantId) {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: '1',
        content: 'Soy Monducuru. Opuntia monacantha. Llevo aquí más tiempo del que imaginas.',
        sender: 'plant',
        source: 'sensor',
        confidence: 'high',
        timestamp: now.subtract(const Duration(minutes: 12)),
      ),
      ChatMessage(
        id: '2',
        content: 'Mi tierra está al 31% de humedad. Para un cactus de mi posición, perfecto. No me eches agua — te lo advierto.',
        sender: 'plant',
        source: 'sensor',
        confidence: 'high',
        timestamp: now.subtract(const Duration(minutes: 4)),
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
    _repository.sendMessage(plantId, newMessage);
  }

  void syncMessages(List<ChatMessage> messages) {
    state = messages;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
