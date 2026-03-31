import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:mainproject/constants.dart';

/// Service for recording and uploading voice messages via Cloudinary
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  AudioRecorder? _recorder;
  bool _isRecording = false;
  String? _currentPath;
  DateTime? _recordingStartTime;

  bool get isRecording => _isRecording;

  /// Get or create the recorder instance
  AudioRecorder _getRecorder() {
    _recorder ??= AudioRecorder();
    return _recorder!;
  }

  /// Check if mic permission is granted
  Future<bool> hasPermission() async {
    return await _getRecorder().hasPermission();
  }

  /// Start recording audio
  Future<void> startRecording() async {
    if (_isRecording) return;

    final recorder = _getRecorder();

    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      throw Exception(
        'Microphone permission not granted. Please enable it in Settings.',
      );
    }

    // Check if recording is supported
    final isSupported = await recorder.isEncoderSupported(AudioEncoder.aacLc);
    debugPrint('VoiceService: AAC-LC supported = $isSupported');

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Use .m4a for AAC, .wav as fallback
    final encoder = isSupported ? AudioEncoder.aacLc : AudioEncoder.wav;
    final ext = isSupported ? 'm4a' : 'wav';
    _currentPath = p.join(tempDir.path, 'voice_$timestamp.$ext');

    debugPrint(
      'VoiceService: Recording to $_currentPath with encoder $encoder',
    );

    final config = RecordConfig(
      encoder: encoder,
      sampleRate: 44100,
      bitRate: 128000,
    );

    await recorder.start(config, path: _currentPath!);
    _isRecording = true;
    _recordingStartTime = DateTime.now();
    debugPrint('VoiceService: Recording started');
  }

  /// Stop recording and return the file path and duration
  Future<VoiceRecordingResult?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _getRecorder().stop();
    _isRecording = false;

    debugPrint('VoiceService: Recording stopped, path = $path');

    if (path == null || _currentPath == null) return null;

    final duration = DateTime.now().difference(_recordingStartTime!);
    final file = File(_currentPath!);

    if (!await file.exists()) {
      debugPrint('VoiceService: Recording file does not exist!');
      return null;
    }

    final fileSize = await file.length();
    debugPrint(
      'VoiceService: Recording complete - ${duration.inSeconds}s, ${fileSize}bytes',
    );

    return VoiceRecordingResult(
      filePath: _currentPath!,
      duration: duration,
      fileSize: fileSize,
    );
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    await _getRecorder().stop();
    _isRecording = false;

    // Delete the temp file
    if (_currentPath != null) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _currentPath = null;
  }

  /// Upload voice recording to Cloudinary and return the secure URL
  Future<String> uploadVoiceMessage({
    required String filePath,
    required String roomId,
    required String senderId,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Recording file not found');
    }

    debugPrint('VoiceService: Uploading to Cloudinary...');

    try {
      // Build multipart request to Cloudinary
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConfig.uploadUrl),
      );

      // Add the audio file
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      // Add Cloudinary parameters
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = 'voice_messages/$roomId';
      request.fields['resource_type'] = 'auto';

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('VoiceService: Cloudinary response ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('VoiceService: Upload error body: ${response.body}');
        throw Exception(
          'Cloudinary upload failed (${response.statusCode}): ${response.body}',
        );
      }

      final responseData = json.decode(response.body);
      final secureUrl = responseData['secure_url'] as String;

      debugPrint('VoiceService: Upload success, URL = $secureUrl');

      // Clean up temp file
      await file.delete();

      return secureUrl;
    } catch (e) {
      debugPrint('VoiceService: Upload error: $e');
      throw Exception('Failed to upload voice message: $e');
    }
  }

  /// Dispose the recorder
  Future<void> dispose() async {
    if (_isRecording) {
      await cancelRecording();
    }
    _recorder?.dispose();
    _recorder = null;
  }
}

/// Result of a voice recording
class VoiceRecordingResult {
  final String filePath;
  final Duration duration;
  final int fileSize;

  VoiceRecordingResult({
    required this.filePath,
    required this.duration,
    required this.fileSize,
  });
}
