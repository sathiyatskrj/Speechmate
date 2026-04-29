import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speechmate/services/database_manager.dart';

class EmotionalSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const EmotionalSplashScreen({super.key, required this.nextScreen});

  @override
  State<EmotionalSplashScreen> createState() => _EmotionalSplashScreenState();
}

class _EmotionalSplashScreenState extends State<EmotionalSplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _taglineController;
  
  // SEQUENCING
  late Animation<double> _constellationOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _skipOpacity;
  late Animation<double> _versionOpacity;
  
  // PARTICLE SYSTEM
  final int particleCount = 75;
  final List<_SplashParticle> particles = [];
  final math.Random random = math.Random();
  Offset _touchPosition = Offset.zero;

  // AMBIENT AUDIO
  final AudioPlayer _ambientPlayer = AudioPlayer();

  // PRELOAD PROGRESS
  double _loadProgress = 0.0;
  bool _isPreloading = true;

  // TAGLINE ROTATION
  int _currentTagline = 0;
  static const List<String> _taglines = [
    "WHERE LANGUAGE BARRIERS END.",
    "PRESERVING VOICES OF THE ISLANDS.",
    "ONE WORD AT A TIME.",
    "BRIDGING CULTURES THROUGH WORDS.",
  ];

  // TIME-AWARE GREETING
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Good Night';
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Color get _greetingGradientStart {
    final hour = DateTime.now().hour;
    if (hour < 5) return const Color(0xFF0F0C29);
    if (hour < 12) return const Color(0xFFFF6B35);
    if (hour < 17) return Colors.cyan;
    return const Color(0xFF8E2DE2);
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize Particles with mixed types
    for (int i = 0; i < particleCount; i++) {
      particles.add(_SplashParticle(random));
    }

    _pulseController = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 4)
    )..repeat(reverse: true);

    _taglineController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 3),
    )..repeat();

    _taglineController.addListener(() {
      if (_taglineController.value > 0.99) {
        setState(() {
          _currentTagline = (_currentTagline + 1) % _taglines.length;
        });
      }
    });

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

    // 4. Skip button appears (after 2s / 30%)
    _skipOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.4, curve: Curves.easeIn),
    );

    // 5. Version appears at the end
    _versionOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 0.85, curve: Curves.easeIn),
    );

    _mainController.forward();

    _mainController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        _navigateNext();
      }
    });

    // Ambient loop for particles
    _pulseController.addListener(() {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      setState(() {
         for (var p in particles) {
           p.update(_touchPosition, size);
         }
      });
    });

    // Start ambient audio & preloading
    _playAmbientAudio();
    _preloadData();
  }

  Future<void> _playAmbientAudio() async {
    try {
      await _ambientPlayer.setVolume(0.0);
      await _ambientPlayer.play(AssetSource('audio/ambient.mp3'));
      // Fade in volume
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        await _ambientPlayer.setVolume(i * 0.04); // Max 0.4 volume
      }
    } catch (e) {
      debugPrint('[Splash] Ambient audio error: $e');
    }
  }

  Future<void> _fadeOutAudio() async {
    try {
      for (int i = 8; i >= 0; i--) {
        await Future.delayed(const Duration(milliseconds: 50));
        await _ambientPlayer.setVolume(i * 0.04);
      }
      await _ambientPlayer.stop();
    } catch (e) {
      debugPrint('[Splash] Audio fade error: $e');
    }
  }

  Future<void> _preloadData() async {
    try {
      // Preload database during splash
      setState(() => _loadProgress = 0.1);
      await DatabaseManager.instance.database;
      if (!mounted) return;
      setState(() => _loadProgress = 0.4);

      // Seed main dictionary
      await DatabaseManager.instance.seedCategoryFromJson('main', 'assets/data/dictionary.json');
      if (!mounted) return;
      setState(() => _loadProgress = 0.7);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_splash', true);
      if (!mounted) return;
      setState(() {
        _loadProgress = 1.0;
        _isPreloading = false;
      });
    } catch (e) {
      debugPrint('[Splash] Preload error: $e');
      if (mounted) setState(() => _isPreloading = false);
    }
  }

  void _navigateNext() async {
    await _fadeOutAudio();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _skipSplash() {
    HapticFeedback.lightImpact();
    _mainController.stop();
    _navigateNext();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _taglineController.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _touchPosition = details.globalPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: (_) => _touchPosition = Offset.zero,
        onTap: () {
          // Allow tap to skip after logo appears
          if (_mainController.value > 0.3) _skipSplash();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // DEEP SPACE GRADIENT — TIME AWARE
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 1.5,
                  colors: [  
                    _greetingGradientStart,
                    const Color(0xFF8E2DE2),
                    const Color(0xFF0F0C29),
                    Colors.black
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
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
                    painter: _ConstellationPainter(
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
                       // TIME-AWARE GREETING (fades in before logo)
                       Opacity(
                         opacity: _constellationOpacity.value,
                         child: Text(
                           _greeting,
                           style: TextStyle(
                             fontSize: 16,
                             fontWeight: FontWeight.w400,
                             color: Colors.white.withValues(alpha: 0.6),
                             letterSpacing: 4.0,
                           ),
                         ),
                       ),

                       const SizedBox(height: 30),

                       // 3D LOGO CONTAINER
                       Transform(
                         transform: Matrix4.identity()
                           ..setEntry(3, 2, 0.001) // Perspective
                           ..rotateX(0.1 * math.sin(_pulseController.value * math.pi))
                           ..rotateY(0.1 * math.cos(_pulseController.value * math.pi))
                           // ignore: deprecated_member_use
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
                                   color: Colors.cyanAccent.withValues(alpha: 0.5),
                                   blurRadius: 60 * _logoScale.value,
                                   spreadRadius: 10,
                                 ),
                                 BoxShadow(
                                   color: Colors.purpleAccent.withValues(alpha: 0.3),
                                   blurRadius: 40 * _logoScale.value,
                                   spreadRadius: 5,
                                 ),
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
                                      fontFamily: 'Roboto',
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 8.0,
                                      height: 1.0,
                                      shadows: [
                                        Shadow(color: Colors.cyan.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0,10))
                                      ]
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // ROTATING TAGLINE
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 600),
                                      child: Text(
                                        _taglines[_currentTagline],
                                        key: ValueKey(_currentTagline),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(alpha: 0.5 + (0.4 * _pulseController.value)),
                                          letterSpacing: 2.0,
                                        ),
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

            // PRELOAD PROGRESS BAR
            if (_isPreloading)
              Positioned(
                bottom: 80,
                left: 40, right: 40,
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (_, __) => Opacity(
                    opacity: _constellationOpacity.value,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _loadProgress,
                            minHeight: 2,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(
                              Colors.cyanAccent.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loading dictionary...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // TAP TO SKIP
            Positioned(
              bottom: 120,
              left: 0, right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (_, __) => Opacity(
                  opacity: _skipOpacity.value * 0.6,
                  child: const Center(
                    child: Text(
                      'TAP TO CONTINUE',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // VERSION BADGE
            Positioned(
              bottom: 30,
              left: 0, right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (_, __) => Opacity(
                  opacity: _versionOpacity.value,
                  child: const Center(
                    child: Text(
                      'v1.4.8',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🌌 TRIBAL PHYSICS ENGINE — UPGRADED WITH GLOWING DOTS
// ---------------------------------------------------------------------------

class _SplashParticle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  String? char; // null = glowing dot, non-null = tribal character
  Color color;
  double glowRadius;
  
  _SplashParticle(math.Random r)
     : x = r.nextDouble(),
       y = r.nextDouble(),
       vx = (r.nextDouble() - 0.5) * 0.0015,
       vy = (r.nextDouble() - 0.5) * 0.0015,
       radius = r.nextDouble() * 10 + 8,
       char = r.nextDouble() > 0.4 ? _getRandomChar(r) : null, // 40% dots, 60% chars
       color = Colors.white.withValues(alpha: 0.3 + r.nextDouble() * 0.4),
       glowRadius = r.nextDouble() * 6 + 2;

  static String _getRandomChar(math.Random r) {
    // Tribal Scripts
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
       double tx = touchPos.dx / size.width;
       double ty = touchPos.dy / size.height;
       
       double dx = x - tx;
       double dy = y - ty;
       double dist = math.sqrt(dx*dx + dy*dy);
       
       if (dist < 0.2) {
         vx += dx * 0.001;
         vy += dy * 0.001;
       }
    }
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<_SplashParticle> particles;
  final double pulse;
  final Offset touchPos;

  _ConstellationPainter({required this.particles, required this.pulse, required this.touchPos});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < particles.length; i++) {
       final p1 = particles[i];
       final pos1 = Offset(p1.x * size.width, p1.y * size.height);

       if (p1.char != null) {
         // Draw Tribal Character
         final textSpan = TextSpan(
           text: p1.char,
           style: TextStyle(
             color: p1.color.withValues(alpha: 0.5 + (0.3 * math.sin(pulse * math.pi))),
             fontSize: p1.radius,
             fontWeight: FontWeight.bold,
             shadows: [Shadow(color: Colors.cyanAccent.withValues(alpha: 0.5), blurRadius: 4)]
           ),
         );
         final textPainter = TextPainter(
           text: textSpan,
           textDirection: TextDirection.ltr,
         );
         textPainter.layout();
         textPainter.paint(canvas, pos1 - Offset(textPainter.width / 2, textPainter.height / 2));
       } else {
         // Draw Glowing Dot
         final glowAlpha = 0.3 + (0.4 * math.sin(pulse * math.pi + i.toDouble()));
         
         // Outer glow
         paint.color = Colors.cyanAccent.withValues(alpha: glowAlpha * 0.3);
         canvas.drawCircle(pos1, p1.glowRadius * 3, paint);
         
         // Inner glow
         paint.color = Colors.cyanAccent.withValues(alpha: glowAlpha * 0.6);
         canvas.drawCircle(pos1, p1.glowRadius * 1.5, paint);
         
         // Core dot
         paint.color = Colors.white.withValues(alpha: glowAlpha);
         canvas.drawCircle(pos1, p1.glowRadius * 0.5, paint);
       }

       // Connect to neighbors (Neural Mesh)
       for (int j = i + 1; j < particles.length; j++) {
         final p2 = particles[j];
         final pos2 = Offset(p2.x * size.width, p2.y * size.height);
         
         final dist = (pos1 - pos2).distance;
         
         if (dist < 100) { // Slightly increased connection threshold
            final double opacity = (1.0 - (dist / 100)) * 0.35;
            paint.color = Colors.cyan.withValues(alpha: opacity);
            paint.strokeWidth = 1.0;
            canvas.drawLine(pos1, pos2, paint);
         }
       }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
