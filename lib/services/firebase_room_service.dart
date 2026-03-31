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
      final querySnapshot = await _firestore.collection(_roomsCollection).get();
      return querySnapshot.docs.map((doc) => _roomFromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch rooms: $e');
    }
  }

  /// Watch all rooms
  Stream<List<Room>> watchAllRooms() {
    return _firestore
        .collection(_roomsCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => _roomFromDoc(doc)).toList(),
        );
  }

  /// Get public rooms
  Future<List<Room>> getPublicRooms() async {
    try {
      final querySnapshot = await _firestore
          .collection(_roomsCollection)
          .where('type', isEqualTo: 'public')
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
          .get();
      return querySnapshot.docs.map((doc) => _roomFromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user rooms: $e');
    }
  }

  /// Get room by ID
  Future<Room?> getRoomById(String roomId) async {
    try {
      final doc = await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .get();
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
          .where(
            (room) =>
                room.name.toLowerCase().contains(query.toLowerCase()) ||
                room.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
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
        'password': password,
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
        memberIds: List<String>.from(members),
        password: password,
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
    String? password,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (password != null) updateData['password'] = password;

      await _firestore
          .collection(_roomsCollection)
          .doc(roomId)
          .update(updateData);

      final room = await getRoomById(roomId);
      if (room == null) throw Exception('Room not found');
      return room;
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  /// Delete a room and its associated messages
  Future<void> deleteRoom(String roomId) async {
    try {
      // 1. Delete all messages associated with the room
      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('roomId', isEqualTo: roomId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete the room document
      batch.delete(_firestore.collection(_roomsCollection).doc(roomId));

      await batch.commit();
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
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => _roomFromDoc(doc)).toList(),
        );
  }

  /// Request to join a private room
  Future<void> requestToJoin(String roomId, String userId) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'pendingRequests': FieldValue.arrayUnion([userId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to send join request: $e');
    }
  }

  /// Accept a join request (move user from pendingRequests to memberIds)
  Future<void> acceptJoinRequest(String roomId, String userId) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'pendingRequests': FieldValue.arrayRemove([userId]),
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to accept join request: $e');
    }
  }

  /// Reject a join request (remove user from pendingRequests)
  Future<void> rejectJoinRequest(String roomId, String userId) async {
    try {
      await _firestore.collection(_roomsCollection).doc(roomId).update({
        'pendingRequests': FieldValue.arrayRemove([userId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to reject join request: $e');
    }
  }

  /// Watch rooms with pending requests (for room creators)
  Stream<List<Room>> watchRoomsWithPendingRequests(String creatorId) {
    return _firestore
        .collection(_roomsCollection)
        .where('creatorId', isEqualTo: creatorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => _roomFromDoc(doc))
              .where((room) => room.pendingRequests.isNotEmpty)
              .toList();
        });
  }

  /// Convert Firestore document to Room model
  Room _roomFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      type: data['type'] == 'public' ? RoomType.public : RoomType.private,
      creatorId: data['creatorId']?.toString() ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      pendingRequests: List<String>.from(data['pendingRequests'] ?? []),
      password: data['password']?.toString(),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString())
          : null,
      lastMessagePreview: data['lastMessagePreview']?.toString(),
      lastMessageTime: data['lastMessageTime'] != null
          ? DateTime.tryParse(data['lastMessageTime'].toString())
          : null,
    );
  }
}
