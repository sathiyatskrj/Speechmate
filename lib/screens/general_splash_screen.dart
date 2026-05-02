import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/services/database_manager.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

class GeneralSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const GeneralSplashScreen({super.key, required this.nextScreen});

  @override
  State<GeneralSplashScreen> createState() => _GeneralSplashScreenState();
}

class _GeneralSplashScreenState extends State<GeneralSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _badgesOpacity;
  late Animation<double> _skipOpacity;

  double _loadProgress = 0.0;
  bool _isPreloading = true;

  // Floating particles
  final int _particleCount = 25;
  final List<_FloatingParticle> _particles = [];
  final math.Random _random = math.Random();

  // Ambient Audio
  final AudioPlayer _ambientPlayer = AudioPlayer();

  // Taglines
  int _currentTagline = 0;
  static const List<String> _taglines = [
    "TRANSLATE • EXPLORE • CONNECT",
    "YOUR ISLAND LANGUAGE COMPANION",
    "BRIDGING CULTURES OFFLINE",
  ];

  @override
  void initState() {
    super.initState();

    // Generate floating particles
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_FloatingParticle(_random));
    }

    // Pulse controller for ambient effects
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Wave controller for background animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Main sequencing controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    // 1. Logo scale in (0% - 40%)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.4, curve: Curves.elasticOut)),
    );
    _logoOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
    );

    // 2. Title slide up (30% - 55%)
    _titleSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.3, 0.55, curve: Curves.easeOutCubic)),
    );
    _titleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.5, curve: Curves.easeIn),
    );

    // 3. Subtitle (45% - 65%)
    _subtitleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.45, 0.65, curve: Curves.easeIn),
    );

    // 4. Feature badges (55% - 75%)
    _badgesOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.55, 0.75, curve: Curves.easeIn),
    );

    // 5. Skip hint (40% - 55%)
    _skipOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.55, curve: Curves.easeIn),
    );

    // Rotate taglines
    _pulseController.addListener(() {
      if (_pulseController.value > 0.98) {
        if (mounted) {
          setState(() {
            _currentTagline = (_currentTagline + 1) % _taglines.length;
          });
        }
      }
    });

    // Animate particles
    _waveController.addListener(() {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      setState(() {
        for (var p in _particles) {
          p.update(size);
        }
      });
    });

    _mainController.forward();
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        _navigateNext();
      }
    });

    _playAmbientAudio();
    _preloadData();
  }

  Future<void> _playAmbientAudio() async {
    try {
      await _ambientPlayer.setVolume(0.0);
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setSource(AssetSource('audio/ambient.mp3'));
      await _ambientPlayer.resume();
      await _ambientPlayer.seek(const Duration(seconds: 2));
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        await _ambientPlayer.setVolume(i * 0.04);
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
      setState(() => _loadProgress = 0.2);
      await DatabaseManager.instance.database;
      if (!mounted) return;
      setState(() => _loadProgress = 0.5);

      await DatabaseManager.instance
          .seedCategoryFromJson('main', 'assets/data/dictionary.json');
      if (!mounted) return;
      setState(() => _loadProgress = 0.8);

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
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 800),
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
    _waveController.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF8FF),
      body: GestureDetector(
        onTap: () {
          if (_mainController.value > 0.3) _skipSplash();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ═══ ANIMATED GRADIENT BACKGROUND ═══
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _GradientWavePainter(
                    progress: _waveController.value,
                    pulse: _pulseController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // ═══ FLOATING PARTICLES ═══
            AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      pulse: _pulseController.value,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),

            // ═══ CENTER CONTENT ═══
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // ── LOGO ──
                      Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF00B0FF),
                                  Color(0xFF00E5FF),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00B0FF)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 30 * _logoScale.value,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 50,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icons/logo_main.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) => const Icon(
                                        Icons.language,
                                        color: Color(0xFF00B0FF),
                                        size: 60),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // ── APP NAME ──
                      Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Opacity(
                          opacity: _titleOpacity.value,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                Color(0xFF0091EA),
                                Color(0xFF00BFA5),
                                Color(0xFF2979FF),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: Text(
                              "SPEECHMATE",
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 3.0,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                      color: const Color(0xFF0091EA)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5))
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── ROTATING TAGLINE ──
                      Opacity(
                        opacity: _subtitleOpacity.value,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                _taglines[_currentTagline],
                                key: ValueKey(_currentTagline),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF37474F).withValues(
                                      alpha: 0.5 +
                                          (0.3 * _pulseController.value)),
                                  letterSpacing: 2.5,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 35),

                      // ── FEATURE BADGES ──
                      Opacity(
                        opacity: _badgesOpacity.value,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _featureBadge("🎙️ Voice", const Color(0xFF0091EA)),
                            _featureBadge("📸 Camera", const Color(0xFF00BFA5)),
                            _featureBadge("🌐 Offline", const Color(0xFF00C853)),
                            _featureBadge("🏝️ Islands", const Color(0xFF2979FF)),
                          ],
                        ),
                      ),

                      const Spacer(flex: 3),
                    ],
                  );
                },
              ),
            ),

            // ═══ PROGRESS BAR ═══
            if (_isPreloading)
              Positioned(
                bottom: 80,
                left: 40,
                right: 40,
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _loadProgress,
                            minHeight: 4,
                            backgroundColor:
                                const Color(0xFF0091EA).withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF00B0FF)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preparing your experience...',
                          style: TextStyle(
                            color: const Color(0xFF546E7A).withValues(alpha: 0.5),
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ═══ TAP TO CONTINUE ═══
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (_, __) => Opacity(
                  opacity: _skipOpacity.value * 0.5,
                  child: const Center(
                    child: Text(
                      'TAP TO CONTINUE',
                      style: TextStyle(
                        color: const Color(0xFF90A4AE),
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ═══ VERSION ═══
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (_, __) => Opacity(
                  opacity: _badgesOpacity.value * 0.5,
                  child: const Center(
                    child: Text(
                      'v1.4.8 • General Edition',
                      style: TextStyle(
                        color: const Color(0xFFB0BEC5),
                        fontSize: 11,
                        letterSpacing: 1.5,
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

  Widget _featureBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// 🌊 ANIMATED WAVE GRADIENT BACKGROUND
// ═══════════════════════════════════════════════════

class _GradientWavePainter extends CustomPainter {
  final double progress;
  final double pulse;

  _GradientWavePainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    // Crisp white-to-ice base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5FE), Color(0xFFF0FFFE), Color(0xFFE0F7FA)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final paint = Paint()..style = PaintingStyle.fill;

    // Blob 1 — Electric blue (top-right)
    final blob1Center = Offset(
      size.width * (0.7 + 0.15 * math.sin(progress * 2 * math.pi)),
      size.height * (0.2 + 0.1 * math.cos(progress * 2 * math.pi)),
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF00B0FF).withValues(alpha: 0.35 + 0.1 * pulse),
        const Color(0xFF00B0FF).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: blob1Center, radius: size.width * 0.45));
    canvas.drawCircle(blob1Center, size.width * 0.45, paint);

    // Blob 2 — Vivid teal (bottom-left)
    final blob2Center = Offset(
      size.width * (0.25 + 0.12 * math.cos(progress * 2 * math.pi + 1)),
      size.height * (0.75 + 0.08 * math.sin(progress * 2 * math.pi + 1)),
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF00E5FF).withValues(alpha: 0.3 + 0.1 * pulse),
        const Color(0xFF00E5FF).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: blob2Center, radius: size.width * 0.5));
    canvas.drawCircle(blob2Center, size.width * 0.5, paint);

    // Blob 3 — Bright lime green (center-right)
    final blob3Center = Offset(
      size.width * (0.55 + 0.1 * math.sin(progress * 2 * math.pi + 2.5)),
      size.height * (0.55 + 0.12 * math.cos(progress * 2 * math.pi + 2.5)),
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF69F0AE).withValues(alpha: 0.25 + 0.08 * pulse),
        const Color(0xFF69F0AE).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: blob3Center, radius: size.width * 0.4));
    canvas.drawCircle(blob3Center, size.width * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════
// ✨ FLOATING PARTICLE SYSTEM
// ═══════════════════════════════════════════════════

class _FloatingParticle {
  double x, y, vx, vy, radius;
  Color color;

  _FloatingParticle(math.Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        vx = (r.nextDouble() - 0.5) * 0.002,
        vy = -r.nextDouble() * 0.003 - 0.0005,
        radius = r.nextDouble() * 3 + 1,
        color = _randomColor(r);

  static Color _randomColor(math.Random r) {
    final colors = [
      const Color(0xFF00B0FF),
      const Color(0xFF00E5FF),
      const Color(0xFF69F0AE),
      const Color(0xFF00BFA5),
      const Color(0xFF2979FF),
      const Color(0xFF80D8FF),
    ];
    return colors[r.nextInt(colors.length)];
  }

  void update(Size size) {
    x += vx;
    y += vy;
    if (x < -0.05) x = 1.05;
    if (x > 1.05) x = -0.05;
    if (y < -0.1) y = 1.1;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double pulse;

  _ParticlePainter({required this.particles, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()..strokeWidth = 0.5;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final pos = Offset(p.x * size.width, p.y * size.height);
      final alpha = 0.3 + 0.3 * math.sin(pulse * math.pi + i);

      // Glow dot
      paint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(pos, p.radius + (pulse * 1.5), paint);

      // Soft halo
      paint.color = p.color.withValues(alpha: alpha * 0.2);
      canvas.drawCircle(pos, p.radius * 4, paint);

      // Connect nearby particles
      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final pos2 = Offset(p2.x * size.width, p2.y * size.height);
        final dist = (pos - pos2).distance;
        if (dist < 100) {
          linePaint.color =
              p.color.withValues(alpha: (1 - dist / 100) * 0.15);
          canvas.drawLine(pos, pos2, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
