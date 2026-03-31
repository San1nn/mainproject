import 'package:mainproject/constants.dart';

/// Form validation utilities
class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Only @gmail.com addresses are allowed';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }

    if (value != password) {
      return AppStrings.passwordMismatch;
    }

    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.nameRequired;
    }

    if (value.length < 4) {
      return 'Name must be at least 4 characters';
    }

    return null;
  }
}
