import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:mainproject/constants.dart';

/// AI-powered Content Moderation Service
class ContentModerationService {
  static final ContentModerationService _instance =
      ContentModerationService._internal();

  factory ContentModerationService() => _instance;

  ContentModerationService._internal();

  /// Gemini model instance (lazy-initialized)
  GenerativeModel? _model;

  GenerativeModel get _geminiModel {
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: GeminiConfig.model,
      generationConfig: GenerationConfig(
        temperature: 0.1, // Low temperature for consistent classification
        maxOutputTokens: 20,
      ),
    );
    return _model!;
  }

  /// List of common inappropriate words (fast local check)
  static const Set<String> _localProfanityList = {
    'hate', 'stupid', 'idiot', 'dumb', 'loser', 'kill', 'die',
    // In a real app, this list would be much longer
  };

  /// Check if content contains foul language (hybrid approach)
  Future<ModerationResult> checkContent(String content) async {
    if (content.trim().isEmpty) {
      return ModerationResult.approved();
    }

    // 1. Fast Local Check
    final lowerContent = content.toLowerCase();
    for (var word in _localProfanityList) {
      if (lowerContent.contains(word)) {
        return ModerationResult.rejected(
          reason: 'Inappropriate language detected (Local Filter)',
        );
      }
    }

    // 2. AI Check (Gemini) for context-aware moderation
    try {
      final prompt =
          '''
You are a content moderator for a student collaboration app. 
Analyze the following message and determine if it contains foul language, hate speech, bullying, or highly inappropriate content.

Rules:
- If inappropriate: Respond only with "REJECTED: [short reason]"
- If appropriate: Respond only with "APPROVED"

Message:
"""
$content
"""
''';

      final response = await _geminiModel.generateContent([
        Content.text(prompt),
      ]);

      final result = response.text?.trim() ?? 'APPROVED';

      if (result.startsWith('REJECTED')) {
        final reason = result.replaceFirst('REJECTED:', '').trim();
        return ModerationResult.rejected(
          reason: reason.isEmpty ? 'Inappropriate content' : reason,
        );
      }

      return ModerationResult.approved();
    } catch (e) {
      debugPrint('Moderation error: $e');
      // If AI fails, we fall back to manual approval or just local check
      return ModerationResult.approved();
    }
  }

  /// Simple filter to mask bad words (Local only)
  String maskProfanity(String content) {
    String filtered = content;
    final lowerContent = content.toLowerCase();

    for (var word in _localProfanityList) {
      if (lowerContent.contains(word)) {
        final regex = RegExp(RegExp.escape(word), caseSensitive: false);
        filtered = filtered.replaceAll(regex, '*' * word.length);
      }
    }
    return filtered;
  }
}

/// Result of content moderation
class ModerationResult {
  final bool isApproved;
  final String? reason;

  ModerationResult.approved() : isApproved = true, reason = null;
  ModerationResult.rejected({required this.reason}) : isApproved = false;
}
