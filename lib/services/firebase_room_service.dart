import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mainproject/models/room.dart';

/// Firebase Room Service for managing rooms
class FirebaseRoomService {
  static final FirebaseRoomService _instance = FirebaseRoomService._internal();

  factory FirebaseRoomService() {
    return _instance;
  }

  FirebaseRoomService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _roomsCollection = 'rooms';

  /// Get all rooms
  Future<List<Room>> getAllRooms() async {
    try {
      final querySnapshot =
          await _firestore.collection(_roomsCollection).get();
      return querySnapshot.docs.map((doc) => _roomFromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch rooms: $e');
    }
  }

  /// Get public rooms
  Future<List<Room>> getPublicRooms() async {
    try {
      final querySnapshot = await _firestore
          .collection(_roomsCollection)
          .where('type', isEqualTo: 'public')
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => _roomFromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch public rooms: $e');
    }
  }

  /// Get private rooms for user
  Future<List<Room>> getPrivateRoomsForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_roomsCollection)
          .where('type', isEqualTo: 'private')
          .where('memberIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => _roomFromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch private rooms: $e');
    }
  }

  /// Get rooms user is member of
  Future<List<Room>> getRoomsForUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_roomsCollection)
          .where('memberIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => _roomFromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user rooms: $e');
    }
  }

  /// Get room by ID
  Future<Room?> getRoomById(String roomId) async {
    try {
      final doc =
          await _firestore.collection(_roomsCollection).doc(roomId).get();
      if (doc.exists) {
        return _roomFromDoc(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch room: $e');
    }
  }

  /// Search rooms by name or description
  Future<List<Room>> searchRooms(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final querySnapshot = await _firestore
          .collection(_roomsCollection)
          .orderBy('name')
          .startAt([lowerQuery])
          .endAt(['$lowerQuery\uf8ff'])
          .get();
      return querySnapshot.docs.map((doc) => _roomFromDoc(doc)).toList();
    } catch (e) {
      // Fallback to client-side search
      final allRooms = await getAllRooms();
      return allRooms
          .where((room) =>
              room.name.toLowerCase().contains(query.toLowerCase()) ||
              room.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Create a new room
  Future<Room> createRoom({
    required String name,
    required String description,
    required RoomType type,
    required String creatorId,
    List<String>? initialMembers,
  }) async {
    try {
      final roomRef = _firestore.collection(_roomsCollection).doc();
      final members = [creatorId, ...(initialMembers ?? [])];
      final now = DateTime.now();

      final roomData = {
        'id': roomRef.id,
        'name': name,
        'description': description,
        'type': type.toString().split('.').last,
        'creatorId': creatorId,
        'memberIds': members,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await roomRef.set(roomData);

      return Room(
        id: roomRef.id,
        name: name,
        description: description,
        type: type,
        creatorId: creatorId,
        memberIds: members,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  /// Join user to a room
  Future<void> joinRoom(String roomId, String userId) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to join room: $e');
    }
  }

  /// Leave user from a room
  Future<void> leaveRoom(String roomId, String userId) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to leave room: $e');
    }
  }

  /// Update room details
  Future<Room> updateRoom({
    required String roomId,
    String? name,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;

      await _firestore.collection(_roomsCollection).doc(roomId).update(updateData);

      final room = await getRoomById(roomId);
      if (room == null) throw Exception('Room not found');
      return room;
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  /// Delete a room
  Future<void> deleteRoom(String roomId) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).delete();
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }

  /// Get recommended rooms for user
  Future<List<Room>> getRecommendedRooms(String userId) async {
    try {
      // Get all public rooms user is not a member of
      final querySnapshot = await _firestore
          .collection(_roomsCollection)
          .where('type', isEqualTo: 'public')
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => _roomFromDoc(doc))
          .where((room) => !room.memberIds.contains(userId))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recommended rooms: $e');
    }
  }

  /// Watch room updates in real-time
  Stream<Room?> watchRoom(String roomId) {
    return _firestore
        .collection(_roomsCollection)
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? _roomFromDoc(doc) : null);
  }

  /// Watch all rooms for user
  Stream<List<Room>> watchUserRooms(String userId) {
    return _firestore
        .collection(_roomsCollection)
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _roomFromDoc(doc)).toList());
  }

  /// Convert Firestore document to Room model
  Room _roomFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] == 'public' ? RoomType.public : RoomType.private,
      creatorId: data['creatorId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : null,
      lastMessagePreview: data['lastMessagePreview'],
      lastMessageTime: data['lastMessageTime'] != null
          ? DateTime.parse(data['lastMessageTime'])
          : null,
    );
  }
}
