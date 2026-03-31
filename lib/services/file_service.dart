import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:mainproject/constants.dart';

/// Service for picking and uploading files via Cloudinary
class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// Pick a file from the device
  Future<PlatformFile?> pickFile({FileType type = FileType.any}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: false,
        withData: kIsWeb, // important for web
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      debugPrint('FileService: Error picking file: $e');
      return null;
    }
  }

  /// Upload a file to Cloudinary and return the secure URL
  Future<String> uploadFile({
    String? filePath,
    Uint8List? fileBytes,
    required String roomId,
    String? fileName,
    String folder = 'chat_files',
  }) async {
    debugPrint('FileService: Starting upload to Cloudinary...');

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConfig.uploadUrl),
      );

      // Add the file based on path (mobile/desktop) or bytes (web)
      if (kIsWeb || filePath == null) {
        if (fileBytes == null) throw Exception('File bytes missing for web upload');
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName ?? 'upload',
        ));
      } else {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('File not found at $filePath');
        }
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      // Add Cloudinary parameters
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = '$folder/$roomId';
      request.fields['resource_type'] = 'auto';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('FileService: Cloudinary response ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Upload failed (${response.statusCode}): ${response.body}');
      }

      final responseData = json.decode(response.body);
      final secureUrl = responseData['secure_url'] as String;

      debugPrint('FileService: Upload success, URL = $secureUrl');
      return secureUrl;
    } catch (e) {
      debugPrint('FileService: Upload error: $e');
      throw Exception('Failed to upload file: $e');
    }
  }
}
