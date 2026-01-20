import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mainproject/models/user.dart' as models;

/// Firebase Authentication Service
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();

  factory FirebaseAuthService() {
    return _instance;
  }

  FirebaseAuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  models.User? _currentUser;

  /// Get current authenticated user
  models.User? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Register a new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final newUser = models.User(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        role: models.UserRole.user,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'id': newUser.id,
        'email': newUser.email,
        'name': newUser.name,
        'role': newUser.role.toString().split('.').last,
        'createdAt': newUser.createdAt.toIso8601String(),
      });

      _currentUser = newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login user
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user data from Firestore
      final userDoc =
          await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        _currentUser = models.User(
          id: data['id'],
          email: data['email'],
          name: data['name'],
          role: _parseUserRole(data['role']),
          createdAt: DateTime.parse(data['createdAt']),
        );
      } else {
        throw Exception('User data not found');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Get user role permissions
  List<String> getUserPermissions(models.UserRole role) {
    switch (role) {
      case models.UserRole.admin:
        return [
          'manage_users',
          'view_analytics',
          'manage_rooms',
          'moderate_content',
          'view_reports',
          'system_settings',
        ];
      case models.UserRole.moderator:
        return [
          'moderate_content',
          'view_reports',
          'manage_rooms',
        ];
      case models.UserRole.user:
        return [
          'view_rooms',
          'send_messages',
          'create_private_rooms',
          'join_public_rooms',
        ];
    }
  }

  /// Check if user is admin
  bool get isAdmin => _currentUser?.role == models.UserRole.admin;

  /// Check if user is moderator
  bool get isModerator => _currentUser?.role == models.UserRole.moderator;

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) {
        updateData['name'] = name;
        _currentUser = _currentUser?.copyWith(name: name);
      }
      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updateData);
      }
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  /// Handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Invalid password';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication error';
    }
  }

  /// Parse user role from string
  models.UserRole _parseUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return models.UserRole.admin;
      case 'moderator':
        return models.UserRole.moderator;
      default:
        return models.UserRole.user;
    }
  }

  /// Check if user exists in Firestore
  Future<bool> userExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  /// Get user by ID
  Future<models.User?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return models.User(
          id: data['id'],
          email: data['email'],
          name: data['name'],
          role: _parseUserRole(data['role']),
          createdAt: DateTime.parse(data['createdAt']),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }
}
