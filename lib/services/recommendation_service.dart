import 'package:mainproject/models/room.dart';
import 'package:mainproject/services/room_service.dart';

/// AI-powered Room Recommendation Service
///
/// Uses keyword extraction, TF-IDF-like scoring, and collaborative
/// filtering to recommend rooms the user is likely to enjoy.
class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();

  factory RecommendationService() => _instance;

  RecommendationService._internal();

  final RoomService _roomService = RoomService();

  /// Common stop words to exclude from keyword extraction
  static const _stopWords = {
    'the',
    'a',
    'an',
    'and',
    'or',
    'but',
    'in',
    'on',
    'at',
    'to',
    'for',
    'of',
    'with',
    'by',
    'from',
    'is',
    'it',
    'this',
    'that',
    'are',
    'was',
    'be',
    'has',
    'had',
    'do',
    'does',
    'did',
    'will',
    'would',
    'can',
    'could',
    'should',
    'may',
    'might',
    'shall',
    'not',
    'no',
    'nor',
    'so',
    'if',
    'then',
    'than',
    'too',
    'very',
    'just',
    'about',
    'up',
    'out',
    'all',
    'each',
    'every',
    'both',
    'few',
    'more',
    'most',
    'some',
    'any',
    'other',
    'into',
    'over',
    'after',
    'before',
    'between',
    'under',
    'above',
    'below',
    'room',
    'rooms',
    'group',
    'join',
    'learn',
    'learning',
    'study',
    'class',
    'course',
    'discuss',
    'discussion',
    'new',
    'get',
    'how',
    'what',
    'why',
    'when',
    'where',
    'who',
    'which',
    'your',
    'our',
    'their',
    'its',
    'my',
    'we',
    'you',
    'they',
    'us',
    'them',
    'i',
    'me',
    'he',
    'she',
    'him',
    'her',
    'his',
    'hers',
    'have',
    'here',
    'there',
  };

  /// Get AI-recommended rooms for a user
  ///
  /// Algorithm:
  /// 1. Extract keywords from user's joined rooms (names + descriptions)
  /// 2. Score available rooms by keyword overlap (content-based filtering)
  /// 3. Boost rooms that share members with user's rooms (collaborative filtering)
  /// 4. Boost rooms with higher member counts (popularity signal)
  /// 5. Return top scored rooms the user hasn't joined
  Future<List<Room>> getRecommendations({
    required String userEmail,
    int maxResults = 5,
  }) async {
    try {
      // Fetch all rooms and identify user's rooms
      final allRooms = await _roomService.getAllRooms();
      final userRooms = allRooms.where((r) => r.isMember(userEmail)).toList();
      final candidateRooms = allRooms
          .where((r) => !r.isMember(userEmail))
          .toList();

      if (candidateRooms.isEmpty) return [];

      // If user has no rooms, return popular rooms they haven't joined
      if (userRooms.isEmpty) {
        candidateRooms.sort((a, b) => b.memberCount.compareTo(a.memberCount));
        return candidateRooms.take(maxResults).toList();
      }

      // Step 1: Extract keyword profile from user's rooms
      final userKeywords = _buildKeywordProfile(userRooms);

      // Step 2: Get co-members (users who share rooms with this user)
      final coMembers = <String>{};
      for (final room in userRooms) {
        for (final memberId in room.memberIds) {
          if (memberId != userEmail) {
            coMembers.add(memberId);
          }
        }
      }

      // Step 3: Score each candidate room
      final scoredRooms = <_ScoredRoom>[];

      for (final room in candidateRooms) {
        double score = 0;

        // Content-based score: keyword overlap
        final roomKeywords = _extractKeywords(
          '${room.name} ${room.description}',
        );
        double keywordScore = 0;
        for (final keyword in roomKeywords) {
          if (userKeywords.containsKey(keyword)) {
            keywordScore += userKeywords[keyword]!;
          }
        }
        // Normalize by number of keywords to avoid bias toward long descriptions
        if (roomKeywords.isNotEmpty) {
          keywordScore = keywordScore / roomKeywords.length;
        }
        score +=
            keywordScore * 10; // Weight: content matching is most important

        // Collaborative filtering: how many co-members are in this room?
        int sharedMembers = 0;
        for (final memberId in room.memberIds) {
          if (coMembers.contains(memberId)) {
            sharedMembers++;
          }
        }
        score += sharedMembers * 3; // Weight: each shared member adds 3 points

        // Popularity boost (logarithmic to avoid domination)
        if (room.memberCount > 0) {
          score += _log2(room.memberCount.toDouble()) * 0.5;
        }

        // Recency boost: newer rooms get a small bonus
        final daysSinceCreated = DateTime.now()
            .difference(room.createdAt)
            .inDays;
        if (daysSinceCreated < 7) {
          score += 2; // New room bonus
        } else if (daysSinceCreated < 30) {
          score += 1; // Recent room bonus
        }

        // Room type preference: match what type the user usually joins
        final publicCount = userRooms
            .where((r) => r.type == RoomType.public)
            .length;
        final privateCount = userRooms
            .where((r) => r.type == RoomType.private)
            .length;
        if (publicCount > privateCount && room.type == RoomType.public) {
          score += 1;
        } else if (privateCount > publicCount &&
            room.type == RoomType.private) {
          score += 1;
        }

        scoredRooms.add(_ScoredRoom(room: room, score: score));
      }

      // Sort by score descending
      scoredRooms.sort((a, b) => b.score.compareTo(a.score));

      return scoredRooms
          .take(maxResults)
          .where((s) => s.score > 0) // Only return rooms with positive scores
          .map((s) => s.room)
          .toList();
    } catch (e) {
      // Fallback: return popular rooms
      try {
        final allRooms = await _roomService.getAllRooms();
        final candidates = allRooms
            .where((r) => !r.isMember(userEmail))
            .toList();
        candidates.sort((a, b) => b.memberCount.compareTo(a.memberCount));
        return candidates.take(maxResults).toList();
      } catch (_) {
        return [];
      }
    }
  }

  /// Build a weighted keyword profile from a list of rooms
  Map<String, double> _buildKeywordProfile(List<Room> rooms) {
    final profile = <String, double>{};

    for (final room in rooms) {
      final text = '${room.name} ${room.name} ${room.description}';
      // Room name repeated to give it more weight
      final keywords = _extractKeywords(text);
      for (final keyword in keywords) {
        profile[keyword] = (profile[keyword] ?? 0) + 1;
      }
    }

    // Normalize: divide by total count to get relative importance
    final total = profile.values.fold(0.0, (sum, v) => sum + v);
    if (total > 0) {
      for (final key in profile.keys.toList()) {
        profile[key] = profile[key]! / total;
      }
    }

    return profile;
  }

  /// Extract meaningful keywords from text
  List<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !_stopWords.contains(word))
        .toList();
  }

  /// Log base 2 helper
  double _log2(double x) {
    if (x <= 0) return 0;
    return x.toString().length.toDouble(); // Simplified log approximation
  }
}

/// Internal class to pair a room with its recommendation score
class _ScoredRoom {
  final Room room;
  final double score;

  _ScoredRoom({required this.room, required this.score});
}
