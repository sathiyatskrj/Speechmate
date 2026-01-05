import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// A premium, organic, voice-reactive background 
/// that simulates flowing aurora borealis lights.
class VoiceReactiveAurora extends StatefulWidget {
  final Widget child;
  final bool isDark; // True for Teacher, False for Student

  const VoiceReactiveAurora({
    super.key,
    required this.child,
    this.isDark = true,
  });

  @override
  State<VoiceReactiveAurora> createState() => _VoiceReactiveAuroraState();
}

class _VoiceReactiveAuroraState extends State<VoiceReactiveAurora> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 10),
    )..repeat();
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
        // The Base Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark ? AppColors.teacherGradient : AppColors.studentGradient,
            ),
          ),
        ),
        
        // The Aurora Mesh
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Optimize: Only repaint when necessary is handled by CustomPainter
            // We use RepaintBoundary to isolate the painting layer
            return RepaintBoundary(
              child: CustomPaint(
                painter: _AuroraPainter(
                  animationValue: _controller.value,
                  isDark: widget.isDark,
                ),
                child: Container(),
              ),
            );
          },
        ),

        // The Content
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _AuroraPainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    // Dynamic colors based on theme
    final Color baseColor = isDark ? Colors.cyanAccent : Colors.purpleAccent;
    final Color secondaryColor = isDark ? Colors.purpleAccent : Colors.pinkAccent;

    // Use derived noise from animation value to avoid separate state
    // intensity oscillates slowly between 0.3 and 0.7
    final double derivedIntensity = 0.3 + (0.4 * (0.5 + 0.5 * sin(animationValue * 2 * pi)));

    // We draw multiple flowing curves
    for (int i = 0; i < 3; i++) {
        _drawRibbon(canvas, size, paint, baseColor, i, 1.0, derivedIntensity);
        _drawRibbon(canvas, size, paint, secondaryColor, i, -1.0, derivedIntensity);
    }
  }

  void _drawRibbon(Canvas canvas, Size size, Paint paint, Color color, int index, double direction, double intensity) {
    paint.color = color.withOpacity(0.15 + (intensity * 0.1));
    
    final path = Path();
    final double waveHeight = size.height * 0.5;
    final double yOffset = size.height * 0.3 * index;
    
    // Complex sine wave math for organic movement
    final double t = (animationValue * 2 * pi) + (index * 1.5);
    
    path.moveTo(0, size.height);
    
    // OPTIMIZATION: Increased step from 20 to 40 to reduce Path operations by 50%
    for (double x = 0; x <= size.width; x += 40) {
       final double normalizedX = x / size.width;
       final double sine1 = sin(normalizedX * 4 * pi + t);
       final double sine2 = cos(normalizedX * 2 * pi - t * 0.5);
       
       final double y = (size.height / 2) + 
                        (sine1 * 50 * direction) + 
                        (sine2 * 30) + 
                        yOffset + 
                        (sin(t * 2) * 20 * intensity); 

       if (x == 0) path.moveTo(x, y);
       path.lineTo(x, y);
    }
    
    // Close the shape to bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
     return oldDelegate.animationValue != animationValue || 
            oldDelegate.isDark != isDark;
  }
}
