/// Enum for room types
enum RoomType { public, private }

/// Room model for discussions and group communication
class Room {
  final String id;
  final String name;
  final String description;
  final RoomType type;
  final String creatorId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastMessagePreview;
  final DateTime? lastMessageTime;

  Room({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.creatorId,
    required this.memberIds,
    required this.createdAt,
    this.updatedAt,
    this.lastMessagePreview,
    this.lastMessageTime,
  });

  /// Check if user is a member of this room
  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  /// Get member count
  int get memberCount => memberIds.length;

  /// Create a copy with modified fields
  Room copyWith({
    String? id,
    String? name,
    String? description,
    RoomType? type,
    String? creatorId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessagePreview,
    DateTime? lastMessageTime,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }

  @override
  String toString() =>
      'Room(id: $id, name: $name, type: $type, members: $memberCount)';
}
