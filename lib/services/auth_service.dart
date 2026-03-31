import 'package:mainproject/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_auth_service.dart';

/// Authentication Service - Firebase Only with Persistent Login
class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Firebase service
  late final FirebaseAuthService _firebaseService = FirebaseAuthService();

  static const String _authTokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';

  /// Initialize persistent login - call on app startup
  Future<bool> initializePersistentLogin() async {
    try {
      // Try to restore session from Firebase
      final restored = await _firebaseService.restoreSession();

      final prefs = await SharedPreferences.getInstance();

      if (restored) {
        // Session restored successfully, ensure prefs are synced
        final currentUser = _firebaseService.currentUser;
        if (currentUser != null) {
          await _savePersistentLogin(currentUser.email);
        }
        return true;
      } else {
        // No valid session, clear stored data
        await prefs.remove(_authTokenKey);
        await prefs.remove(_userEmailKey);
        return false;
      }
    } catch (e) {
      print('Error initializing persistent login: $e');
      return false;
    }
  }

  /// Get current authenticated user
  User? get currentUser => _firebaseService.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _firebaseService.isAuthenticated;

  /// Register a new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _firebaseService.register(
        email: email,
        password: password,
        name: name,
      );

      // Save login info for persistent login
      await _savePersistentLogin(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Login user
  Future<void> login({required String email, required String password}) async {
    try {
      await _firebaseService.login(email: email, password: password);

      // Save login info for persistent login
      await _savePersistentLogin(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Save persistent login data
  Future<void> _savePersistentLogin(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userEmailKey, email);
      await prefs.setBool(_authTokenKey, true);
    } catch (e) {
      print('Error saving persistent login: $e');
    }
  }

  /// Logout current user and clear persistent login
  Future<void> logout() async {
    try {
      await _firebaseService.logout();

      // Clear persistent login data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
      await prefs.remove(_userEmailKey);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user role permissions
  List<String> getUserPermissions(UserRole role) {
    return _firebaseService.getUserPermissions(role);
  }

  /// Check if user has permission
  bool hasPermission(String permission) {
    final user = currentUser;
    if (user == null) return false;
    final permissions = getUserPermissions(user.role);
    return permissions.contains(permission);
  }

  /// Get user by ID
  Future<User?> getUserById(String uid) async {
    return _firebaseService.getUserById(uid);
  }
}
