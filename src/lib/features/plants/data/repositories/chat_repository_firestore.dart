import 'package:cloud_firestore/cloud_firestore.dart';

import '../../presentation/widgets/message_bubble.dart';
import 'chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _messagesRef(String plantId) {
    return _firestore.collection('plants').doc(plantId).collection('messages');
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String plantId) {
    return _messagesRef(plantId).orderBy('timestampMs').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<void> sendMessage(String plantId, ChatMessage message) async {
    await _messagesRef(plantId).doc(message.id).set(message.toMap());
  }
}
