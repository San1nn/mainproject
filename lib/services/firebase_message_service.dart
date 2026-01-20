import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mainproject/models/message.dart';

/// Firebase Message Service for managing messages
class FirebaseMessageService {
  static final FirebaseMessageService _instance =
      FirebaseMessageService._internal();

  factory FirebaseMessageService() {
    return _instance;
  }

  FirebaseMessageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _messagesCollection = 'messages';

  /// Send a message
  Future<Message> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    required MessageType type,
  }) async {
    try {
      final messageRef = _firestore.collection(_messagesCollection).doc();
      final now = DateTime.now();

      final messageData = {
        'id': messageRef.id,
        'roomId': roomId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type.toString().split('.').last,
        'timestamp': now.toIso8601String(),
        'likedByUserIds': [],
      };

      await messageRef.set(messageData);

      // Update room's last message info
      await _firestore.collection('rooms').doc(roomId).update({
        'lastMessagePreview': content.length > 50
            ? '${content.substring(0, 50)}...'
            : content,
        'lastMessageTime': now.toIso8601String(),
      });

      return Message(
        id: messageRef.id,
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: type,
        timestamp: now,
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages for a room
  Future<List<Message>> getMessages(String roomId,
      {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .where('roomId', isEqualTo: roomId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => _messageFromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  /// Get message by ID
  Future<Message?> getMessageById(String messageId) async {
    try {
      final doc =
          await _firestore.collection(_messagesCollection).doc(messageId).get();
      if (doc.exists) {
        return _messageFromDoc(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch message: $e');
    }
  }

  /// Edit a message
  Future<Message> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'content': newContent,
        'editedAt': now.toIso8601String(),
      });

      final updatedMessage = await getMessageById(messageId);
      if (updatedMessage == null) throw Exception('Message not found');
      return updatedMessage;
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Like/Unlike a message
  Future<void> toggleLikeMessage(String messageId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .get();

      if (doc.exists) {
        final likedByUserIds =
            List<String>.from(doc.data()?['likedByUserIds'] ?? []);

        if (likedByUserIds.contains(userId)) {
          likedByUserIds.remove(userId);
        } else {
          likedByUserIds.add(userId);
        }

        await _firestore
            .collection(_messagesCollection)
            .doc(messageId)
            .update({'likedByUserIds': likedByUserIds});
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Watch messages for a room in real-time
  Stream<List<Message>> watchRoomMessages(String roomId, {int limit = 50}) {
    return _firestore
        .collection(_messagesCollection)
        .where('roomId', isEqualTo: roomId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _messageFromDoc(doc)).toList());
  }

  /// Get message count for a room
  Future<int> getMessageCount(String roomId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .where('roomId', isEqualTo: roomId)
          .count()
          .get();
      return querySnapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get message count: $e');
    }
  }

  /// Delete all messages for a room
  Future<void> deleteRoomMessages(String roomId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .where('roomId', isEqualTo: roomId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete room messages: $e');
    }
  }

  /// Convert Firestore document to Message model
  Message _messageFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: data['id'] ?? doc.id,
      roomId: data['roomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Anonymous',
      content: data['content'] ?? '',
      type: _parseMessageType(data['type'] ?? 'text'),
      timestamp: DateTime.parse(
        data['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      editedAt: data['editedAt'] != null
          ? DateTime.parse(data['editedAt'])
          : null,
      likedByUserIds: List<String>.from(data['likedByUserIds'] ?? []),
    );
  }

  /// Parse message type from string
  MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'voice':
        return MessageType.voice;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}
