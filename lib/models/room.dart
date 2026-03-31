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
  final List<String> pendingRequests;
  final String? password;
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
    this.pendingRequests = const [],
    this.password,
    required this.createdAt,
    this.updatedAt,
    this.lastMessagePreview,
    this.lastMessageTime,
  });

  /// Check if user is a member of this room
  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  /// Check if user has a pending join request
  bool hasPendingRequest(String userId) {
    return pendingRequests.contains(userId);
  }

  /// Check if user is the creator of this room
  bool isCreator(String userId) {
    return creatorId == userId;
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
    List<String>? pendingRequests,
    String? password,
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
      pendingRequests: pendingRequests ?? this.pendingRequests,
      password: password ?? this.password,
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
