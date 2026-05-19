import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M2-05: Achievement badges for student milestones.
class AchievementBadgesScreen extends StatefulWidget {
  const AchievementBadgesScreen({super.key});
  @override
  State<AchievementBadgesScreen> createState() => _AchievementBadgesScreenState();
}

class _AchievementBadgesScreenState extends State<AchievementBadgesScreen> {
  List<Map<String, dynamic>> _badges = [];
  bool _isLoading = true;

  static final List<Map<String, dynamic>> _allBadges = [
    {'id': 'first_word', 'title': 'First Word', 'desc': 'Learned your first Nicobarese word', 'emoji': '🌱', 'threshold': 1, 'metric': 'words'},
    {'id': 'vocab_10', 'title': 'Word Explorer', 'desc': 'Learned 10 words', 'emoji': '📚', 'threshold': 10, 'metric': 'words'},
    {'id': 'vocab_50', 'title': 'Word Master', 'desc': 'Learned 50 words', 'emoji': '🎓', 'threshold': 50, 'metric': 'words'},
    {'id': 'vocab_100', 'title': 'Lexicon Legend', 'desc': 'Learned 100 words', 'emoji': '👑', 'threshold': 100, 'metric': 'words'},
    {'id': 'streak_3', 'title': 'On Fire', 'desc': '3-day streak', 'emoji': '🔥', 'threshold': 3, 'metric': 'streak'},
    {'id': 'streak_7', 'title': 'Week Warrior', 'desc': '7-day streak', 'emoji': '⚡', 'threshold': 7, 'metric': 'streak'},
    {'id': 'streak_30', 'title': 'Monthly Maven', 'desc': '30-day streak', 'emoji': '🏆', 'threshold': 30, 'metric': 'streak'},
    {'id': 'quiz_perfect', 'title': 'Perfect Score', 'desc': '100% on a quiz', 'emoji': '💯', 'threshold': 1, 'metric': 'perfect_quizzes'},
    {'id': 'quiz_5', 'title': 'Quiz Champion', 'desc': 'Completed 5 quizzes', 'emoji': '🧠', 'threshold': 5, 'metric': 'quizzes'},
    {'id': 'voice_first', 'title': 'Voice Pioneer', 'desc': 'Used voice translation', 'emoji': '🎙️', 'threshold': 1, 'metric': 'voice_uses'},
    {'id': 'level_5', 'title': 'Level 5 Scholar', 'desc': 'Reached Level 5', 'emoji': '🌟', 'threshold': 5, 'metric': 'level'},
    {'id': 'level_10', 'title': 'Nicobarese Sage', 'desc': 'Completed all 10 levels', 'emoji': '🏅', 'threshold': 10, 'metric': 'level'},
  ];

  @override
  void initState() { super.initState(); _loadBadges(); }

  Future<void> _loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final metrics = {
      'words': prefs.getInt('words_learned') ?? 12,
      'streak': prefs.getInt('learning_streak') ?? 4,
      'quizzes': prefs.getInt('quizzes_completed') ?? 3,
      'perfect_quizzes': prefs.getInt('perfect_quizzes') ?? 1,
      'voice_uses': prefs.getInt('voice_uses') ?? 2,
      'level': prefs.getInt('current_level') ?? 3,
    };
    final badges = _allBadges.map((b) {
      final current = metrics[b['metric']] ?? 0;
      final threshold = b['threshold'] as int;
      return {...b, 'unlocked': current >= threshold, 'progress': (current / threshold).clamp(0.0, 1.0)};
    }).toList();
    if (mounted) setState(() { _badges = badges; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _badges.where((b) => b['unlocked'] == true).length;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1628),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white,
        title: const Text('Achievements', style: TextStyle(fontWeight: FontWeight.w800)), centerTitle: true),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : Column(children: [
              Padding(padding: const EdgeInsets.all(20), child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.amber.withValues(alpha: 0.15), Colors.orange.withValues(alpha: 0.08)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  Column(children: [
                    Text('$unlocked', style: const TextStyle(color: Colors.amberAccent, fontSize: 36, fontWeight: FontWeight.w900)),
                    Text('Unlocked', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))]),
                  Column(children: [
                    Text('${_badges.length}', style: const TextStyle(color: Colors.white54, fontSize: 36, fontWeight: FontWeight.w900)),
                    Text('Total', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12))]),
                ]))).animate().fadeIn(),
              Expanded(child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.85),
                itemCount: _badges.length,
                itemBuilder: (context, i) {
                  final b = _badges[i];
                  final ok = b['unlocked'] == true;
                  return ClipRRect(borderRadius: BorderRadius.circular(20), child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ok ? Colors.amber.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ok ? Colors.amber.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06))),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(ok ? (b['emoji'] ?? '🏅') : '🔒', style: TextStyle(fontSize: ok ? 40 : 32)),
                        const SizedBox(height: 10),
                        Text(b['title'] ?? '', style: TextStyle(color: ok ? Colors.amberAccent : Colors.white54, fontSize: 14, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(b['desc'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10), textAlign: TextAlign.center, maxLines: 2),
                        const SizedBox(height: 10),
                        if (!ok) ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                          value: (b['progress'] as double?) ?? 0.0, backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent), minHeight: 4))
                        else const Icon(Icons.check_circle_rounded, color: Colors.amberAccent, size: 20),
                      ])),
                  )).animate().fadeIn(delay: Duration(milliseconds: 50 * i));
                })),
            ]),
    );
  }
}
