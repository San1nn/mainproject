import 'package:mainproject/models/room.dart';
import 'package:mainproject/services/firebase_room_service.dart';

/// Room Service for managing rooms and operations
class RoomService {
  static final RoomService _instance = RoomService._internal();

  factory RoomService() {
    return _instance;
  }

  RoomService._internal();

  final FirebaseRoomService _firebaseRoomService = FirebaseRoomService();

  /// Get all rooms
  Future<List<Room>> getAllRooms() async {
    return _firebaseRoomService.getAllRooms();
  }

  /// Watch all rooms
  Stream<List<Room>> watchAllRooms() {
    return _firebaseRoomService.watchAllRooms();
  }

  /// Get public rooms
  Future<List<Room>> getPublicRooms() async {
    return _firebaseRoomService.getPublicRooms();
  }

  /// Get private rooms for user
  Future<List<Room>> getPrivateRoomsForUser(String userId) async {
    return _firebaseRoomService.getPrivateRoomsForUser(userId);
  }

  /// Get rooms user is member of
  Future<List<Room>> getRoomsForUser(String userId) async {
    return _firebaseRoomService.getRoomsForUser(userId);
  }

  /// Watch rooms user is member of
  Stream<List<Room>> watchUserRooms(String userId) {
    return _firebaseRoomService.watchUserRooms(userId);
  }

  /// Get room by ID
  Future<Room?> getRoomById(String roomId) async {
    return _firebaseRoomService.getRoomById(roomId);
  }

  /// Search rooms by name or description
  Future<List<Room>> searchRooms(String query) async {
    return _firebaseRoomService.searchRooms(query);
  }

  /// Create a new room
  Future<Room> createRoom({
    required String name,
    required String description,
    required RoomType type,
    required String creatorId,
    String? password,
    List<String>? initialMembers,
  }) async {
    return _firebaseRoomService.createRoom(
      name: name,
      description: description,
      type: type,
      creatorId: creatorId,
      password: password,
      initialMembers: initialMembers,
    );
  }

  /// Join user to a room
  Future<void> joinRoom(String roomId, String userId) async {
    return _firebaseRoomService.joinRoom(roomId, userId);
  }

  /// Leave user from a room
  Future<void> leaveRoom(String roomId, String userId) async {
    return _firebaseRoomService.leaveRoom(roomId, userId);
  }

  /// Update room details
  Future<Room> updateRoom({
    required String roomId,
    String? name,
    String? description,
    String? password,
  }) async {
    return _firebaseRoomService.updateRoom(
      roomId: roomId,
      name: name,
      description: description,
      password: password,
    );
  }

  /// Delete a room
  Future<void> deleteRoom(String roomId) async {
    return _firebaseRoomService.deleteRoom(roomId);
  }

  /// Get recommended rooms for user
  Future<List<Room>> getRecommendedRooms(String userId) async {
    return _firebaseRoomService.getRecommendedRooms(userId);
  }

  /// Watch a specific room for updates
  Stream<Room?> watchRoom(String roomId) {
    return _firebaseRoomService.watchRoom(roomId);
  }
}
