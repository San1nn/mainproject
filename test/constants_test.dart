import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mainproject/constants.dart';

void main() {
  group('AppColors', () {
    test('Primary colors are defined', () {
      expect(AppColors.primary, const Color(0xFF2563EB));
      expect(AppColors.primaryLight, const Color(0xFF3B82F6));
      expect(AppColors.primaryDark, const Color(0xFF1E40AF));
    });

    test('Secondary colors are defined', () {
      expect(AppColors.secondary, const Color(0xFF10B981));
      expect(AppColors.secondaryLight, const Color(0xFF34D399));
      expect(AppColors.secondaryDark, const Color(0xFF059669));
    });

    test('Neutral colors are defined', () {
      expect(AppColors.background, const Color(0xFFF9FAFB));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.surfaceVariant, const Color(0xFFF3F4F6));
    });

    test('Text colors are defined', () {
      expect(AppColors.textPrimary, const Color(0xFF111827));
      expect(AppColors.textSecondary, const Color(0xFF6B7280));
      expect(AppColors.textTertiary, const Color(0xFF9CA3AF));
    });

    test('Status colors are defined', () {
      expect(AppColors.success, const Color(0xFF10B981));
      expect(AppColors.error, const Color(0xFFEF4444));
      expect(AppColors.warning, const Color(0xFFFB923C));
      expect(AppColors.info, const Color(0xFF3B82F6));
    });

    test('Border colors are defined', () {
      expect(AppColors.border, const Color(0xFFE5E7EB));
      expect(AppColors.borderDark, const Color(0xFFD1D5DB));
    });

    test('Overlay color is defined', () {
      expect(AppColors.overlay, const Color(0x33000000));
    });
  });

  group('AppStrings', () {
    test('App strings are defined', () {
      expect(AppStrings.appName, 'MainProject');
      expect(AppStrings.appVersion, '1.0.0');
    });

    test('Auth strings are defined', () {
      expect(AppStrings.login, 'Login');
      expect(AppStrings.register, 'Register');
      expect(AppStrings.logout, 'Logout');
      expect(AppStrings.email, 'Email');
      expect(AppStrings.password, 'Password');
      expect(AppStrings.confirmPassword, 'Confirm Password');
      expect(AppStrings.name, 'Full Name');
    });

    test('Validation strings are defined', () {
      expect(AppStrings.emailRequired, 'Email is required');
      expect(AppStrings.emailInvalid, 'Enter a valid email');
      expect(AppStrings.passwordRequired, 'Password is required');
      expect(AppStrings.passwordTooShort, 'Password must be at least 6 characters');
      expect(AppStrings.passwordMismatch, 'Passwords do not match');
      expect(AppStrings.nameRequired, 'Name is required');
    });

    test('Navigation strings are defined', () {
      expect(AppStrings.home, 'Home');
      expect(AppStrings.dashboard, 'Dashboard');
      expect(AppStrings.profile, 'Profile');
      expect(AppStrings.settings, 'Settings');
    });
  });
}
