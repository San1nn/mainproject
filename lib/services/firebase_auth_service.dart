import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mainproject/constants.dart';
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

  /// Restore session from persistent storage
  Future<bool> restoreSession() async {
    try {
      final firebaseUser = await _firebaseAuth.authStateChanges().first;

      if (firebaseUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          _currentUser = models.User(
            id: firebaseUser.uid,
            email: data['email'] ?? firebaseUser.email ?? '',
            name: data['name'] ?? 'User',
            role: _parseUserRole(data['role'] ?? 'user'),
            createdAt: data['createdAt'] != null
                ? DateTime.tryParse(data['createdAt'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
          );
          return true;
        }
        return false;
      }
      return false;
    } catch (e) {
      print('Session restoration failed: $e');
      return false;
    }
  }

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
  Future<void> login({required String email, required String password}) async {
    try {
      print('DEBUG: Attempting login for $email');
      final userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      print('DEBUG: Auth successful, UID: ${userCredential.user?.uid}');

      // Fetch user data from Firestore with timeout
      print('DEBUG: Fetching user document...');
      var userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic>? data;

      if (userDoc.exists) {
        print('DEBUG: User document found by UID');
        data = userDoc.data();
      } else {
        print(
          'DEBUG: User document not found by UID, trying email fallback...',
        );
        // Fallback: Try finding by email
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));

        if (query.docs.isNotEmpty) {
          print('DEBUG: User document found by email fallback');
          data = query.docs.first.data();
        } else {
          print('DEBUG: No user document found by email fallback either');
        }
      }

      if (data != null) {
        print('DEBUG: Mapping user data. Role: ${data['role']}');
        
        // Auto-upgrade admin@gmail.com to admin role if they somehow registered as a normal user
        if ((email == AppStrings.adminEmail || email == 'admin@gmail.com') && data['role'] != 'admin') {
           print('DEBUG: Upgrading $email to admin role automatically.');
           await _firestore.collection('users').doc(userCredential.user!.uid).update({'role': 'admin'});
           data['role'] = 'admin';
        }

        _currentUser = models.User(
          id: data['id'] ?? userCredential.user!.uid,
          email: data['email'] ?? email,
          name: data['name'] ?? 'Admin',
          role: _parseUserRole(data['role']),
          createdAt: data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
        );
        print('DEBUG: Login complete for ${_currentUser!.name}');
      } else if (email == AppStrings.adminEmail || email == 'admin@gmail.com') {
        // EMERGENCY FALLBACK + AUTO-CREATE for special admin account
        print(
          'DEBUG: Firestore missing for admin@gmail.com. Auto-creating profile...',
        );
        final adminData = {
          'id': userCredential.user!.uid,
          'email': email,
          'name': 'System Admin',
          'role': 'admin',
          'createdAt': DateTime.now().toIso8601String(),
        };

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(adminData);

        _currentUser = models.User(
          id: adminData['id'] as String,
          email: adminData['email'] as String,
          name: adminData['name'] as String,
          role: models.UserRole.admin,
          createdAt: DateTime.now(),
        );
        print('DEBUG: Admin profile created and login complete');
      } else {
        print('DEBUG: Profile missing in Firestore');
        throw Exception(
          'User profile not found in database. Please register first.',
        );
      }
    } on FirebaseAuthException catch (e) {
      print('DEBUG: FirebaseAuthException: ${e.code}');
      throw Exception(_handleAuthError(e));
    } catch (e) {
      print('DEBUG: Login Error: $e');

      // If network is down but user is logging in as the known admin,
      // we allow it for development purposes if they used the bypass
      if (email == 'admin@gmail.com' &&
          e.toString().contains('TimeoutException')) {
        print(
          'DEBUG: Network Timeout but email is admin@gmail.com. Using Emergency Bypass.',
        );
        _currentUser = models.User(
          id: 'offline_admin_id',
          email: 'admin@gmail.com',
          name: 'Admin (Offline Mode)',
          role: models.UserRole.admin,
          createdAt: DateTime.now(),
        );
        return;
      }

      if (e.toString().contains('unavailable')) {
        throw Exception(
          'Server unreachable. Please check your internet connection.',
        );
      }
      throw Exception(
        'Login failed: ${e.toString().replaceFirst('Exception: ', '')}',
      );
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
        return ['moderate_content', 'view_reports', 'manage_rooms'];
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
      case 'wrong-password':
      case 'invalid-credential':
        return 'email or password is incorrect';
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

  /// Get user by ID (with email fallback and admin bypass)
  Future<models.User?> getUserById(String uidOrEmail) async {
    // 0. Hardcoded Admin Bypass check (for internal system identities)
    if (uidOrEmail == 'hardcoded_admin_id' || uidOrEmail == 'admin@gmail.com') {
      return models.User(
        id: 'hardcoded_admin_id',
        email: 'admin@gmail.com',
        name: 'System Admin',
        role: models.UserRole.admin,
        createdAt: DateTime(2024, 1, 1),
      );
    }

    try {
      // 1. Try fetching by Document ID (standard UID approach)
      final doc = await _firestore
          .collection('users')
          .doc(uidOrEmail)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists) {
        final data = doc.data()!;
        return models.User(
          id: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? 'User',
          role: _parseUserRole(data['role'] ?? 'user'),
          createdAt: data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
        );
      }

      // 2. Fallback: If not found by Doc ID, and it looks like an email, try searching by email field
      if (uidOrEmail.contains('@')) {
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: uidOrEmail)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));

        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          return models.User(
            id: query.docs.first.id,
            email: data['email'] ?? uidOrEmail,
            name: data['name'] ?? 'User',
            role: _parseUserRole(data['role'] ?? 'user'),
            createdAt: data['createdAt'] != null
                ? DateTime.tryParse(data['createdAt'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
          );
        }
      }

      return null;
    } catch (e) {
      print('DEBUG: Error fetching user by ID ($uidOrEmail): $e');
      return null;
    }
  }
}
