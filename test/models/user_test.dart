import 'package:flutter_test/flutter_test.dart';
import 'package:mainproject/models/user.dart';

void main() {
  group('User Model', () {
    late User testUser;

    setUp(() {
      testUser = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.user,
        createdAt: DateTime(2024, 1, 1),
      );
    });

    test('User creation with all required fields', () {
      expect(testUser.id, '123');
      expect(testUser.email, 'test@example.com');
      expect(testUser.name, 'Test User');
      expect(testUser.role, UserRole.user);
    });

    test('User.toJson converts user to map correctly', () {
      final json = testUser.toJson();

      expect(json['id'], '123');
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Test User');
      expect(json['role'], 'user');
      expect(json['createdAt'], '2024-01-01T00:00:00.000');
    });

    test('User.fromJson creates user from map correctly', () {
      final json = {
        'id': '456',
        'email': 'fromjson@example.com',
        'name': 'JSON User',
        'role': 'admin',
        'createdAt': '2024-01-15T10:30:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, '456');
      expect(user.email, 'fromjson@example.com');
      expect(user.name, 'JSON User');
      expect(user.role, UserRole.admin);
    });

    test('User.fromJson with invalid role defaults to user role', () {
      final json = {
        'id': '789',
        'email': 'invalid@example.com',
        'name': 'Invalid Role User',
        'role': 'invalid_role',
        'createdAt': '2024-01-15T10:30:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.role, UserRole.user);
    });

    test('User.copyWith creates modified copy', () {
      final modifiedUser = testUser.copyWith(
        name: 'Updated Name',
        role: UserRole.admin,
      );

      expect(modifiedUser.id, testUser.id);
      expect(modifiedUser.email, testUser.email);
      expect(modifiedUser.name, 'Updated Name');
      expect(modifiedUser.role, UserRole.admin);
      expect(modifiedUser.createdAt, testUser.createdAt);
    });

    test('User.copyWith with no arguments returns equivalent user', () {
      final copiedUser = testUser.copyWith();

      expect(copiedUser.id, testUser.id);
      expect(copiedUser.email, testUser.email);
      expect(copiedUser.name, testUser.name);
      expect(copiedUser.role, testUser.role);
      expect(copiedUser.createdAt, testUser.createdAt);
    });

    test('User with different roles', () {
      final adminUser = User(
        id: '1',
        email: 'admin@example.com',
        name: 'Admin',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      final moderatorUser = User(
        id: '2',
        email: 'mod@example.com',
        name: 'Moderator',
        role: UserRole.moderator,
        createdAt: DateTime.now(),
      );

      expect(adminUser.role, UserRole.admin);
      expect(moderatorUser.role, UserRole.moderator);
      expect(testUser.role, UserRole.user);
    });

    test('User JSON round-trip conversion', () {
      final originalUser = User(
        id: 'uuid-12345',
        email: 'roundtrip@example.com',
        name: 'Round Trip User',
        role: UserRole.moderator,
        createdAt: DateTime(2024, 6, 15, 14, 30),
      );

      final json = originalUser.toJson();
      final restoredUser = User.fromJson(json);

      expect(restoredUser.id, originalUser.id);
      expect(restoredUser.email, originalUser.email);
      expect(restoredUser.name, originalUser.name);
      expect(restoredUser.role, originalUser.role);
      expect(restoredUser.createdAt, originalUser.createdAt);
    });
  });
}
