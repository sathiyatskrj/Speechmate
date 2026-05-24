import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speechmate/core/app_strings.dart';

// ============================================================================
// COMPETITION-GRADE ADVANCED UI COMPONENTS
// Extracted from student_dash.dart for maintainability
// ============================================================================

// ----------------------------------------------------------------------------
// 1. Ambient Animated Glass Background (Custom Painted Canvas)
// ----------------------------------------------------------------------------
/// Renders a dynamic, heavily optimized animated blob gradient background.
/// Uses multiple overlapping radial gradients painted on a custom canvas
/// to avoid widget tree bloat and maintain 60FPS scrolling performance.
class AmbientGlassBackground extends StatefulWidget {
  const AmbientGlassBackground({super.key});

  @override
  State<AmbientGlassBackground> createState() => _AmbientGlassBackgroundState();
}

class _AmbientGlassBackgroundState extends State<AmbientGlassBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _AmbientPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double progress;
  _AmbientPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    final Rect rect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // FAST HARDWARE ACCELERATED GRADIENTS (FIXES HANGING ON PHONES)
    // Replaced MaskFilter.blur which kills mobile performance with RadialGradients.
    void drawFastGlowingOrb(double x, double y, double radius, Color color) {
      final rect = Rect.fromCircle(center: Offset(x, y), radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.0)],
          stops: const [0.1, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    }

    final double x1 =
        size.width * 0.5 + math.sin(progress * math.pi * 2) * size.width * 0.4;
    final double y1 = size.height * 0.3 +
        math.cos(progress * math.pi * 2) * size.height * 0.2;
    drawFastGlowingOrb(x1, y1, 300, Colors.cyanAccent);

    final double x2 = size.width * 0.2 +
        math.cos(progress * math.pi * 2 + math.pi) * size.width * 0.3;
    final double y2 = size.height * 0.8 +
        math.sin(progress * math.pi * 2 + math.pi) * size.height * 0.3;
    drawFastGlowingOrb(x2, y2, 350, Colors.pinkAccent);

    final double x3 = size.width * 0.8 +
        math.sin(progress * math.pi * 2 + math.pi / 2) * size.width * 0.3;
    final double y3 = size.height * 0.5 +
        math.cos(progress * math.pi * 2 + math.pi / 2) * size.height * 0.4;
    drawFastGlowingOrb(x3, y3, 280, Colors.purpleAccent);
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => oldDelegate.progress != progress;
}

// ----------------------------------------------------------------------------
// 2. Interactive 3D Tilt Card wrapper (Gyroscope-like Interaction)
// ----------------------------------------------------------------------------
/// Captures pan gestures on a child widget and applies a 3D matrix transformation
/// to simulate depth, shadow shifting, and tactile responsiveness.
class PremiumTiltCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const PremiumTiltCard({super.key, required this.child, required this.onTap});

  @override
  State<PremiumTiltCard> createState() => _PremiumTiltCardState();
}

class _PremiumTiltCardState extends State<PremiumTiltCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);
    final double percentX = (localPos.dx / size.width) - 0.5;
    final double percentY = (localPos.dy / size.height) - 0.5;
    setState(() {
      _tiltX = percentY * 0.3; // Constrained pitch rotation
      _tiltY = -percentX * 0.3; // Constrained yaw rotation
    });
  }

  void _reset() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _reset();
          widget.onTap();
        },
        onTapCancel: _reset,
        onPanUpdate: (details) => _onPanUpdate(details, size),
        onPanEnd: (_) => _reset(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = 1.0 - (_controller.value * 0.05);
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateX(_tiltX)
                ..rotateY(_tiltY)
                ..scale(scale, scale, scale),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: widget.child,
        ),
      );
    });
  }
}

