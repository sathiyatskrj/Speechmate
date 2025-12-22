import 'package:flutter/material.dart';
import 'dart:math';
import 'word_match_game.dart';
import 'flash_card_game.dart';
import 'scramble_game.dart';

class GamesHubScreen extends StatefulWidget {
  const GamesHubScreen({super.key});

  @override
  State<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends State<GamesHubScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text("Learning Games", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Play & Learn!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose a game to start your adventure",
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 1, // Single column for big cards
                childAspectRatio: 2.2,
                mainAxisSpacing: 20,
                children: [
                  _buildGameCard(
                    context,
                    "Word Match",
                    "Connect English & Nicobarese",
                    Icons.schema_rounded,
                    [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
                    const WordMatchGame(),
                  ),
                  _buildGameCard(
                    context,
                    "Flash Cards",
                    "Master vocabulary quickly",
                    Icons.style,
                    [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)],
                    const FlashCardGame(),
                  ),
                  _buildGameCard(
                    context,
                    "Word Scramble",
                    "Unjumble the letters",
                    Icons.spellcheck,
                    [const Color(0xFF84fab0), const Color(0xFF8fd3f4)],
                    const ScrambleGame(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, String title, String subtitle, IconData icon, List<Color> colors, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(icon, size: 120, color: Colors.white.withOpacity(0.2)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
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
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
