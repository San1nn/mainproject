/// Content Moderation Service
/// Handles detection and filtering of inappropriate content
class ContentModerationService {
  static final ContentModerationService _instance =
      ContentModerationService._internal();

  factory ContentModerationService() {
    return _instance;
  }

  ContentModerationService._internal();

  /// List of inappropriate words/phrases to filter
  static const Set<String> _inappropriateWords = {
    'hate',
    'stupid',
    'idiot',
    'dumb',
    'ugly',
    'loser',
    'useless',
    'pathetic',
    'disgusting',
    'terrible',
  };

  /// Check if content contains inappropriate language
  Future<bool> containsFoulLanguage(String content) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    final lowerContent = content.toLowerCase();

    for (var word in _inappropriateWords) {
      if (lowerContent.contains(word)) {
        return true;
      }
    }

    return false;
  }

  /// Filter inappropriate words from content
  Future<String> filterContent(String content) async {
    await Future.delayed(const Duration(milliseconds: 250));

    String filtered = content;

    for (var word in _inappropriateWords) {
      final regex = RegExp(word, caseSensitive: false);
      filtered = filtered.replaceAll(regex, '*' * word.length);
    }

    return filtered;
  }

  /// Get flagged words in content
  Future<List<String>> getFlaggedWords(String content) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final lowerContent = content.toLowerCase();
    final flaggedWords = <String>[];

    for (var word in _inappropriateWords) {
      if (lowerContent.contains(word)) {
        flaggedWords.add(word);
      }
    }

    return flaggedWords;
  }

  /// Check if content is spam
  Future<bool> isSpam(String content) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Simple spam detection logic
    final allCaps = content.toUpperCase() == content && content.length > 10;
    final excessiveSpecialChars =
        RegExp(r'[!@#$%^&*]{3,}').hasMatch(content);
    final repetitiveText = RegExp(r'(.)\1{4,}').hasMatch(content);
    final urlLikePattern = RegExp(r'https?://|www\.|\.com|\.net');

    return allCaps || excessiveSpecialChars || repetitiveText || urlLikePattern.hasMatch(content);
  }

  /// Get moderation score (0.0 to 1.0)
  /// 0.0 = fully appropriate, 1.0 = highly inappropriate
  Future<double> getModerationScore(String content) async {
    await Future.delayed(const Duration(milliseconds: 350));

    double score = 0.0;

    // Check for foul language
    if (await containsFoulLanguage(content)) {
      score += 0.5;
    }

    // Check for spam
    if (await isSpam(content)) {
      score += 0.3;
    }

    // Check length
    if (content.length > 500) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Generate moderation report for content
  Future<ModerationReport> generateModerationReport(String content) async {
    final hasFoulLanguage = await containsFoulLanguage(content);
    final isSpamContent = await isSpam(content);
    final score = await getModerationScore(content);
    final flaggedWords = await getFlaggedWords(content);

    return ModerationReport(
      content: content,
      hasFoulLanguage: hasFoulLanguage,
      isSpam: isSpamContent,
      moderationScore: score,
      flaggedWords: flaggedWords,
      isApproved: score < 0.5,
      requiresReview: score >= 0.3 && score < 0.7,
      timestamp: DateTime.now(),
    );
  }
}

/// Moderation report data class
class ModerationReport {
  final String content;
  final bool hasFoulLanguage;
  final bool isSpam;
  final double moderationScore;
  final List<String> flaggedWords;
  final bool isApproved;
  final bool requiresReview;
  final DateTime timestamp;

  ModerationReport({
    required this.content,
    required this.hasFoulLanguage,
    required this.isSpam,
    required this.moderationScore,
    required this.flaggedWords,
    required this.isApproved,
    required this.requiresReview,
    required this.timestamp,
  });

  /// Get status string
  String get status {
    if (isApproved) return 'Approved';
    if (requiresReview) return 'Review Required';
    return 'Rejected';
  }

  @override
  String toString() =>
      'ModerationReport(score: $moderationScore, status: $status)';
}
