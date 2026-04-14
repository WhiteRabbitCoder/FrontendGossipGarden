import '../../presentation/widgets/message_bubble.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> watchMessages(String plantId);

  Future<void> sendMessage(String plantId, ChatMessage message);
}
