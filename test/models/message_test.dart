import 'package:flutter_test/flutter_test.dart';
import 'package:mainproject/models/message.dart';

void main() {
  group('Message Model', () {
    late Message testMessage;
    final now = DateTime(2024, 1, 15, 10, 30);

    setUp(() {
      testMessage = Message(
        id: 'msg-123',
        roomId: 'room-456',
        senderId: 'user-789',
        senderName: 'Test User',
        content: 'Hello, World!',
        type: MessageType.text,
        timestamp: now,
      );
    });

    test('Message creation with required fields', () {
      expect(testMessage.id, 'msg-123');
      expect(testMessage.roomId, 'room-456');
      expect(testMessage.senderId, 'user-789');
      expect(testMessage.senderName, 'Test User');
      expect(testMessage.content, 'Hello, World!');
      expect(testMessage.type, MessageType.text);
      expect(testMessage.timestamp, now);
    });

    test('Message with no edits', () {
      expect(testMessage.isEdited, false);
      expect(testMessage.editedAt, null);
    });

    test('Message with edits', () {
      final editedMessage = testMessage.copyWith(
        editedAt: now.add(const Duration(minutes: 5)),
      );

      expect(editedMessage.isEdited, true);
      expect(editedMessage.editedAt, now.add(const Duration(minutes: 5)));
    });

    test('Message with no likes', () {
      expect(testMessage.likeCount, 0);
      expect(testMessage.isLikedBy('user-001'), false);
    });

    test('Message with likes', () {
      final likedMessage = testMessage.copyWith(
        likedByUserIds: ['user-001', 'user-002', 'user-003'],
      );

      expect(likedMessage.likeCount, 3);
      expect(likedMessage.isLikedBy('user-001'), true);
      expect(likedMessage.isLikedBy('user-002'), true);
      expect(likedMessage.isLikedBy('user-999'), false);
    });

    test('Message types', () {
      final textMsg = testMessage.copyWith(type: MessageType.text);
      final voiceMsg = testMessage.copyWith(type: MessageType.voice);
      final imageMsg = testMessage.copyWith(type: MessageType.image);
      final fileMsg = testMessage.copyWith(type: MessageType.file);

      expect(textMsg.type, MessageType.text);
      expect(voiceMsg.type, MessageType.voice);
      expect(imageMsg.type, MessageType.image);
      expect(fileMsg.type, MessageType.file);
    });

    test('Message.copyWith creates modified copy', () {
      final modifiedMessage = testMessage.copyWith(
        content: 'Updated content',
        type: MessageType.image,
      );

      expect(modifiedMessage.id, testMessage.id);
      expect(modifiedMessage.roomId, testMessage.roomId);
      expect(modifiedMessage.content, 'Updated content');
      expect(modifiedMessage.type, MessageType.image);
      expect(modifiedMessage.timestamp, testMessage.timestamp);
    });

    test('Message.copyWith with no arguments returns equivalent message', () {
      final copiedMessage = testMessage.copyWith();

      expect(copiedMessage.id, testMessage.id);
      expect(copiedMessage.roomId, testMessage.roomId);
      expect(copiedMessage.senderId, testMessage.senderId);
      expect(copiedMessage.senderName, testMessage.senderName);
      expect(copiedMessage.content, testMessage.content);
      expect(copiedMessage.type, testMessage.type);
      expect(copiedMessage.timestamp, testMessage.timestamp);
    });

    test('Message toString', () {
      final messageString = testMessage.toString();

      expect(messageString, contains('msg-123'));
      expect(messageString, contains('room-456'));
      expect(messageString, contains('Test User'));
      expect(messageString, contains('text'));
    });

    test('Multiple messages in conversation', () {
      final msg1 = testMessage;
      final msg2 = testMessage.copyWith(
        id: 'msg-124',
        content: 'Second message',
        timestamp: now.add(const Duration(seconds: 30)),
      );
      final msg3 = testMessage.copyWith(
        id: 'msg-125',
        content: 'Third message',
        timestamp: now.add(const Duration(seconds: 60)),
      );

      final messages = [msg1, msg2, msg3];
      expect(messages.length, 3);
      expect(messages[0].content, 'Hello, World!');
      expect(messages[2].content, 'Third message');
    });
  });
}
