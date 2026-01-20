/// Voice message model for audio communications
class VoiceMessage {
  final String id;
  final String messageId;
  final String roomId;
  final String senderId;
  final String senderName;
  final String audioUrl;
  final Duration duration;
  final DateTime timestamp;
  final int? fileSize;

  VoiceMessage({
    required this.id,
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.audioUrl,
    required this.duration,
    required this.timestamp,
    this.fileSize,
  });

  /// Get formatted duration (MM:SS)
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted file size
  String? get formattedFileSize {
    if (fileSize == null) return null;
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(2)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Create a copy with modified fields
  VoiceMessage copyWith({
    String? id,
    String? messageId,
    String? roomId,
    String? senderId,
    String? senderName,
    String? audioUrl,
    Duration? duration,
    DateTime? timestamp,
    int? fileSize,
  }) {
    return VoiceMessage(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  @override
  String toString() =>
      'VoiceMessage(id: $id, sender: $senderName, duration: $formattedDuration)';
}
