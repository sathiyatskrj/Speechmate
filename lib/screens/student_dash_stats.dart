import 'package:flutter/material.dart';
import 'package:speechmate/services/progress_service.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:speechmate/screens/student_dash_engines.dart';

// ============================================================================
// STATS WIDGETS — Extracted from student_dash.dart for maintainability
// ============================================================================

// ----------------------------------------------------------------------------
// 1. Daily Mission Card
// ----------------------------------------------------------------------------
/// A bright, animated mission card that gives students a fun daily learning goal.
class DailyMissionCard extends StatefulWidget {
  const DailyMissionCard({super.key});
  @override
  State<DailyMissionCard> createState() => _DailyMissionCardState();
}

class _DailyMissionCardState extends State<DailyMissionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  double _progress = 0.0;
  late Map<String, dynamic> _todaysMission;
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    _shimmer =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _todaysMission = SmartMissionEngine.getTodaysMission();
    _loadRealProgress();
  }

  Future<void> _loadRealProgress() async {
    final progressService = ProgressService();
    final stats = await progressService.getProgressStats();
    final wordsLearned = stats['wordsLearned'] ?? 0;
    final target = _todaysMission['target'] as int;
    if (mounted) {
      setState(() {
        _progress = (wordsLearned / target).clamp(0.0, 1.0);
        _loadingProgress = false;
      });
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int xpReward = _todaysMission['xp'];
    final String missionText = _todaysMission['text'];
    final int target = _todaysMission['target'];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(AppStrings.get('dailyMission'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _shimmer,
                  builder: (ctx, _) => Text(
                    '+$xpReward ⭐',
                    style: TextStyle(
                      color: Colors.white
                          .withValues(alpha: 0.7 + 0.3 * _shimmer.value),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              missionText,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.get('missionHint'),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 12,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(_progress * target).round()} / $target',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text('${(_progress * 100).round()}% ${AppStrings.get('percentDone')}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 2. Quick Stats Row (Streak 🔥, Stars ⭐, Level 🏅)
// ----------------------------------------------------------------------------
/// Three colourful bubble-cards showing a student's key stats at a glance.
class QuickStatsRow extends StatefulWidget {
  const QuickStatsRow({super.key});

  @override
  State<QuickStatsRow> createState() => _QuickStatsRowState();
}

class _QuickStatsRowState extends State<QuickStatsRow> {
  int _streak = 0;
  int _stars = 0;
  String _levelName = 'Seedling';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final progressService = ProgressService();
    final stats = await progressService.getProgressStats();
    final xpInfo = StudentXPEngine.getLevelInfo(stats['studentXP'] ?? 0);

    if (mounted) {
      setState(() {
        _streak = stats['dayStreak'] ?? 0;
        _stars = stats['studentStars'] ?? 0;
        _levelName = xpInfo['name'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
          height: 80,
          child: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent)));
    }

    return Row(
      children: [
        _buildStatBubble(
            emoji: '🔥',
            label: AppStrings.get('streakLabel'),
            value: '$_streak ${AppStrings.get('days')}',
            color: const Color(0xFFFF6B35)),
        const SizedBox(width: 12),
        _buildStatBubble(
            emoji: '⭐',
            label: AppStrings.get('starsLabel'),
            value: '$_stars',
            color: const Color(0xFFFFD700)),
        const SizedBox(width: 12),
        _buildStatBubble(
            emoji: '🏅',
            label: AppStrings.get('levelLabel'),
            value: _levelName,
            color: const Color(0xFF7B61FF)),
      ],
    );
  }

  Widget _buildStatBubble(
      {required String emoji,
      required String label,
      required String value,
      required Color color}) {
    // NO BackdropFilter here — 3 stacked blurs destroy mobile perf
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
