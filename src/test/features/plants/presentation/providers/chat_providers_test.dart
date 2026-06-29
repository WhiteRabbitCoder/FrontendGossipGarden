import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:gossip_garden/features/plants/presentation/providers/chat_providers.dart';
import 'package:gossip_garden/features/plants/data/models/chat_dto.dart';
import 'package:gossip_garden/core/services/backend_chat_service.dart';

@GenerateMocks([BackendChatService])
import 'chat_providers_test.mocks.dart';

void main() {
  late ProviderContainer container;
  late MockBackendChatService mockChatService;
  const plantId = 'plant-123';

  setUp(() {
    mockChatService = MockBackendChatService();
    container = ProviderContainer(
      overrides: [
        backendChatServiceProvider.overrideWithValue(mockChatService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ChatMessagesNotifier', () {
    test('Initial state is loading or error if stub missing', () {
      final state = container.read(chatMessagesProvider(plantId));
      expect(state.isLoading || state.hasError, true);
    });

    test('sendMessage optimistically adds message and then updates', () async {
      when(mockChatService.chat(
        plantId: anyNamed('plantId'),
        message: anyNamed('message'),
        responseFormat: anyNamed('responseFormat'),
        imageBase64: anyNamed('imageBase64'),
        userAudioBase64: anyNamed('userAudioBase64'),
      )).thenAnswer((_) async => ChatMessageResponse(
        reply: 'Hola humano!',
        plantId: plantId,
        timestamp: DateTime.now(),
      ));

      // Fetch history initially empty
      when(mockChatService.getHistory(plantId)).thenAnswer((_) async => ChatHistoryResponse(
        plantId: plantId,
        messages: [],
      ));

      // Initialize provider
      final notifier = container.read(chatMessagesProvider(plantId).notifier);
      
      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Call send message
      final future = notifier.sendMessage('Hola planta');
      
      // Synchronously check optimistic update
      final stateWhileLoading = container.read(chatMessagesProvider(plantId));
      expect(stateWhileLoading.value!.length, 1);
      expect(stateWhileLoading.value!.first.content, 'Hola planta');
      expect(stateWhileLoading.value!.first.sender, 'user');

      // Wait for response
      await future;

      final stateAfter = container.read(chatMessagesProvider(plantId));
      expect(stateAfter.value!.length, 2);
      expect(stateAfter.value![1].content, 'Hola humano!');
      expect(stateAfter.value![1].sender, 'plant');
    });

    test('sendMessage rolls back on error', () async {
      when(mockChatService.chat(
        plantId: anyNamed('plantId'),
        message: anyNamed('message'),
        responseFormat: anyNamed('responseFormat'),
        imageBase64: anyNamed('imageBase64'),
        userAudioBase64: anyNamed('userAudioBase64'),
      )).thenThrow(Exception('DioException fake'));

      when(mockChatService.getHistory(plantId)).thenAnswer((_) async => ChatHistoryResponse(
        plantId: plantId,
        messages: [],
      ));

      final notifier = container.read(chatMessagesProvider(plantId).notifier);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // This will throw
      expect(
        () => notifier.sendMessage('Hola planta error'),
        throwsException,
      );

      // Check state is reverted
      final stateAfter = container.read(chatMessagesProvider(plantId));
      expect(stateAfter.value!.isEmpty, true);
    });
  });
}
