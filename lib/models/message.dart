/// Enum for message types
enum MessageType { text, voice, image, file, system }

/// Message model for room communications
class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final DateTime? editedAt;
  final List<String>? likedByUserIds;

  /// For message threading/replies
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderName;

  /// For media and system metadata (duration, file size, etc)
  final Map<String, dynamic>? metadata;

  /// AI and Moderation flags
  final bool isAiGenerated;
  final bool isFlagged;
  final String? flagReason;
  final bool isReported;
  final List<String>? reportedByUserIds;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.type,
    required this.timestamp,
    this.editedAt,
    this.likedByUserIds,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
    this.metadata,
    this.isAiGenerated = false,
    this.isFlagged = false,
    this.flagReason,
    this.isReported = false,
    this.reportedByUserIds,
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
    String? senderPhotoUrl,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    DateTime? editedAt,
    List<String>? likedByUserIds,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
    Map<String, dynamic>? metadata,
    bool? isAiGenerated,
    bool? isFlagged,
    String? flagReason,
    bool? isReported,
    List<String>? reportedByUserIds,
  }) {
    return Message(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      metadata: metadata ?? this.metadata,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      isFlagged: isFlagged ?? this.isFlagged,
      flagReason: flagReason ?? this.flagReason,
      isReported: isReported ?? this.isReported,
      reportedByUserIds: reportedByUserIds ?? this.reportedByUserIds,
    );
  }

  @override
  String toString() =>
      'Message(id: $id, roomId: $roomId, sender: $senderName, type: $type, isAi: $isAiGenerated, isFlagged: $isFlagged, isReported: $isReported)';
}
