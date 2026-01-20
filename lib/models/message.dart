/// Enum for message types
enum MessageType { text, voice, image, file }

/// Message model for room communications
class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final DateTime? editedAt;
  final List<String>? likedByUserIds;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.editedAt,
    this.likedByUserIds,
  });

  /// Check if message was edited
  bool get isEdited => editedAt != null;

  /// Get like count
  int get likeCount => likedByUserIds?.length ?? 0;

  /// Check if user has liked this message
  bool isLikedBy(String userId) {
    return likedByUserIds?.contains(userId) ?? false;
  }

  /// Create a copy with modified fields
  Message copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    DateTime? editedAt,
    List<String>? likedByUserIds,
  }) {
    return Message(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
    );
  }

  @override
  String toString() =>
      'Message(id: $id, roomId: $roomId, sender: $senderName, type: $type)';
}
