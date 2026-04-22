import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import 'package:speechmate/widgets/gamification_header.dart';
import 'package:speechmate/features/gamification/gamification_service.dart';
import 'word_match_game.dart';
import 'flash_card_game.dart';
import 'scramble_game.dart';
import 'word_runner_game.dart'; // [NEW] Added Import
import 'dart:ui';

class GamesHubScreen extends StatefulWidget {
  const GamesHubScreen({super.key});

  @override
  State<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends State<GamesHubScreen> {
  final List<Map<String, dynamic>> _games = [
    {
      "title": "Word Match",
      "subtitle": "Connect English & Nicobarese",
      "icon": Icons.schema_rounded,
      "colors": [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
      "page": const WordMatchGame(),
    },
    {
      "title": "Flash Cards",
      "subtitle": "Master vocabulary quickly",
      "icon": Icons.style,
      "colors": [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)],
      "page": const FlashCardGame(),
    },
    {
      "title": "Word Scramble",
      "subtitle": "Unjumble the letters",
      "icon": Icons.spellcheck,
      "colors": [const Color(0xFF84fab0), const Color(0xFF8fd3f4)],
      "page": const ScrambleGame(),
    },
    {
      "title": "Word Runner",
      "subtitle": "Run, Jump & Collect Words!",
      "icon": Icons.directions_run,
      "colors": [const Color(0xFFff9966), const Color(0xFFff5e62)],
      "page": const WordRunnerGame(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _refreshGamification();
  }

  Future<void> _refreshGamification() async {
    await GamificationService.refresh();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Learning Games", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF6A11CB).withValues(alpha: 0.8), const Color(0xFF2575FC).withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GamificationHeader().animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
              const SizedBox(height: 20),
              const Text(
                "Play & Learn! 🎮",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ).animate().fadeIn().slideX(begin: -0.1),
              const SizedBox(height: 8),
              const Text(
                "Choose a game to start your adventure.",
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ).animate().fadeIn().slideX(begin: -0.1, delay: 100.ms),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _games.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final game = _games[index];
                    return _buildGameCard(
                      context,
                      index,
                      game['title'],
                      game['subtitle'],
                      game['icon'],
                      game['colors'],
                      game['page'],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, int index, String title, String subtitle, IconData icon, List<Color> colors, Widget page) {
    return TapScale(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        // Refresh gamification when returning from a game to show new XP
        _refreshGamification();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.first.withValues(alpha: 0.9), colors.last.withValues(alpha: 0.7)], 
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Icon(icon, size: 140, color: Colors.white.withValues(alpha: 0.15)),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25), 
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5))
                      ),
                      child: Icon(icon, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 150).ms, duration: 400.ms).slideY(begin: 0.2, curve: Curves.easeOutBack);
  }
}

// --- HIDDEN SURPRISE UTILITY ---
class CelebrationOverlay extends StatefulWidget {
  final Widget child;
  const CelebrationOverlay({super.key, required this.child});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    // Create particles
    for (int i = 0; i < 50; i++) {
      _particles.add(ConfettiParticle());
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: _particles.map((p) => p.build(_controller.value)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double xStart;
  final double speed;
  final double angle;

  ConfettiParticle()
      : color = Colors.primaries[Random().nextInt(Colors.primaries.length)],
        xStart = Random().nextDouble() * 400, // random width
        speed = 400 + Random().nextDouble() * 400,
        angle = (Random().nextDouble() - 0.5) * 2;

  Widget build(double t) {
    double y = speed * t;
    double x = xStart + sin(t * 10) * 20 * angle;
    
    // Only show if on screen
    if (y > 800) return const SizedBox(); 

    return Positioned(
      top: y - 50, // start slightly above
      left: x,
      child: Transform.rotate(
        angle: t * 10 * angle,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
