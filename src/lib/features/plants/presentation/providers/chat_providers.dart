import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gossip_garden/core/config/firebase_environment.dart';
import 'package:gossip_garden/core/services/backend_chat_service.dart';

import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_firestore.dart';
import '../../data/repositories/chat_repository_memory.dart';
import '../../data/models/chat_dto.dart' as dto;
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
    AsyncValue<List<ChatMessage>>, String>(
  (ref, plantId) => ChatMessagesNotifier(
    plantId,
    ref.read(backendChatServiceProvider),
  ),
);

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final String plantId;
  final BackendChatService _chatService;

  ChatMessagesNotifier(this.plantId, this._chatService)
      : super(const AsyncValue.loading()) {
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await _chatService.getHistory(plantId);
      final messages = history.messages.map((dtoMsg) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(), // Temporary
        content: dtoMsg.content,
        sender: dtoMsg.role == 'assistant' ? 'plant' : 'user',
        source: 'backend',
        confidence: 'high',
        timestamp: dtoMsg.timestamp,
      )).toList();
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(String content) async {
    final currentMessages = state.value ?? [];
    
    // Optimistic UI update
    final newMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      sender: 'user',
      source: 'no-data',
      confidence: 'high',
      timestamp: DateTime.now(),
    );
    state = AsyncValue.data([...currentMessages, newMessage]);

    try {
      final response = await _chatService.chat(plantId: plantId, message: content);
      
      final replyMessage = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: response.reply,
        sender: 'plant',
        source: 'backend',
        confidence: 'high',
        timestamp: response.timestamp,
      );

      final updatedMessages = state.value ?? [];
      state = AsyncValue.data([...updatedMessages, replyMessage]);
    } catch (e) {
      // Revert or show error
      state = AsyncValue.data(currentMessages);
      rethrow;
    }
  }
}
