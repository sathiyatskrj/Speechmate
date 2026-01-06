import 'package:flutter/material.dart';
import 'dart:math';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool isPlaying;

  const ConfettiOverlay({
    Key? key,
    required this.child,
    required this.isPlaying,
  }) : super(key: key);

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Loop duration
    )..addListener(_updateParticles);
    
    // Start loop but only spawn when isPlaying is true
    _controller.repeat(); 
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _spawnExplosion();
    }
  }

  void _spawnExplosion() {
    for (int i = 0; i < 50; i++) {
      _particles.add(_ConfettiParticle(
        color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        x: 0.5, // Center
        y: 0.5,
        speedX: (_random.nextDouble() - 0.5) * 0.05,
        speedY: (_random.nextDouble() - 1.0) * 0.05 - 0.02, // Generally up
        size: _random.nextDouble() * 10 + 5,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
      ));
    }
  }

  void _updateParticles() {
    if (!widget.isPlaying && _particles.isEmpty) return;

    setState(() {
      for (var particle in _particles) {
        particle.x += particle.speedX;
        particle.y += particle.speedY;
        particle.speedY += 0.002; // Gravity
        particle.rotation += particle.rotationSpeed;
      }
      // Remove off-screen particles
      _particles.removeWhere((p) => p.y > 1.2);
    });
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
        if (widget.isPlaying || _particles.isNotEmpty)
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(_particles),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  Color color;
  double x, y;
  double speedX, speedY;
  double size;
  double rotation;
  double rotationSpeed;

  _ConfettiParticle({
    required this.color,
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    this.rotation = 0.0,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()..color = particle.color;
      
      canvas.save();
      canvas.translate(particle.x * size.width, particle.y * size.height);
      canvas.rotate(particle.rotation);
      
      // Draw a simple square/rect confetti
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.6),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
