import 'package:flutter_test/flutter_test.dart';
import 'package:mainproject/models/room.dart';

void main() {
  group('Room Model', () {
    late Room testRoom;
    final now = DateTime(2024, 1, 1, 10, 0);

    setUp(() {
      testRoom = Room(
        id: 'room-001',
        name: 'General Discussion',
        description: 'A place for general discussions',
        type: RoomType.public,
        creatorId: 'user-admin',
        memberIds: ['user-001', 'user-002', 'user-003'],
        createdAt: now,
      );
    });

    test('Room creation with required fields', () {
      expect(testRoom.id, 'room-001');
      expect(testRoom.name, 'General Discussion');
      expect(testRoom.description, 'A place for general discussions');
      expect(testRoom.type, RoomType.public);
      expect(testRoom.creatorId, 'user-admin');
      expect(testRoom.memberIds, ['user-001', 'user-002', 'user-003']);
      expect(testRoom.createdAt, now);
    });

    test('Room member check', () {
      expect(testRoom.isMember('user-001'), true);
      expect(testRoom.isMember('user-002'), true);
      expect(testRoom.isMember('user-999'), false);
    });

    test('Room member count', () {
      expect(testRoom.memberCount, 3);

      final roomWithMoreMembers = testRoom.copyWith(
        memberIds: ['user-001', 'user-002', 'user-003', 'user-004', 'user-005'],
      );
      expect(roomWithMoreMembers.memberCount, 5);
    });

    test('Room types', () {
      final publicRoom = testRoom.copyWith(type: RoomType.public);
      final privateRoom = testRoom.copyWith(type: RoomType.private);

      expect(publicRoom.type, RoomType.public);
      expect(privateRoom.type, RoomType.private);
    });

    test('Room.copyWith creates modified copy', () {
      final modifiedRoom = testRoom.copyWith(
        name: 'Updated Room Name',
        memberIds: [...testRoom.memberIds, 'user-004'],
      );

      expect(modifiedRoom.id, testRoom.id);
      expect(modifiedRoom.name, 'Updated Room Name');
      expect(modifiedRoom.memberCount, 4);
      expect(modifiedRoom.type, testRoom.type);
    });

    test('Room with last message info', () {
      final roomWithMessage = testRoom.copyWith(
        lastMessagePreview: 'This is the last message',
        lastMessageTime: now.add(const Duration(hours: 1)),
      );

      expect(roomWithMessage.lastMessagePreview, 'This is the last message');
      expect(roomWithMessage.lastMessageTime, now.add(const Duration(hours: 1)));
    });

    test('Room with updated time', () {
      final updatedRoom = testRoom.copyWith(
        updatedAt: now.add(const Duration(days: 1)),
      );

      expect(updatedRoom.updatedAt, now.add(const Duration(days: 1)));
    });

    test('Room.copyWith with no arguments returns equivalent room', () {
      final copiedRoom = testRoom.copyWith();

      expect(copiedRoom.id, testRoom.id);
      expect(copiedRoom.name, testRoom.name);
      expect(copiedRoom.description, testRoom.description);
      expect(copiedRoom.type, testRoom.type);
      expect(copiedRoom.memberIds, testRoom.memberIds);
      expect(copiedRoom.createdAt, testRoom.createdAt);
    });

    test('Room toString', () {
      final roomString = testRoom.toString();

      expect(roomString, contains('room-001'));
      expect(roomString, contains('General Discussion'));
      expect(roomString, contains('public'));
      expect(roomString, contains('3'));
    });

    test('Private room creation', () {
      final privateRoom = Room(
        id: 'room-private-001',
        name: 'Private Group',
        description: 'A private discussion group',
        type: RoomType.private,
        creatorId: 'user-creator',
        memberIds: ['user-creator', 'user-friend-1', 'user-friend-2'],
        createdAt: now,
      );

      expect(privateRoom.type, RoomType.private);
      expect(privateRoom.memberCount, 3);
      expect(privateRoom.isMember('user-creator'), true);
    });

    test('Empty room (just creator)', () {
      final emptyRoom = Room(
        id: 'room-empty',
        name: 'Empty Room',
        description: 'A room with just the creator',
        type: RoomType.private,
        creatorId: 'user-alone',
        memberIds: ['user-alone'],
        createdAt: now,
      );

      expect(emptyRoom.memberCount, 1);
      expect(emptyRoom.isMember('user-alone'), true);
    });

    test('Adding members to room', () {
      final room = testRoom;
      final newMembers = [...room.memberIds, 'user-004', 'user-005'];
      final updatedRoom = room.copyWith(memberIds: newMembers);

      expect(updatedRoom.memberCount, 5);
      expect(updatedRoom.isMember('user-004'), true);
      expect(updatedRoom.isMember('user-005'), true);
    });
  });
}
