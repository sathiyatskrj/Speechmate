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
  final int particleCount = 35; // Reduced from 75 to fix hanging and lag
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
    
  ];

  // TIME-AWARE GREETING
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, Explorer!';
    if (hour < 17) return 'Good Afternoon, Adventurer!';
    return 'Good Evening, Superstar!';
  }

  Color get _greetingGradientStart {
    final hour = DateTime.now().hour;
    if (hour < 5) return const Color(0xFF2C3E50);
    if (hour < 12) return const Color(0xFFFFB75E);
    if (hour < 17) return const Color(0xFF00C9FF);
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
      duration: const Duration(milliseconds: 4000), // Sped up from 6500 to fix slow splash
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
      await _ambientPlayer.seek(const Duration(seconds: 2)); // Start music from 2 sec
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
            // FUN PLAYFUL GRADIENT — TIME AWARE
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [  
                    _greetingGradientStart,
                    const Color(0xFF4FACFE),
                    const Color(0xFF00F2FE),
                  ],
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
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                           decoration: BoxDecoration(
                             color: Colors.white.withValues(alpha: 0.3),
                             borderRadius: BorderRadius.circular(30),
                             border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2)
                           ),
                           child: Text(
                             _greeting,
                             style: const TextStyle(
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                               color: Colors.white,
                               letterSpacing: 1.5,
                             ),
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
                             width: 150,
                             height: 150,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               color: Colors.white,
                               border: Border.all(color: Colors.white, width: 4),
                               boxShadow: [
                                 BoxShadow(
                                   color: Colors.white.withValues(alpha: 0.6),
                                   blurRadius: 30 * _logoScale.value,
                                   spreadRadius: 10,
                                 ),
                               ]
                             ),
                             child: ClipOval(
                               child: Image.asset(
                                 'assets/icons/logo_main.png', 
                                 fit: BoxFit.cover,
                                 errorBuilder: (c,o,s) => const Icon(Icons.sentiment_very_satisfied_rounded, color: Colors.cyan, size: 80)
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
                                    colors: [Colors.white, Colors.yellowAccent],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter
                                  ).createShader(bounds),
                                  child: Text(
                                    "SPEECHMATE",
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                      height: 1.0,
                                      shadows: [
                                        Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0,5))
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white.withValues(alpha: 0.8 + (0.2 * _pulseController.value)),
                                          letterSpacing: 1.5,
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
// 🌌 COLORFUL NEON TRIBAL SCRIPT ENGINE
// ---------------------------------------------------------------------------

class _SplashParticle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  String char;
  Color color;
  
  _SplashParticle(math.Random r)
     : x = r.nextDouble(),
       y = r.nextDouble(),
       vx = (r.nextDouble() - 0.5) * 0.003, // Slightly faster
       vy = -r.nextDouble() * 0.004 - 0.001, // Float up
       radius = r.nextDouble() * 20 + 20,
       char = _getRandomChar(r),
       color = _getRandomColor(r);

  static String _getRandomChar(math.Random r) {
    final List<String> nicobarese = ['A', 'Ā', 'B', 'D', 'K', 'L', 'M', 'N', 'O', 'Ò'];
    final List<String> greatAndamanese = ['a', 'e', 'i', 'o', 'u', 'ph', 'th', 'kh'];
    final List<String> onge = ['A', 'Ŋ', 'G', 'K', 'T', 'E', 'Y', 'W'];
    final all = [...nicobarese, ...greatAndamanese, ...onge];
    return all[r.nextInt(all.length)];
  }

  static Color _getRandomColor(math.Random r) {
    final colors = [
       Colors.pinkAccent,
       Colors.cyanAccent,
       Colors.yellowAccent,
       Colors.greenAccent,
       Colors.orangeAccent,
       const Color(0xFFb388ff), // purpleAccent
    ];
    return colors[r.nextInt(colors.length)];
  }

  void update(Offset touchPos, Size size) {
    x += vx;
    y += vy;

    // Wrap around screen
    if (x < -0.1) x = 1.1;
    if (x > 1.1) x = -0.1;
    if (y < -0.2) y = 1.1; 
    
    // Interactive Repulsion from Touch
    if (touchPos != Offset.zero) {
       double tx = touchPos.dx / size.width;
       double ty = touchPos.dy / size.height;
       
       double dx = x - tx;
       double dy = y - ty;
       double dist = math.sqrt(dx*dx + dy*dy);
       
       if (dist < 0.2) {
         vx += dx * 0.008;
         vy += dy * 0.008;
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
    final linePaint = Paint()..strokeWidth = 1.5;

    for (int i = 0; i < particles.length; i++) {
       final p1 = particles[i];
       final pos1 = Offset(p1.x * size.width, p1.y * size.height);

       // Connect to neighbors (Neon Neural Mesh)
       for (int j = i + 1; j < particles.length; j++) {
         final p2 = particles[j];
         final pos2 = Offset(p2.x * size.width, p2.y * size.height);
         
         final dist = (pos1 - pos2).distance;
         
         if (dist < 130) { // Large connection radius
            final double opacity = (1.0 - (dist / 130)) * 0.4;
            // Draw glowing connecting line matching the particle's color
            linePaint.color = p1.color.withValues(alpha: opacity);
            canvas.drawLine(pos1, pos2, linePaint);
         }
       }

       // Draw Glowing Tribal Character
       final textSpan = TextSpan(
         text: p1.char,
         style: TextStyle(
           color: p1.color.withValues(alpha: 0.8 + (0.2 * math.sin(pulse * math.pi + i))),
           fontWeight: FontWeight.bold,
           fontSize: p1.radius + (math.sin(pulse * math.pi + i) * 6), // Pulsing size
           shadows: [
             Shadow(color: p1.color, blurRadius: 15), // Strong neon glow
             Shadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 5), // Inner bright glow
           ]
         ),
       );
       final textPainter = TextPainter(
         text: textSpan,
         textDirection: TextDirection.ltr,
       );
       textPainter.layout();
       textPainter.paint(canvas, pos1 - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
