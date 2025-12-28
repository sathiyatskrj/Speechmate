import 'package:flutter/material.dart';
import 'tap_scale.dart';

class LearningTiles extends StatelessWidget {
  final String word;
  final String? emoji;
  final List<Color> gradient;
  final Widget? navigateTo;
  final VoidCallback? onTap;

  const LearningTiles({
    super.key,
    required this.word,
    this.emoji,
    required this.gradient,
    this.navigateTo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap ?? () {
        if (navigateTo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => navigateTo!),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(4, 8),
            ),
            const BoxShadow(
              color: Colors.white24,
              blurRadius: 2,
              offset: Offset(-2, -2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle in background
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (emoji != null) ...[
                  Text(
                    emoji!,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                ],
                Center(
                  child: Text(
                    word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
