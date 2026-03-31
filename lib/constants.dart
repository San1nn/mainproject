import 'package:flutter/material.dart';

// ============================================================================
// APPLICATION COLOR CONSTANTS
// ============================================================================

/// Application color constants
class AppColors {
  // Primary colors (Vibrant Indigo/Blue)
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Secondary colors (Emerald/Teal)
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);

  // Background colors (Deep Slates)
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceVariant = Color(0xFF334155);
  static const Color cardBackground = Color(0xFF1E293B);

  // Text colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Borders & Dividers
  static const Color border = Color(0xFF334155);
  static const Color borderLight = Color(0xFF475569);
  static const Color borderDark = Color(0xFF1E293B);

  // Overlay
  static const Color overlay = Color(0x66000000);

  // Accents
  static const Color accentGrape = Color(0xFF8B5CF6);
  static const Color accentRose = Color(0xFFF43F5E);
}

// ============================================================================
// CLOUDINARY CONFIGURATION
// ============================================================================

/// Cloudinary configuration for media uploads (voice messages, etc.)
///
/// Setup instructions:
/// 1. Go to https://cloudinary.com and sign up (free)
/// 2. From your Dashboard, copy your "Cloud Name"
/// 3. Go to Settings → Upload → Upload Presets
/// 4. Click "Add upload preset"
/// 5. Set "Signing Mode" to "Unsigned"
/// 6. Set folder to "voice_messages" (optional)
/// 7. Save and copy the preset name
class CloudinaryConfig {
  static const String cloudName = 'df74bjuye'; // ← Replace with your cloud name
  static const String uploadPreset =
      'voice_uploads'; // ← Replace with your unsigned upload preset name

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';
}

// ============================================================================
// GEMINI AI CONFIGURATION
// ============================================================================

/// Google Gemini AI configuration for chat summarization (via Firebase AI Logic)
class GeminiConfig {
  /// Model to use — gemini-2.5-flash-lite is the recommended free-tier model
  static const String model = 'gemini-2.5-flash-lite';

  /// Minimum message length (in characters) to show the summarize option
  static const int minLengthForSummary = 100;
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
  static const String emailInvalid = 'email is not valid';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
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
