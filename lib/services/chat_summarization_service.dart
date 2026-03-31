import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:mainproject/constants.dart';

/// AI-powered Chat Summarization Service using Firebase AI Logic (Gemini)
class ChatSummarizationService {
  static final ChatSummarizationService _instance =
      ChatSummarizationService._internal();

  factory ChatSummarizationService() => _instance;

  ChatSummarizationService._internal();

  /// In-memory cache: messageId → summary
  final Map<String, String> _cache = {};

  /// Gemini model via Firebase AI Logic (lazy-initialized)
  GenerativeModel? _model;

  /// Returns the Gemini model, creating it on first use
  GenerativeModel get _geminiModel {
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: GeminiConfig.model,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 256,
      ),
    );
    return _model!;
  }

  /// Check if a message is long enough to warrant summarization
  bool canSummarize(String content) {
    return content.trim().length >= GeminiConfig.minLengthForSummary;
  }

  /// Summarize a single long message.
  /// Returns the cached summary if available, otherwise calls Gemini.
  Future<String> summarizeMessage(String messageId, String content) async {
    // Return cached summary if exists
    if (_cache.containsKey(messageId)) {
      return _cache[messageId]!;
    }

    if (content.trim().isEmpty) {
      return 'No content to summarize.';
    }

    try {
      final prompt =
          '''
You are a helpful assistant inside a student collaboration app called StudWise.
Summarize the following chat message in 1-3 concise bullet points.
Keep it short, clear, and student-friendly. Use plain language.
Do NOT add any extra commentary — just the bullet points.

Message:
"""
$content
"""
''';

      final response = await _geminiModel.generateContent([
        Content.text(prompt),
      ]);

      final summary = response.text?.trim() ?? 'Could not generate summary.';
      // Cache the result so we don't need to call again
      _cache[messageId] = summary;
      return summary;
    } catch (e) {
      debugPrint('Summarize error: $e');
      return 'Unable to generate summary. Please try again in a moment.';
    }
  }

  /// Summarize the entire chat (all recent text messages in a room).
  /// [messages] is a list of maps with 'senderName' and 'content' keys.
  Future<String> summarizeChat(
    String roomId,
    List<Map<String, String>> messages,
  ) async {
    final cacheKey = 'room_${roomId}_${messages.length}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    if (messages.isEmpty) {
      return 'No messages to summarize.';
    }

    try {
      final formattedMessages = messages
          .map((m) => '${m['senderName']}: ${m['content']}')
          .join('\n');

      final prompt =
          '''
You are a helpful assistant inside a student collaboration app called StudWise.
Provide a comprehensive yet concise "Quick Rundown" of the following chat conversation.

The rundown should include:
1. **The Core Topic**: What were they talking about? (1 sentence)
2. **Key Takeaways**: Detailed bullet points explaining the main arguments, facts, or ideas shared.
3. **Decisions or Action Items**: If any specific plans were made or tasks assigned, list them clearly.

Keep the tone student-friendly, encouraging, and clear.
Avoid generic summaries; use specific details from the chat.

Chat Messages:
"""
$formattedMessages
"""
''';

      final response = await _geminiModel.generateContent([
        Content.text(prompt),
      ]);

      final summary = response.text?.trim() ?? 'Could not generate summary.';
      _cache[cacheKey] = summary;
      return summary;
    } catch (e) {
      debugPrint('Chat summarize error: $e');
      return 'Unable to generate summary. Please try again in a moment.';
    }
  }

  /// Clear all cached summaries
  void clearCache() => _cache.clear();

  /// Remove a specific cached summary
  void removeCached(String key) => _cache.remove(key);
}
