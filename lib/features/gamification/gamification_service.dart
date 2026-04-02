import 'package:speechmate/services/progress_service.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final ProgressService _progressService = ProgressService();

  // XP thresholds per level
  static const List<int> _levelThresholds = [0, 100, 250, 500, 850, 1300, 2000, 3000, 4500, 7000];

  /// Get current level from real XP data
  Future<int> getCurrentLevel() async {
    final xp = await getXP();
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (xp >= _levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  /// Get XP needed for next level
  Future<int> getNextLevelXP() async {
    final level = await getCurrentLevel();
    if (level >= _levelThresholds.length) return _levelThresholds.last;
    return _levelThresholds[level]; // next threshold
  }

  /// Get total XP from real progress data
  Future<int> getXP() async {
    try {
      final stats = await _progressService.getProgressStats();
      final wordsLearned = stats['wordsLearned'] ?? 0;
      final quizzesTaken = stats['quizzesTaken'] ?? 0;
      final dayStreak = stats['dayStreak'] ?? 0;
      
      // XP formula: 10pts per word + 25pts per quiz + 5pts per streak day
      return (wordsLearned * 10) + (quizzesTaken * 25) + (dayStreak * 5);
    } catch (_) {
      return 0;
    }
  }

  /// Get current daily streak from real data
  Future<int> getCurrentStreak() async {
    try {
      final stats = await _progressService.getProgressStats();
      return stats['dayStreak'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Compute badges based on real progress
  Future<List<Map<String, dynamic>>> getBadges() async {
    try {
      final stats = await _progressService.getProgressStats();
      final wordsLearned = stats['wordsLearned'] ?? 0;
      final quizzesTaken = stats['quizzesTaken'] ?? 0;
      final dayStreak = stats['dayStreak'] ?? 0;

      return [
        {
          'icon': '🔥',
          'name': 'Streak Fire',
          'desc': '7 Day Streak',
          'obtained': dayStreak >= 7,
        },
        {
          'icon': '📖',
          'name': 'Bookworm',
          'desc': 'Learned 50 Words',
          'obtained': wordsLearned >= 50,
        },
        {
          'icon': '🧠',
          'name': 'Quiz Master',
          'desc': 'Completed 10 Quizzes',
          'obtained': quizzesTaken >= 10,
        },
        {
          'icon': '🏆',
          'name': 'Century Club',
          'desc': 'Learned 100 Words',
          'obtained': wordsLearned >= 100,
        },
        {
          'icon': '⚡',
          'name': 'Speed Learner',
          'desc': '30 Day Streak',
          'obtained': dayStreak >= 30,
        },
      ];
    } catch (_) {
      return [];
    }
  }
  
  static String getLevelTitle(int level) {
    const titles = [
      "Novice Explorer",
      "Seed Planter",
      "Word Gatherer",
      "Story Teller",
      "Village Voice",
      "Word Hunter",
      "Culture Keeper",
      "Master Linguist",
      "Legend",
      "Ancestor's Echo"
    ];
    if (level <= 0) return titles[0];
    if (level > titles.length) return titles.last;
    return titles[level - 1];
  }
}
