import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mainproject/models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  /// Get all users from Firestore
  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Always use document ID as the primary ID
        return User.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  /// Watch all users from Firestore
  Stream<List<User>> watchAllUsers() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Always use document ID as the primary ID
            return User.fromJson(data);
          }).toList(),
        );
  }

  /// Update user role
  Future<void> updateUserRole(String email, UserRole newRole) async {
    try {
      // Find user by email
      final snapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('User not found');
      }

      final docId = snapshot.docs.first.id;
      await _firestore.collection(_collection).doc(docId).update({
        'role': newRole.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
