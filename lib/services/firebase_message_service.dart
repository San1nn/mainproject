import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
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
    String? senderPhotoUrl,
    required String content,
    required MessageType type,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
    Map<String, dynamic>? metadata,
    bool isAiGenerated = false,
    bool isFlagged = false,
    String? flagReason,
  }) async {
    print(
      'DEBUG: Attempting to send message. Auth UID: ${FirebaseAuth.instance.currentUser?.uid}',
    );
    try {
      final messageRef = _firestore.collection(_messagesCollection).doc();
      final now = DateTime.now();

      final messageData = {
        'id': messageRef.id,
        'roomId': roomId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'content': content,
        'type': type.toString().split('.').last,
        'timestamp': now.toIso8601String(),
        'likedByUserIds': [],
        'replyToId': replyToId,
        'replyToContent': replyToContent,
        'replyToSenderName': replyToSenderName,
        'metadata': metadata,
        'isAiGenerated': isAiGenerated,
        'isFlagged': isFlagged,
        'flagReason': flagReason,
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
        senderPhotoUrl: senderPhotoUrl,
        content: content,
        type: type,
        timestamp: now,
        replyToId: replyToId,
        replyToContent: replyToContent,
        replyToSenderName: replyToSenderName,
        metadata: metadata,
        isAiGenerated: isAiGenerated,
        isFlagged: isFlagged,
        flagReason: flagReason,
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages for a room
  Future<List<Message>> getMessages(String roomId, {int limit = 50}) async {
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
      final doc = await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .get();
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

  /// Moderator: Replace a flagged message content with a removal notice
  Future<void> moderatorDeleteMessage({
    required String messageId,
    required String roomId,
    required String moderatorName,
  }) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'content':
            '⚠️ This message was removed by moderator $moderatorName for violating community guidelines.',
        'type': 'system',
        'isFlagged': false,
        'isReported': false,
        'flagReason': null,
        'reportedByUserIds': [],
      });
    } catch (e) {
      throw Exception('Failed to delete flagged message: $e');
    }
  }

  /// Moderator: Send a warning to a user in a room
  Future<void> warnUser({
    required String roomId,
    required String targetUserName,
    required String moderatorName,
    String? reason,
  }) async {
    try {
      final warningContent = reason != null && reason.isNotEmpty
          ? '⚠️ Warning: $targetUserName has been warned by moderator $moderatorName. Reason: $reason. Please follow community guidelines.'
          : '⚠️ Warning: $targetUserName has been warned by moderator $moderatorName. Please follow community guidelines.';

      await sendMessage(
        roomId: roomId,
        senderId: 'system',
        senderName: 'System',
        content: warningContent,
        type: MessageType.system,
      );
    } catch (e) {
      throw Exception('Failed to warn user: $e');
    }
  }

  /// Moderator: Dismiss a flag / clear moderation status on a message
  Future<void> dismissFlag(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'isFlagged': false,
        'isReported': false,
        'flagReason': null,
        'reportedByUserIds': [],
      });
    } catch (e) {
      throw Exception('Failed to dismiss flag: $e');
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
        final likedByUserIds = List<String>.from(
          doc.data()?['likedByUserIds'] ?? [],
        );

        if (likedByUserIds.contains(userId)) {
          likedByUserIds.remove(userId);
        } else {
          likedByUserIds.add(userId);
        }

        await _firestore.collection(_messagesCollection).doc(messageId).update({
          'likedByUserIds': likedByUserIds,
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Report a message for moderator review
  Future<void> reportMessage(String messageId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .get();

      if (doc.exists) {
        final reportedByUserIds = List<String>.from(
          doc.data()?['reportedByUserIds'] ?? [],
        );

        if (!reportedByUserIds.contains(userId)) {
          reportedByUserIds.add(userId);
          await _firestore
              .collection(_messagesCollection)
              .doc(messageId)
              .update({
                'isReported': true,
                'reportedByUserIds': reportedByUserIds,
              });
        }
      }
    } catch (e) {
      throw Exception('Failed to report message: $e');
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
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _messageFromDoc(doc)).toList(),
        );
  }

  /// Watch for flagged or reported messages in specific rooms
  Stream<List<Message>> watchFlaggedMessages(List<String> roomIds) {
    if (roomIds.isEmpty) return Stream.value([]);

    // Firestore 'whereIn' is limited to 30 items
    final chunks = <List<String>>[];
    for (var i = 0; i < roomIds.length; i += 30) {
      chunks.add(
        roomIds.sublist(i, i + 30 > roomIds.length ? roomIds.length : i + 30),
      );
    }

    // Use a reactive combined filter
    return _firestore
        .collection(_messagesCollection)
        .where('roomId', whereIn: chunks.first)
        .where(
          Filter.or(
            Filter('isFlagged', isEqualTo: true),
            Filter('isReported', isEqualTo: true),
          ),
        )
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => _messageFromDoc(doc))
              .toList();
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages.take(10).toList();
        });
  }

  /// Watch recent messages across multiple rooms (for activity feed)
  Stream<List<Message>> watchRecentMessages(
    List<String> roomIds, {
    String? excludeSenderId,
    int limit = 15,
  }) {
    if (roomIds.isEmpty) return Stream.value([]);

    // Firestore 'whereIn' is limited to 30 items
    final chunks = <List<String>>[];
    for (var i = 0; i < roomIds.length; i += 30) {
      chunks.add(
        roomIds.sublist(i, i + 30 > roomIds.length ? roomIds.length : i + 30),
      );
    }

    return _firestore
        .collection(_messagesCollection)
        .where('roomId', whereIn: chunks.first)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          var messages = snapshot.docs
              .map((doc) => _messageFromDoc(doc))
              .toList();
          // Exclude current user's own messages if specified
          if (excludeSenderId != null) {
            messages = messages
                .where((m) => m.senderId != excludeSenderId)
                .toList();
          }
          return messages;
        });
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
      senderPhotoUrl: data['senderPhotoUrl'],
      content: data['content'] ?? '',
      type: _parseMessageType(data['type'] ?? 'text'),
      timestamp: DateTime.parse(
        data['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      editedAt: data['editedAt'] != null
          ? DateTime.parse(data['editedAt'])
          : null,
      likedByUserIds: List<String>.from(data['likedByUserIds'] ?? []),
      replyToId: data['replyToId'],
      replyToContent: data['replyToContent'],
      replyToSenderName: data['replyToSenderName'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      isAiGenerated: data['isAiGenerated'] ?? false,
      isFlagged: data['isFlagged'] ?? false,
      flagReason: data['flagReason'],
      isReported: data['isReported'] ?? false,
      reportedByUserIds: List<String>.from(data['reportedByUserIds'] ?? []),
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
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}
