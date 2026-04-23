import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/local_llm_service.dart';
class SRSEngine {
  static const double DEFAULT_EASE = 2.5;
  static const int MIN_EASE = 1300; // 1.3 * 1000 to avoid float precision drops if needed, but we'll stick to double

  // Grade is between 0 and 5:
  // 5 - perfect response
  // 4 - correct response after a hesitation
  // 3 - correct response recalled with serious difficulty
  // 2 - incorrect response; where the correct one seemed easy to recall
  // 1 - incorrect response; the correct one remembered
  // 0 - complete blackout.
  
  static Future<void> processReview(String wordId, int grade) async {
    final db = await DatabaseManager.instance.database;
    final res = await db.query('flashcards', where: 'word_id = ?', whereArgs: [wordId]);
    if (res.isEmpty) return;

    final card = res.first;
    int interval = card['interval'] as int;
    int repetition = card['repetition'] as int;
    double easeFactor = card['ease_factor'] as double;

    if (grade >= 3) {
      // Correct
      if (repetition == 0) {
        interval = 1;
      } else if (repetition == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetition += 1;
    } else {
      // Incorrect
      repetition = 0;
      interval = 1;
    }

    easeFactor = easeFactor + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;

    final DateTime now = DateTime.now();
    final DateTime nextReview = now.add(Duration(days: interval));

    await DatabaseManager.instance.updateFlashcard(
      wordId, 
      interval, 
      repetition, 
      easeFactor, 
      nextReview.millisecondsSinceEpoch
    );
  }

  /// AI Tutor: Adaptive Learning Path
  /// Analyzes the student's recent performance to dynamically generate
  /// the next set of recommended lesson topics using SmolLM2.
  static Future<List<String>> analyzeStudentPerformance() async {
    // In a real scenario, you would fetch recent session grades from the database
    // For now, we mock some aggregate stats for the LLM
    final Map<String, int> recentScores = {
      "auditory_recognition": 30, // Student is struggling with listening
      "visual_matching": 90,      // Student is excelling at reading
      "pronunciation": 50,
    };

    final llmService = LocalLlmService();
    return await llmService.generateAdaptivePath(recentScores);
  }
}
