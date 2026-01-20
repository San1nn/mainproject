import 'package:mainproject/models/user.dart';
import 'firebase_auth_service.dart';

/// Authentication Service - Uses Firebase when available, falls back to mock
class AuthService {
  static final AuthService _instance = AuthService._internal();
  static bool _useFirebase = true; // Toggle between Firebase and mock

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Firebase service
  late final FirebaseAuthService _firebaseService = FirebaseAuthService();

  // Mock data
  User? _currentUser;
  final Map<String, String> _userDatabase = {
    'admin@example.com': 'password123', // Demo admin account
    'user@example.com': 'password123',  // Demo user account
  };

  /// Get current authenticated user
  User? get currentUser => _currentUser ?? _firebaseService.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated =>
      _useFirebase
          ? _firebaseService.isAuthenticated
          : _currentUser != null;

  /// Enable/Disable Firebase (for testing)
  static void setUseFirebase(bool useFirebase) {
    _useFirebase = useFirebase;
  }

  /// Register a new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      if (_useFirebase) {
        await _firebaseService.register(
          email: email,
          password: password,
          name: name,
        );
        _currentUser = _firebaseService.currentUser;
      } else {
        // Mock registration
        await _mockRegister(email, password, name);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Login user
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      if (_useFirebase) {
        await _firebaseService.login(email: email, password: password);
        _currentUser = _firebaseService.currentUser;
      } else {
        // Mock login
        await _mockLogin(email, password);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      if (_useFirebase) {
        await _firebaseService.logout();
      }
      _currentUser = null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user role permissions
  List<String> getUserPermissions(UserRole role) {
    if (_useFirebase) {
      return _firebaseService.getUserPermissions(role);
    }
    
    switch (role) {
      case UserRole.admin:
        return [
          'manage_users',
          'view_analytics',
          'manage_rooms',
          'moderate_content',
          'view_reports',
          'system_settings',
        ];
      case UserRole.moderator:
        return [
          'moderate_content',
          'view_reports',
          'manage_rooms',
        ];
      case UserRole.user:
        return [
          'view_rooms',
          'send_messages',
          'create_private_rooms',
          'join_public_rooms',
        ];
    }
  }

  // Mock Methods
  Future<void> _mockRegister(String email, String password, String name) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_userDatabase.containsKey(email)) {
      throw Exception('Email already registered');
    }

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('All fields are required');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // Store user credentials
    _userDatabase[email] = password;

    // Create user object
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      role: UserRole.user,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _mockLogin(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_userDatabase.containsKey(email)) {
      throw Exception('User not found');
    }

    if (_userDatabase[email] != password) {
      throw Exception('Invalid password');
    }

    // Determine role based on email
    UserRole role = UserRole.user;
    if (email == 'admin@example.com') {
      role = UserRole.admin;
    } else if (email == 'moderator@example.com') {
      role = UserRole.moderator;
    }

    _currentUser = User(
      id: email.hashCode.toString(),
      email: email,
      name: email.split('@').first,
      role: role,
      createdAt: DateTime.now(),
    );
  }

  /// Check if user has permission
  bool hasPermission(String permission) {
    final user = currentUser;
    if (user == null) return false;
    final permissions = getUserPermissions(user.role);
    return permissions.contains(permission);
  }
}
