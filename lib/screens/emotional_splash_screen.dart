import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:speechmate/screens/app_language_select.dart';
import 'package:speechmate/screens/languages.dart';

class EmotionalSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const EmotionalSplashScreen({super.key, required this.nextScreen});

  @override
  State<EmotionalSplashScreen> createState() => _EmotionalSplashScreenState();
}

class _EmotionalSplashScreenState extends State<EmotionalSplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  
  // SEQUENCING
  late Animation<double> _constellationOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  
  // PARTICLE SYSTEM
  final int particleCount = 65; // increased density
  final List<Particle> particles = [];
  final math.Random random = math.Random();
  Offset _touchPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    
    // Initialize Particles with Physics properties
    for (int i = 0; i < particleCount; i++) {
      particles.add(Particle(random));
    }

    _pulseController = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 4)
    )..repeat(reverse: true);

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    );

    // 1. Constellation Fade In (0 - 2s)
    _constellationOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    // 2. Logo Explosion (2s - 3s)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.5, curve: Curves.elasticOut)),
    );
     _logoRotate = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.6, curve: Curves.easeOutBack)),
    );

    // 3. 3D Text Reveal (3s - 5s)
    _textSlide = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.5, 0.7, curve: Curves.easeOutExpo)),
    );
    _textOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.55, 0.7, curve: Curves.easeIn),
    );

    _mainController.forward();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Haptic Feedback for impact
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => widget.nextScreen,
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              transitionDuration: const Duration(milliseconds: 1000),
            ),
          );
        });
      }
    });

    // Ambient loop for particles
    _pulseController.addListener(() {
      final size = MediaQuery.of(context).size;
      setState(() {
         for (var p in particles) {
           p.update(_touchPosition, size);
         }
      });
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _touchPosition = details.globalPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: (_) => _touchPosition = Offset.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // DEEP SPACE GRADIENT
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 1.5, // Expanded depth
                  colors: [  
                    Color(0xFF4A00E0), // Vibrant Violet
                    Color(0xFF8E2DE2), // Rich Purple 
                    Color(0xFF0F0C29), // Deep Space
                    Colors.black
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),

            // INTERACTIVE CONSTELLATION MESH
            AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _constellationOpacity.value,
                  child: CustomPaint(
                    painter: ConstellationPainter(
                      particles: particles, 
                      pulse: _pulseController.value,
                      touchPos: _touchPosition
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),

            // CENTER CONTENT
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       // 3D LOGO CONTAINER
                       Transform(
                         transform: Matrix4.identity()
                           ..setEntry(3, 2, 0.001) // Perspective
                           ..rotateX(0.1 * math.sin(_pulseController.value * math.pi))
                           ..rotateY(0.1 * math.cos(_pulseController.value * math.pi))
                           ..scale(_logoScale.value),
                         alignment: Alignment.center,
                         child: Transform.rotate(
                           angle: _logoRotate.value,
                           child: Container(
                             width: 140,
                             height: 140,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: const LinearGradient(
                                 begin: Alignment.topLeft,
                                 end: Alignment.bottomRight,
                                 colors: [Colors.cyanAccent, Colors.purpleAccent],
                               ),
                               boxShadow: [
                                 BoxShadow(
                                   color: Colors.cyanAccent.withOpacity(0.5),
                                   blurRadius: 60 * _logoScale.value,
                                   spreadRadius: 10,
                                 )
                               ]
                             ),
                             padding: const EdgeInsets.all(3),
                             child: Container(
                               decoration: const BoxDecoration(
                                 shape: BoxShape.circle,
                                 color: Colors.black,
                               ),
                               child: ClipOval(
                                 child: Image.asset(
                                   'assets/icons/logo_main.png', 
                                   fit: BoxFit.cover,
                                   errorBuilder: (c,o,s) => const Icon(Icons.mic, color: Colors.white, size: 60)
                                 ),
                               ),
                             ),
                           ),
                         ),
                       ),

                       const SizedBox(height: 50),

                       // 3D TEXT REVEAL
                       Transform.translate(
                         offset: Offset(0, _textSlide.value),
                         child: Opacity(
                            opacity: _textOpacity.value,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Colors.white, Color(0xFFB0C4DE)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter
                                  ).createShader(bounds),
                                  child: Text(
                                    "SPEECHMATE",
                                    style: TextStyle(
                                      fontFamily: 'Roboto', // Default but clean
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 8.0,
                                      height: 1.0,
                                      shadows: [
                                        Shadow(color: Colors.cyan.withOpacity(0.5), blurRadius: 30, offset: const Offset(0,10))
                                      ]
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // GLIMMERING SUBTITLE
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Text(
                                      "ANCESTRAL VOICES. FUTURE TECH.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.6 + (0.4 * _pulseController.value)),
                                        letterSpacing: 2.0,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                         ),
                       ),
                     ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🌌 TRIBAL PHYSICS ENGINE
// ---------------------------------------------------------------------------

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  String char;
  Color color;
  
  Particle(math.Random r)
     : x = r.nextDouble(),
       y = r.nextDouble(),
       vx = (r.nextDouble() - 0.5) * 0.0015,
       vy = (r.nextDouble() - 0.5) * 0.0015,
       radius = r.nextDouble() * 10 + 10, // Size for text
       char = _getRandomChar(r),
       color = Colors.white.withOpacity(0.3 + r.nextDouble() * 0.4);

  static String _getRandomChar(math.Random r) {
    // User Provided Tribal Scripts
    final List<String> nicobarese = ['A', 'Ā', 'B', 'D', 'K', 'L', 'M', 'N', 'O', 'Ò'];
    final List<String> greatAndamanese = ['a', 'e', 'i', 'o', 'u', 'ph', 'th', 'kh'];
    final List<String> onge = ['A', 'Ŋ', 'G', 'K', 'T', 'E', 'Y', 'W'];
    
    final all = [...nicobarese, ...greatAndamanese, ...onge];
    return all[r.nextInt(all.length)];
  }

  void update(Offset touchPos, Size size) {
    x += vx;
    y += vy;

    // Bounce off walls
    if (x < 0 || x > 1) vx *= -1;
    if (y < 0 || y > 1) vy *= -1;
    
    // Interactive Repulsion from Touch
    if (touchPos != Offset.zero) {
       // Normalize touch to 0-1
       double tx = touchPos.dx / size.width;
       double ty = touchPos.dy / size.height;
       
       double dx = x - tx;
       double dy = y - ty;
       double dist = math.sqrt(dx*dx + dy*dy);
       
       if (dist < 0.2) { // Repel if close
         vx += dx * 0.001;
         vy += dy * 0.001;
       }
    }
  }
}

class ConstellationPainter extends CustomPainter {
  final List<Particle> particles;
  final double pulse;
  final Offset touchPos;

  ConstellationPainter({required this.particles, required this.pulse, required this.touchPos});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < particles.length; i++) {
       final p1 = particles[i];
       final pos1 = Offset(p1.x * size.width, p1.y * size.height);

       // Draw Text Character
       final textSpan = TextSpan(
         text: p1.char,
         style: TextStyle(
           color: p1.color.withOpacity(0.5 + (0.3 * math.sin(pulse * math.pi))),
           fontSize: p1.radius,
           fontWeight: FontWeight.bold,
           shadows: [Shadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 4)]
         ),
       );
       final textPainter = TextPainter(
         text: textSpan,
         textDirection: TextDirection.ltr,
       );
       textPainter.layout();
       textPainter.paint(canvas, pos1 - Offset(textPainter.width / 2, textPainter.height / 2));

       // Connect to neighbors (Neural Mesh)
       for (int j = i + 1; j < particles.length; j++) {
         final p2 = particles[j];
         final pos2 = Offset(p2.x * size.width, p2.y * size.height);
         
         final dist = (pos1 - pos2).distance;
         
         if (dist < 90) { // Connection threshold
            final double opacity = (1.0 - (dist / 90)) * 0.4;
            paint.color = Colors.cyan.withOpacity(opacity);
            paint.strokeWidth = 1.0;
            canvas.drawLine(pos1, pos2, paint);
         }
       }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
