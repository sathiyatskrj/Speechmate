import 'package:speechmate/services/progress_service.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final ProgressService _progressService = ProgressService();

  // Static cached values for UI access
  static int xp = 0;
  static int currentLevel = 1;
  static int nextLevelXp = 100;
  static int currentStreak = 0;

  // XP thresholds per level
  static const List<int> _levelThresholds = [0, 100, 250, 500, 850, 1300, 2000, 3000, 4500, 7000];

  /// Initialize and load stats
  static Future<void> initialize() async {
     await _instance.syncWithProgress();
  }

  /// Sync real progress stats into cached static values
  Future<void> syncWithProgress() async {
    xp = await getXP();
    currentLevel = await getCurrentLevel();
    nextLevelXp = await getNextLevelXP();
    currentStreak = await getCurrentStreak();
  }

  /// Get current level from real XP data
  Future<int> getCurrentLevel() async {
    final currentXp = await getXP();
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (currentXp >= _levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  /// Get XP needed for next level
  Future<int> getNextLevelXP() async {
    final level = await getCurrentLevel();
    if (level >= _levelThresholds.length) return _levelThresholds.last;
    return _levelThresholds[level]; // next threshold
  }

  /// Diminishing returns XP calculator for a given count and tier thresholds
  int _tieredXP(int count, List<List<int>> tiers) {
    int xpTotal = 0;
    int remaining = count;
    for (final tier in tiers) {
      final cap = tier[0]; // max items at this rate
      final rate = tier[1]; // XP per item
      if (remaining <= 0) break;
      final used = remaining > cap ? cap : remaining;
      xpTotal += used * rate;
      remaining -= used;
    }
    return xpTotal;
  }

  /// Get total XP from real progress data with diminishing returns
  Future<int> getXP() async {
    try {
      final stats = await _progressService.getProgressStats();
      final wordsLearned = stats['wordsLearned'] ?? 0;
      final quizzesTaken = stats['quizzesTaken'] ?? 0;
      final dayStreak = stats['dayStreak'] ?? 0;
      final communityPosts = stats['communityPosts'] ?? 0;
      
      // Words: 1-50 = 10xp, 51-100 = 7xp, 101-200 = 4xp, 200+ = 2xp
      final wordXP = _tieredXP(wordsLearned, [[50, 10], [50, 7], [100, 4], [99999, 2]]);
      // Quizzes: 1-10 = 25xp, 11-30 = 15xp, 30+ = 8xp
      final quizXP = _tieredXP(quizzesTaken, [[10, 25], [20, 15], [99999, 8]]);
      // Streak & community stay linear (hard to farm)
      final streakXP = dayStreak * 5;
      final communityXP = communityPosts * 15;
      
      return wordXP + quizXP + streakXP + communityXP;
    } catch (e) { debugPrint("Silent error caught: $e");
      return 0;
    }
  }

  /// Refreshes the cached stats from the underlying progress service
  static Future<void> refresh() async {
     await initialize();
  }

  Future<int> getCurrentLevelFromXp(int xpVal) async {
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (xpVal >= _levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  Future<int> getNextLevelXpFromLevel(int level) async {
     if (level >= _levelThresholds.length) return _levelThresholds.last;
    return _levelThresholds[level];
  }

  /// Get current daily streak from real data
  Future<int> getCurrentStreak() async {
    try {
      final stats = await _progressService.getProgressStats();
      return stats['dayStreak'] ?? 0;
    } catch (e) { debugPrint("Silent error caught: $e");
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
          'icon': '🌊',
          'name': 'Ocean Navigator',
          'desc': '7 Day Streak',
          'obtained': dayStreak >= 7,
        },
        {
          'icon': '🛶',
          'name': 'Hodi Constructor',
          'desc': 'Learned 50 Words',
          'obtained': wordsLearned >= 50,
        },
        {
          'icon': '🌿',
          'name': 'Pandanus Gatherer',
          'desc': 'Completed 10 Quizzes',
          'obtained': quizzesTaken >= 10,
        },
        {
          'icon': '🐢',
          'name': 'Sea Turtle Guide',
          'desc': 'Learned 100 Words',
          'obtained': wordsLearned >= 100,
        },
        {
          'icon': '🏝️',
          'name': 'Island Protector',
          'desc': '30 Day Streak',
          'obtained': dayStreak >= 30,
        },
      ];
    } catch (e) { debugPrint("Silent error caught: $e");
      return [];
    }
  }
  
  static String getLevelTitle(int level) {
    const titles = [
      "Island Guest",
      "Shell Gatherer",
      "Hodi Weaver",
      "Turtle Tracker",
      "Ocean Navigator",
      "Jungle Guide",
      "Village Elder",
      "Culture Keeper",
      "Oral Historian",
      "Ancestor's Echo"
    ];
    if (level <= 0) return titles[0];
    if (level > titles.length) return titles.last;
    return titles[level - 1];
  }
}
