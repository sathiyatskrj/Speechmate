import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speechmate/core/app_strings.dart';

// ============================================================================
// ENGINES — Extracted from student_dash.dart for maintainability
// ============================================================================

// ============================================================================
// ENGINE 1: Student XP & Leveling Engine
// ============================================================================
/// Lightweight progression engine that calculates XP, levels, and streaks.
/// All computation is O(1) — no loops, no heavy allocations.
class StudentXPEngine {
  // XP thresholds for each level (exponential curve)
  static const List<int> _levelThresholds = [
    0,
    50,
    150,
    350,
    700,
    1200,
    2000,
    3200,
    5000,
    8000,
    12000
  ];

  static const List<String> _levelNames = [
    'Seedling',
    'Sprout',
    'Explorer',
    'Adventurer',
    'Pathfinder',
    'Discoverer',
    'Scholar',
    'Champion',
    'Master',
    'Legend',
    'Elder'
  ];

  static const List<String> _levelEmojis = [
    '🌱',
    '🌿',
    '🧭',
    '⚔️',
    '🗺️',
    '🔭',
    '📚',
    '🏆',
    '👑',
    '⭐',
    '🌟'
  ];

  /// Gets the current level info from total XP (O(1) binary-search style)
  static Map<String, dynamic> getLevelInfo(int totalXP) {
    int level = 0;
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (totalXP >= _levelThresholds[i]) {
        level = i;
        break;
      }
    }

    final int currentThreshold = _levelThresholds[level];
    final int nextThreshold = level < _levelThresholds.length - 1
        ? _levelThresholds[level + 1]
        : _levelThresholds[level] + 5000;

    final double progressToNext =
        (totalXP - currentThreshold) / (nextThreshold - currentThreshold);

    return {
      'level': level,
      'name': _levelNames[level.clamp(0, _levelNames.length - 1)],
      'emoji': _levelEmojis[level.clamp(0, _levelEmojis.length - 1)],
      'totalXP': totalXP,
      'xpForNext': nextThreshold - totalXP,
      'progress': progressToNext.clamp(0.0, 1.0),
    };
  }

  /// Calculates XP reward for an action with streak multiplier
  static int calculateReward({
    required String action,
    int streakDays = 0,
  }) {
    // Base XP values per action type
    int baseXP;
    switch (action) {
      case 'translate_word':
        baseXP = 10;
        break;
      case 'ar_scan':
        baseXP = 25;
        break;
      case 'voice_record':
        baseXP = 30;
        break;
      case 'complete_game':
        baseXP = 50;
        break;
      case 'daily_mission':
        baseXP = 100;
        break;
      default:
        baseXP = 5;
    }

    // Streak multiplier: +5% per day, capped at 2x
    final double streakMultiplier = 1.0 + (streakDays * 0.05).clamp(0.0, 1.0);
    return (baseXP * streakMultiplier).round();
  }
}

// ============================================================================
// ENGINE 2: Lightweight Confetti Celebration Engine
// ============================================================================
/// A performance-safe confetti particle system using a single CustomPainter.
/// Max 25 particles, no blur, no shadows — pure rect/circle drawing.
class ConfettiOverlay extends StatefulWidget {
  final bool trigger;
  const ConfettiOverlay({super.key, required this.trigger});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_ConfettiParticle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _particles.clear();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger) {
      _spawnParticles();
    }
  }

  void _spawnParticles() {
    _particles = List.generate(
        25,
        (_) => _ConfettiParticle(
              x: _rng.nextDouble(),
              y: -0.1 - _rng.nextDouble() * 0.3,
              vx: (_rng.nextDouble() - 0.5) * 0.3,
              vy: 0.3 + _rng.nextDouble() * 0.5,
              rotation: _rng.nextDouble() * math.pi * 2,
              rotationSpeed: (_rng.nextDouble() - 0.5) * 6,
              size: 6 + _rng.nextDouble() * 8,
              color: [
                const Color(0xFFFF6B6B),
                const Color(0xFFFFD93D),
                const Color(0xFF6BCB77),
                const Color(0xFF4D96FF),
                const Color(0xFFFF6BFF),
                const Color(0xFFFF9A3C),
              ][_rng.nextInt(6)],
            ));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_particles.isEmpty) return const SizedBox.shrink();
          return RepaintBoundary(
            child: CustomPaint(
              painter: _ConfettiPainter(_particles, _controller.value),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  double x, y, vx, vy, rotation, rotationSpeed, size;
  Color color;
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final double fade = t > 0.7 ? (1.0 - t) / 0.3 : 1.0; // Fade out in last 30%

    for (final p in particles) {
      final double px = (p.x + p.vx * t) * size.width;
      final double py = (p.y + p.vy * t + 0.5 * t * t) * size.height; // Gravity
      final double rot = p.rotation + p.rotationSpeed * t;

      paint.color = p.color.withValues(alpha: fade * 0.9);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

// ============================================================================
// ENGINE 3: Smart Daily Mission Engine (Lightweight SRS)
// ============================================================================
/// Generates personalized daily missions based on what the child hasn't
/// practiced recently. Uses a simple staleness score — no heavy computation.
class SmartMissionEngine {
  /// Mission text keys for localization
  static const List<String> _missionTextKeys = [
    'missionLearnWords',
    'missionPlayGames',
    'missionScanAR',
    'missionRecordVoice',
    'missionBodyQuiz',
    'missionAnimals',
    'missionNature',
    'missionNumbers',
    'missionStories',
    'missionColors',
  ];

  /// Pre-defined mission templates (targets and XP)
  static const List<Map<String, dynamic>> _missionTemplates = [
    {'target': 5, 'xp': 50, 'category': 'vocabulary', 'emoji': '📖'},
    {'target': 2, 'xp': 40, 'category': 'games', 'emoji': '🎮'},
    {'target': 3, 'xp': 60, 'category': 'ar', 'emoji': '📷'},
    {'target': 3, 'xp': 45, 'category': 'voice', 'emoji': '🎤'},
    {'target': 1, 'xp': 35, 'category': 'quiz', 'emoji': '🦴'},
    {'target': 4, 'xp': 40, 'category': 'animals', 'emoji': '🐾'},
    {'target': 3, 'xp': 35, 'category': 'nature', 'emoji': '🌿'},
    {'target': 5, 'xp': 30, 'category': 'numbers', 'emoji': '🔢'},
    {'target': 1, 'xp': 55, 'category': 'stories', 'emoji': '📻'},
    {'target': 4, 'xp': 35, 'category': 'colors', 'emoji': '🎨'},
  ];

  /// Picks today's mission deterministically from the day-of-year.
  /// Same mission all day, different tomorrow. No storage needed.
  static Map<String, dynamic> getTodaysMission() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _missionTemplates.length;
    final template = Map<String, dynamic>.from(_missionTemplates[index]);
    // Resolve localized text at runtime
    template['text'] = AppStrings.get(_missionTextKeys[index]);
    return template;
  }

  /// Calculates a staleness score for each category based on
  /// simulated last-practice timestamps. Higher = needs more practice.
  static Map<String, double> getCategoryStaleness() {
    // In production, these would come from local storage.
    // For demo, we simulate varied staleness.
    final now = DateTime.now();
    final rng = math.Random(now.day);
    final categories = [
      'vocabulary',
      'games',
      'ar',
      'voice',
      'quiz',
      'animals',
      'nature',
      'numbers',
      'stories',
      'colors'
    ];
    return Map.fromEntries(
        categories.map((c) => MapEntry(c, rng.nextDouble())));
  }
}
