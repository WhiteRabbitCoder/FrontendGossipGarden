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

final plantVoicesProvider = StateNotifierProvider.family<PlantVoicesNotifier, AsyncValue<dto.VoicesResponse>, String>(
  (ref, plantId) => PlantVoicesNotifier(plantId, ref.read(backendChatServiceProvider)),
);

class PlantVoicesNotifier extends StateNotifier<AsyncValue<dto.VoicesResponse>> {
  final String plantId;
  final BackendChatService _chatService;

  PlantVoicesNotifier(this.plantId, this._chatService) : super(const AsyncValue.loading()) {
    _fetchVoices();
  }

  Future<void> _fetchVoices() async {
    try {
      final response = await _chatService.getVoices(plantId);
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setVoice(String voiceId) async {
    final currentData = state.value;
    if (currentData == null) return;
    
    // Optimistic update
    state = AsyncValue.data(dto.VoicesResponse(
      plantId: currentData.plantId,
      currentVoiceId: voiceId,
      options: currentData.options,
    ));

    try {
      final response = await _chatService.setVoice(plantId, voiceId);
      state = AsyncValue.data(response);
    } catch (e) {
      state = AsyncValue.data(currentData);
      rethrow;
    }
  }
}

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
      final messages = history.messages.asMap().entries.map((entry) {
        final i = entry.key;
        final dtoMsg = entry.value;
        return ChatMessage(
          id: '${DateTime.now().microsecondsSinceEpoch}_$i',
          content: dtoMsg.content,
          sender: dtoMsg.role == 'assistant' ? 'plant' : 'user',
          source: 'backend',
          confidence: 'high',
          timestamp: dtoMsg.timestamp,
          imageUrl: dtoMsg.userImageUrl,
          audioUrl: dtoMsg.audioUrl,
        );
      }).toList();
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(
    String content, {
    String responseFormat = 'text',
    String? audioUrl,
    String? imageBase64,
    String? userAudioBase64,
  }) async {
    final currentMessages = state.value ?? [];
    
    // Optimistic UI update
    final initialContent = userAudioBase64 != null ? "Transcribiendo audio... ⏳" : content;
    final newMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: initialContent,
      sender: 'user',
      source: 'no-data',
      confidence: 'high',
      timestamp: DateTime.now(),
      audioUrl: audioUrl,
      imageBase64: imageBase64,
    );
    state = AsyncValue.data([...currentMessages, newMessage]);

    try {
      String finalContent = content;
      if (userAudioBase64 != null) {
        finalContent = await _chatService.transcribeAudio(userAudioBase64);
        
        // Actualizar UI con la transcripción antes de llamar al LLM
        final updatedMessages = (state.value ?? []).map((m) {
          if (m.id == newMessage.id) {
            return ChatMessage(
              id: m.id,
              content: finalContent,
              sender: m.sender,
              source: m.source,
              confidence: m.confidence,
              timestamp: m.timestamp,
              audioUrl: m.audioUrl,
              imageBase64: m.imageBase64,
            );
          }
          return m;
        }).toList();
        state = AsyncValue.data(updatedMessages);
      }

      final response = await _chatService.chat(
        plantId: plantId, 
        message: finalContent, 
        responseFormat: responseFormat,
        imageBase64: imageBase64,
        userAudioBase64: userAudioBase64,
      );
      
      final replyMessage = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: response.reply,
        sender: 'plant',
        source: 'backend',
        confidence: 'high',
        timestamp: response.timestamp,
        audioUrl: response.audioUrl,
      );

      final updatedMessages = (state.value ?? []).map((m) {
        if (m.id == newMessage.id) {
          return ChatMessage(
            id: m.id,
            content: m.content,
            sender: m.sender,
            source: m.source,
            confidence: m.confidence,
            timestamp: m.timestamp,
            audioUrl: m.audioUrl,
            imageUrl: response.userImageUrl,
          );
        }
        return m;
      }).toList();
      state = AsyncValue.data([...updatedMessages, replyMessage]);
    } catch (e) {
      // Revert or show error
      state = AsyncValue.data(currentMessages);
      rethrow;
    }
  }
}
