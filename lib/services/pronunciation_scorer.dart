import 'dart:math';

/// Scores pronunciation accuracy by comparing transcribed speech to expected text.
/// Uses Levenshtein distance normalized to a 0-100 score.
class PronunciationScorer {
  /// Compare [transcribed] text against [expected] text.
  /// Returns a score from 0 (no match) to 100 (perfect match).
  static int score(String transcribed, String expected) {
    final t = transcribed.trim().toLowerCase();
    final e = expected.trim().toLowerCase();

    if (t.isEmpty || e.isEmpty) return 0;
    if (t == e) return 100;

    final distance = _levenshtein(t, e);
    final maxLen = max(t.length, e.length);
    final similarity = 1.0 - (distance / maxLen);
    return (similarity * 100).round().clamp(0, 100);
  }

  /// Returns a qualitative label for the score.
  static String label(int score) {
    if (score >= 90) return 'Excellent! 🌟';
    if (score >= 70) return 'Great! 👍';
    if (score >= 50) return 'Good effort! 💪';
    if (score >= 30) return 'Keep practicing 📖';
    return 'Try again 🔄';
  }

  /// Standard Levenshtein distance algorithm.
  static int _levenshtein(String s, String t) {
    final m = s.length;
    final n = t.length;

    // Use two-row optimization to save memory
    List<int> prev = List.generate(n + 1, (j) => j);
    List<int> curr = List.filled(n + 1, 0);

    for (int i = 1; i <= m; i++) {
      curr[0] = i;
      for (int j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1,       // deletion
          curr[j - 1] + 1,   // insertion
          prev[j - 1] + cost, // substitution
        ].reduce(min);
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[n];
  }
}