// ----------------------------------------------------------------------------
// 3. Daily Discovery Glass Card
// ----------------------------------------------------------------------------
/// Prominently displays the "Word of the Day" with rich typography and
/// glassmorphic background to encourage daily engagement.
class DailyDiscoveryCard extends StatelessWidget {
  const DailyDiscoveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.6),
                  Colors.white.withValues(alpha: 0.2)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("WORD OF THE DAY",
                        style: TextStyle(
                            color: Colors.purple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                  ),
                  const Spacer(),
                  const Icon(Icons.volume_up_rounded,
                      color: Colors.purpleAccent),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Pōt",
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.0)),
              const Text("Nicobarese",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.black12),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.translate_rounded,
                      size: 16, color: Colors.black54),
                  SizedBox(width: 8),
                  Text("Meaning:",
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  Text("Ocean / Sea",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 4. Progress Radar Chart Widget (Animated Custom Canvas)
// ----------------------------------------------------------------------------
/// Renders a complex spider/radar chart displaying the student's fluency
/// across multiple linguistic domains. Built purely via the Canvas API.
class ProgressRadarChartWidget extends StatefulWidget {
  const ProgressRadarChartWidget({super.key});

  @override
  State<ProgressRadarChartWidget> createState() =>
      _ProgressRadarChartWidgetState();
}

class _ProgressRadarChartWidgetState extends State<ProgressRadarChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Dummy data for competition showcase presentation
  final List<double> values = [0.85, 0.60, 0.95, 0.45, 0.75];
  final List<String> labels = [
    "Nature",
    "Family",
    "Numbers",
    "Colors",
    "Animals"
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)
          ]),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarChartPainter(
              values: values,
              labels: labels,
              progress:
                  CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
                      .value,
            ),
          );
        },
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double progress;

  _RadarChartPainter(
      {required this.values, required this.labels, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.8;
    final int sides = values.length;
    final double angle = (2 * math.pi) / sides;

    // Draw Polygonal Webs (Background rings)
    final webPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int step = 1; step <= 4; step++) {
      final double r = radius * (step / 4);
      final Path webPath = Path();
      for (int i = 0; i < sides; i++) {
        final double x = center.dx + r * math.cos(i * angle - math.pi / 2);
        final double y = center.dy + r * math.sin(i * angle - math.pi / 2);
        if (i == 0) {
          webPath.moveTo(x, y);
        } else {
          webPath.lineTo(x, y);
        }
      }
      webPath.close();
      canvas.drawPath(webPath, webPaint);
    }

    // Draw Radial Spokes and Labels
    for (int i = 0; i < sides; i++) {
      final double x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final double y = center.dy + radius * math.sin(i * angle - math.pi / 2);
      canvas.drawLine(center, Offset(x, y), webPaint);

      final labelSpan = TextSpan(
          text: labels[i],
          style: const TextStyle(
              color: Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.bold));
      final tp = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)
        ..layout();

      // Calculate label offsets outside the web
      final double lx = center.dx +
          (radius + 20) * math.cos(i * angle - math.pi / 2) -
          tp.width / 2;
      final double ly = center.dy +
          (radius + 20) * math.sin(i * angle - math.pi / 2) -
          tp.height / 2;
      tp.paint(canvas, Offset(lx, ly));
    }

    // Draw Data Polygon Mask (Animated)
    final Path dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final double r = radius * values[i] * progress;
      final double x = center.dx + r * math.cos(i * angle - math.pi / 2);
      final double y = center.dy + r * math.sin(i * angle - math.pi / 2);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Fill with translucent cyan
    final dataPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, dataPaint);

    // Outline path
    final dataBorderPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, dataBorderPaint);

    // Draw Data Points on top
    for (int i = 0; i < sides; i++) {
      final double r = radius * values[i] * progress;
      final double x = center.dx + r * math.cos(i * angle - math.pi / 2);
      final double y = center.dy + r * math.sin(i * angle - math.pi / 2);

      final pointPaint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      final pointBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), 4, pointBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ----------------------------------------------------------------------------
// 5. Achievement Showcase Ribbon List
// ----------------------------------------------------------------------------
/// Renders a horizontal scrolling list of dynamically painted achievement medals.
class AchievementShowcaseWidget extends StatelessWidget {
  const AchievementShowcaseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {
        'title': 'First Word',
        'color': Colors.orangeAccent,
        'icon': Icons.star_rounded
      },
      {
        'title': 'Explorer',
        'color': Colors.cyanAccent,
        'icon': Icons.explore_rounded
      },
      {
        'title': '7 Day Streak',
        'color': Colors.pinkAccent,
        'icon': Icons.local_fire_department_rounded
      },
      {
        'title': 'Grammar Pro',
        'color': Colors.greenAccent,
        'icon': Icons.spellcheck_rounded
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            AppStrings.get('achievements') != 'achievements'
                ? AppStrings.get('achievements').toUpperCase()
                : "ACHIEVEMENTS",
            style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.5),
                          border: Border.all(
                              color:
                                  (a['color'] as Color).withValues(alpha: 0.8),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: (a['color'] as Color)
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]),
                      child: Icon(a['icon'] as IconData,
                          color: a['color'] as Color, size: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(a['title'] as String,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        textAlign: TextAlign.center,
                        maxLines: 2),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// 6. Kids Section Header
// ----------------------------------------------------------------------------
/// A fun, colourful section label with a big emoji for easy reading.
class KidsSectionHeader extends StatelessWidget {
  final String emoji;
  final String label;
  const KidsSectionHeader(
      {super.key, required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Colors.black12, Colors.transparent]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// 7. Voice Waveform Visualizer (Lightweight Canvas)
// ----------------------------------------------------------------------------
/// A smooth, animated audio waveform that can respond to mock amplitude data.
/// Uses a single CustomPainter with only ~20 bars — no FFT, no heavy math.
class VoiceWaveformWidget extends StatefulWidget {
  const VoiceWaveformWidget({super.key});

  @override
  State<VoiceWaveformWidget> createState() => _VoiceWaveformWidgetState();
}

class _VoiceWaveformWidgetState extends State<VoiceWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _WaveformPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double t;
  _WaveformPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const int barCount = 20;
    final double barWidth = size.width / (barCount * 2);
    final double maxHeight = size.height * 0.8;
    final double centerY = size.height / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      // Smooth sine-wave animation: each bar has a phase offset
      final double phase = i * 0.3 + t * math.pi * 2;
      final double amplitude = (math.sin(phase) * 0.5 + 0.5) * maxHeight * 0.5;
      final double x = (i * 2 + 0.5) * barWidth;

      // Gradient colour from cyan to purple based on position
      final double ratio = i / barCount;
      paint.color = Color.lerp(
        const Color(0xFF00BCD4), // Cyan
        const Color(0xFF9C27B0), // Purple
        ratio,
      )!
          .withValues(alpha: 0.7);

      // Draw symmetric bar from center
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(x, centerY),
            width: barWidth * 0.8,
            height: amplitude + 4),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) => old.t != t;
}
