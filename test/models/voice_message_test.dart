import 'package:flutter_test/flutter_test.dart';
import 'package:mainproject/models/voice_message.dart';

void main() {
  group('VoiceMessage Model', () {
    late VoiceMessage testVoiceMessage;
    final now = DateTime(2024, 1, 15, 10, 30);

    setUp(() {
      testVoiceMessage = VoiceMessage(
        id: 'voice-001',
        messageId: 'msg-123',
        roomId: 'room-456',
        senderId: 'user-789',
        senderName: 'John Doe',
        audioUrl: 'https://example.com/audio.mp3',
        duration: const Duration(minutes: 2, seconds: 30),
        timestamp: now,
        fileSize: 2048000,
      );
    });

    test('VoiceMessage creation with required fields', () {
      expect(testVoiceMessage.id, 'voice-001');
      expect(testVoiceMessage.messageId, 'msg-123');
      expect(testVoiceMessage.roomId, 'room-456');
      expect(testVoiceMessage.senderId, 'user-789');
      expect(testVoiceMessage.senderName, 'John Doe');
      expect(testVoiceMessage.audioUrl, 'https://example.com/audio.mp3');
      expect(testVoiceMessage.duration, const Duration(minutes: 2, seconds: 30));
      expect(testVoiceMessage.timestamp, now);
    });

    test('VoiceMessage formatted duration', () {
      expect(testVoiceMessage.formattedDuration, '02:30');

      final shortMessage = testVoiceMessage.copyWith(
        duration: const Duration(seconds: 5),
      );
      expect(shortMessage.formattedDuration, '00:05');

      final longMessage = testVoiceMessage.copyWith(
        duration: const Duration(hours: 1, minutes: 5, seconds: 42),
      );
      expect(longMessage.formattedDuration, '65:42');
    });

    test('VoiceMessage without file size', () {
      final messageWithoutSize = VoiceMessage(
        id: 'voice-no-size',
        messageId: 'msg-123',
        roomId: 'room-456',
        senderId: 'user-789',
        senderName: 'John Doe',
        audioUrl: 'https://example.com/audio.mp3',
        duration: const Duration(minutes: 2, seconds: 30),
        timestamp: DateTime.now(),
      );
      expect(messageWithoutSize.fileSize, null);
      expect(messageWithoutSize.formattedFileSize, null);
    });

    test('VoiceMessage formatted file size in bytes', () {
      final messageBytes = testVoiceMessage.copyWith(fileSize: 512);
      expect(messageBytes.formattedFileSize, '512 B');
    });

    test('VoiceMessage formatted file size in KB', () {
      final messageKB = testVoiceMessage.copyWith(fileSize: 2048);
      expect(messageKB.formattedFileSize, contains('KB'));
    });

    test('VoiceMessage formatted file size in MB', () {
      final messageMB = testVoiceMessage.copyWith(fileSize: 2048000);
      expect(messageMB.formattedFileSize, contains('MB'));
    });

    test('VoiceMessage.copyWith creates modified copy', () {
      final modifiedMessage = testVoiceMessage.copyWith(
        senderName: 'Jane Doe',
        duration: const Duration(minutes: 1, seconds: 15),
      );

      expect(modifiedMessage.id, testVoiceMessage.id);
      expect(modifiedMessage.senderName, 'Jane Doe');
      expect(modifiedMessage.duration, const Duration(minutes: 1, seconds: 15));
      expect(modifiedMessage.audioUrl, testVoiceMessage.audioUrl);
    });

    test('VoiceMessage.copyWith with no arguments returns equivalent message', () {
      final copiedMessage = testVoiceMessage.copyWith();

      expect(copiedMessage.id, testVoiceMessage.id);
      expect(copiedMessage.messageId, testVoiceMessage.messageId);
      expect(copiedMessage.roomId, testVoiceMessage.roomId);
      expect(copiedMessage.senderId, testVoiceMessage.senderId);
      expect(copiedMessage.senderName, testVoiceMessage.senderName);
      expect(copiedMessage.audioUrl, testVoiceMessage.audioUrl);
      expect(copiedMessage.duration, testVoiceMessage.duration);
      expect(copiedMessage.timestamp, testVoiceMessage.timestamp);
    });

    test('VoiceMessage with different durations', () {
      final tenSeconds = testVoiceMessage.copyWith(
        duration: const Duration(seconds: 10),
      );
      expect(tenSeconds.formattedDuration, '00:10');

      final fiveMinutes = testVoiceMessage.copyWith(
        duration: const Duration(minutes: 5),
      );
      expect(fiveMinutes.formattedDuration, '05:00');

      final thirtySeconds = testVoiceMessage.copyWith(
        duration: const Duration(seconds: 30),
      );
      expect(thirtySeconds.formattedDuration, '00:30');
    });

    test('VoiceMessage file size formatting precision', () {
      final smallFile = testVoiceMessage.copyWith(fileSize: 1500);
      expect(smallFile.formattedFileSize, '1.46 KB');

      final mediumFile = testVoiceMessage.copyWith(fileSize: 1500000);
      expect(mediumFile.formattedFileSize, '1.43 MB');
    });

    test('Multiple voice messages in room', () {
      final msg1 = testVoiceMessage;
      final msg2 = testVoiceMessage.copyWith(
        id: 'voice-002',
        duration: const Duration(minutes: 1),
        timestamp: now.add(const Duration(seconds: 30)),
      );
      final msg3 = testVoiceMessage.copyWith(
        id: 'voice-003',
        duration: const Duration(minutes: 3, seconds: 15),
        timestamp: now.add(const Duration(minutes: 1)),
      );

      final messages = [msg1, msg2, msg3];
      expect(messages.length, 3);
      expect(messages[0].formattedDuration, '02:30');
      expect(messages[1].formattedDuration, '01:00');
      expect(messages[2].formattedDuration, '03:15');
    });
  });
}
