import 'package:flutter/material.dart';

// ============================================================================
// APPLICATION COLOR CONSTANTS
// ============================================================================

/// Application color constants
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E40AF);

  // Secondary colors
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);

  // Neutral colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Text colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFB923C);
  static const Color info = Color(0xFF3B82F6);

  // Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFFD1D5DB);

  // Overlay
  static const Color overlay = Color(0x33000000);
}

// ============================================================================
// APPLICATION STRING CONSTANTS
// ============================================================================

/// Application string constants
class AppStrings {
  // App
  static const String appName = 'MainProject';
  static const String appVersion = '1.0.0';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String name = 'Full Name';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';

  // Validation
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String nameRequired = 'Name is required';

  // Home
  static const String home = 'Home';
  static const String dashboard = 'Dashboard';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String management = 'Management';

  // Messages
  static const String loading = 'Loading...';
  static const String success = 'Success';
  static const String error = 'Error';
  static const String tryAgain = 'Try Again';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';

  // Demo accounts
  static const String adminEmail = 'admin@example.com';
  static const String userEmail = 'user@example.com';
  static const String demoPassword = 'password123';
}

// ============================================================================
// FIREBASE COLLECTION NAMES
// ============================================================================

/// Firebase Collection Names
class FirebaseCollections {
  static const String users = 'users';
  static const String rooms = 'rooms';
  static const String messages = 'messages';
  static const String voiceMessages = 'voice_messages';
}

// ============================================================================
// FIREBASE FIELD NAMES
// ============================================================================

/// Firebase User Fields
class FirebaseUserFields {
  static const String id = 'id';
  static const String email = 'email';
  static const String name = 'name';
  static const String role = 'role';
  static const String photoUrl = 'photoUrl';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

/// Firebase Room Fields
class FirebaseRoomFields {
  static const String id = 'id';
  static const String name = 'name';
  static const String description = 'description';
  static const String type = 'type';
  static const String creatorId = 'creatorId';
  static const String memberIds = 'memberIds';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String lastMessagePreview = 'lastMessagePreview';
  static const String lastMessageTime = 'lastMessageTime';
}

/// Firebase Message Fields
class FirebaseMessageFields {
  static const String id = 'id';
  static const String roomId = 'roomId';
  static const String senderId = 'senderId';
  static const String senderName = 'senderName';
  static const String content = 'content';
  static const String type = 'type';
  static const String timestamp = 'timestamp';
  static const String editedAt = 'editedAt';
  static const String likedByUserIds = 'likedByUserIds';
}

// ============================================================================
// FIREBASE ERROR CODES
// ============================================================================

/// Firebase Error Codes
class FirebaseErrorCodes {
  static const String emailAlreadyInUse = 'email-already-in-use';
  static const String invalidEmail = 'invalid-email';
  static const String weakPassword = 'weak-password';
  static const String userNotFound = 'user-not-found';
  static const String wrongPassword = 'wrong-password';
  static const String tooManyRequests = 'too-many-requests';
  static const String operationNotAllowed = 'operation-not-allowed';
  static const String accountExistsWithDifferentCredential =
      'account-exists-with-different-credential';
}

// ============================================================================
// ROUTE CONSTANTS
// ============================================================================

/// Route name constants
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String roomDetail = '/room-detail';
}

// ============================================================================
// DIMENSION CONSTANTS
// ============================================================================

/// Dimension constants for consistent spacing
class AppDimensions {
  // Padding & Margins
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Button heights
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
}

// ============================================================================
// DURATION CONSTANTS
// ============================================================================

/// Duration constants for animations and delays
class AppDurations {
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
  static const Duration networkDelay = Duration(milliseconds: 500);
}

// ============================================================================
// VALIDATION CONSTANTS
// ============================================================================

/// Validation constants
class ValidationConstants {
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
}
