import 'package:mainproject/models/room.dart';

/// Room Service for managing rooms and operations
class RoomService {
  static final RoomService _instance = RoomService._internal();

  factory RoomService() {
    return _instance;
  }

  RoomService._internal();

  /// Mock rooms database
  final List<Room> _rooms = [
    Room(
      id: '1',
      name: 'Flutter Development',
      description: 'Discuss Flutter framework, widgets, and best practices',
      type: RoomType.public,
      creatorId: 'admin@example.com',
      memberIds: ['admin@example.com', 'user@example.com'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastMessagePreview: 'Great discussion on state management!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Room(
      id: '2',
      name: 'Web Development',
      description: 'Learn and discuss web development technologies',
      type: RoomType.public,
      creatorId: 'admin@example.com',
      memberIds: ['admin@example.com'],
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      lastMessagePreview: 'React vs Vue comparison',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Room(
      id: '3',
      name: 'Project Alpha',
      description: 'Private room for Project Alpha team',
      type: RoomType.private,
      creatorId: 'user@example.com',
      memberIds: ['user@example.com', 'admin@example.com'],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      lastMessagePreview: 'Phase 2 implementation started',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Room(
      id: '4',
      name: 'Database Design',
      description: 'Discussions on database architecture and optimization',
      type: RoomType.public,
      creatorId: 'admin@example.com',
      memberIds: ['admin@example.com', 'user@example.com'],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      lastMessagePreview: 'SQL vs NoSQL for this use case',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Room(
      id: '5',
      name: 'Mobile App Design',
      description: 'UI/UX design principles and mobile app development',
      type: RoomType.public,
      creatorId: 'admin@example.com',
      memberIds: ['admin@example.com'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      lastMessagePreview: 'Material Design 3 updates',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  /// Get all rooms
  Future<List<Room>> getAllRooms() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rooms;
  }

  /// Get public rooms
  Future<List<Room>> getPublicRooms() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _rooms.where((room) => room.type == RoomType.public).toList();
  }

  /// Get private rooms for user
  Future<List<Room>> getPrivateRoomsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _rooms
        .where((room) =>
            room.type == RoomType.private && room.memberIds.contains(userId))
        .toList();
  }

  /// Get rooms user is member of
  Future<List<Room>> getRoomsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rooms
        .where((room) => room.memberIds.contains(userId))
        .toList();
  }

  /// Get room by ID
  Future<Room?> getRoomById(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _rooms.firstWhere((room) => room.id == roomId);
    } catch (e) {
      return null;
    }
  }

  /// Search rooms by name or description
  Future<List<Room>> searchRooms(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final lowerQuery = query.toLowerCase();
    return _rooms
        .where((room) =>
            room.name.toLowerCase().contains(lowerQuery) ||
            room.description.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Create a new room
  Future<Room> createRoom({
    required String name,
    required String description,
    required RoomType type,
    required String creatorId,
    List<String>? initialMembers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newRoom = Room(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      type: type,
      creatorId: creatorId,
      memberIds: [creatorId, ...(initialMembers ?? [])],
      createdAt: DateTime.now(),
    );

    _rooms.add(newRoom);
    return newRoom;
  }

  /// Join user to a room
  Future<void> joinRoom(String roomId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      if (!room.memberIds.contains(userId)) {
        final updatedMembers = [...room.memberIds, userId];
        _rooms[roomIndex] = room.copyWith(memberIds: updatedMembers);
      }
    }
  }

  /// Leave user from a room
  Future<void> leaveRoom(String roomId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      final updatedMembers = room.memberIds
          .where((memberId) => memberId != userId)
          .toList();
      _rooms[roomIndex] = room.copyWith(memberIds: updatedMembers);
    }
  }

  /// Update room details
  Future<Room> updateRoom({
    required String roomId,
    String? name,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      final updatedRoom = room.copyWith(
        name: name ?? room.name,
        description: description ?? room.description,
        updatedAt: DateTime.now(),
      );
      _rooms[roomIndex] = updatedRoom;
      return updatedRoom;
    }

    throw Exception('Room not found');
  }

  /// Delete a room
  Future<void> deleteRoom(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _rooms.removeWhere((room) => room.id == roomId);
  }

  /// Get recommended rooms for user
  Future<List<Room>> getRecommendedRooms(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Get rooms user is not a member of
    return _rooms
        .where((room) => !room.memberIds.contains(userId))
        .toList();
  }
}
