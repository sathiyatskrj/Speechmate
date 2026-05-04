import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/services/database_manager.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

class EmotionalSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const EmotionalSplashScreen({super.key, required this.nextScreen});

  @override
  State<EmotionalSplashScreen> createState() => _EmotionalSplashScreenState();
}

class _EmotionalSplashScreenState extends State<EmotionalSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _emojiController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _badgesOpacity;
  late Animation<double> _skipOpacity;

  double _loadProgress = 0.0;
  bool _isPreloading = true;

  // Floating emoji particles — fun for kids! 🌈
  final int _particleCount = 18;
  final List<_FunParticle> _particles = [];
  final math.Random _random = math.Random();

  // Ambient Audio
  final AudioPlayer _ambientPlayer = AudioPlayer();

  // Time-aware greeting for children
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅 Good Morning, Explorer!';
    if (hour < 17) return '☀️ Good Afternoon, Champion!';
    return '🌙 Good Evening, Superstar!';
  }

  // Taglines
  int _currentTagline = 0;
  static const List<String> _taglines = [
    "🗣️ SPEAK • 🎨 LEARN • 🌍 EXPLORE",
    "🏝️ YOUR ISLAND LANGUAGE BUDDY",
    "✨ MAKING WORDS FUN & EASY",
  ];

  @override
  void initState() {
    super.initState();

    // Generate floating emoji particles
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_FunParticle(_random));
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

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
    _emojiController.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0533),
      body: GestureDetector(
        onTap: () {
          if (_mainController.value > 0.3) _skipSplash();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ═══ RAINBOW CANDY GRADIENT BACKGROUND ═══
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RainbowWavePainter(
                    progress: _waveController.value,
                    pulse: _pulseController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // ═══ FLOATING EMOJI PARTICLES ═══
            AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: CustomPaint(
                    painter: _EmojiParticlePainter(
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

                      // ── TIME-AWARE GREETING ──
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: Text(
                            _greeting,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

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
                                  Color(0xFFFF6B6B), // Coral
                                  Color(0xFFFFE66D), // Sunny yellow
                                  Color(0xFF4ECDC4), // Teal
                                  Color(0xFF45B7D1), // Sky blue
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B6B)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 30 * _logoScale.value,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF4ECDC4)
                                      .withValues(alpha: 0.3),
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
                                        Icons.auto_awesome,
                                        color: Color(0xFFFF6B6B),
                                        size: 60),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // ── APP NAME — RAINBOW GRADIENT ──
                      Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Opacity(
                          opacity: _titleOpacity.value,
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                Color(0xFFFF6B6B), // Red/coral
                                Color(0xFFFFE66D), // Yellow
                                Color(0xFF4ECDC4), // Teal
                                Color(0xFF45B7D1), // Blue
                                Color(0xFFBB6BD9), // Purple
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: Text(
                              "SPEECHMATE",
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 3.0,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(
                                      alpha: 0.7 +
                                          (0.3 * _pulseController.value)),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 35),

                      // ── FEATURE BADGES — COLORFUL ──
                      Opacity(
                        opacity: _badgesOpacity.value,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _featureBadge("🎙️ Voice", const Color(0xFFFF6B6B)),
                            _featureBadge("📸 Camera", const Color(0xFFFFE66D)),
                            _featureBadge("🌐 Offline", const Color(0xFF4ECDC4)),
                            _featureBadge("🏝️ Islands", const Color(0xFFBB6BD9)),
                          ],
                        ),
                      ),

                      const Spacer(flex: 3),
                    ],
                  );
                },
              ),
            ),

            // ═══ PROGRESS BAR — RAINBOW ═══
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
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: _loadProgress,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B6B),
                                      Color(0xFFFFE66D),
                                      Color(0xFF4ECDC4),
                                      Color(0xFF45B7D1),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '✨ Preparing your adventure...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
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
                  opacity: _skipOpacity.value * 0.6,
                  child: Center(
                    child: Text(
                      '👆 TAP TO CONTINUE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
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
                  child: Center(
                    child: Text(
                      'v1.5.0 • Educational Edition 🌟',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w400,
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
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8, spreadRadius: 1),
        ],
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
// 🌈 RAINBOW CANDY WAVE BACKGROUND
// ═══════════════════════════════════════════════════

class _RainbowWavePainter extends CustomPainter {
  final double progress;
  final double pulse;

  _RainbowWavePainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep space-candy base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0533), // Deep purple-black
            Color(0xFF0D1B2A), // Deep navy
            Color(0xFF1B0A2E), // Dark violet
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final paint = Paint()..style = PaintingStyle.fill;

    // Blob 1 — Coral/Pink (top-right)
    final blob1Center = Offset(
      size.width * (0.75 + 0.12 * math.sin(progress * 2 * math.pi)),
      size.height * (0.15 + 0.08 * math.cos(progress * 2 * math.pi)),
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFF6B6B).withValues(alpha: 0.35 + 0.1 * pulse),
        const Color(0xFFFF6B6B).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: blob1Center, radius: size.width * 0.5));
    canvas.drawCircle(blob1Center, size.width * 0.5, paint);

    // Blob 2 — Sunny Yellow (center-left)
    final blob2Center = Offset(
      size.width * (0.2 + 0.1 * math.cos(progress * 2 * math.pi + 1.5)),
      size.height * (0.45 + 0.1 * math.sin(progress * 2 * math.pi + 1.5)),
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFE66D).withValues(alpha: 0.2 + 0.08 * pulse),
        const Color(0xFFFFE66D).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: blob2Center, radius: size.width * 0.45));
    canvas.drawCircle(blob2Center, size.width * 0.45, paint);

    // Blob 3 — Teal/Cyan (bottom-right)
    final blob3Center = Offset(
      size.width * (0.7 + 0.08 * math.sin(progress * 2 * math.pi + 3)),
      size.height * (0.75 + 0.06 * math.cos(progress * 2 * math.pi + 3)),
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF4ECDC4).withValues(alpha: 0.3 + 0.1 * pulse),
        const Color(0xFF4ECDC4).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: blob3Center, radius: size.width * 0.5));
    canvas.drawCircle(blob3Center, size.width * 0.5, paint);

    // Blob 4 — Purple/Violet (bottom-left)
    final blob4Center = Offset(
      size.width * (0.25 + 0.1 * math.cos(progress * 2 * math.pi + 4.5)),
      size.height * (0.8 + 0.08 * math.sin(progress * 2 * math.pi + 4.5)),
    );
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFBB6BD9).withValues(alpha: 0.25 + 0.08 * pulse),
        const Color(0xFFBB6BD9).withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: blob4Center, radius: size.width * 0.4));
    canvas.drawCircle(blob4Center, size.width * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════
// ✨ FUN EMOJI PARTICLE SYSTEM — CHILD FRIENDLY
// ═══════════════════════════════════════════════════

class _FunParticle {
  double x, y, vx, vy, size;
  String emoji;
  double rotationSpeed;

  static const List<String> _emojis = [
    '⭐', '🌟', '✨', '💫', '🎨', '📚', '🎵', '🌈',
    '🦋', '🌺', '🎯', '🏝️', '🐚', '🌴', '🎪', '🪁',
  ];

  _FunParticle(math.Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        vx = (r.nextDouble() - 0.5) * 0.001,
        vy = -r.nextDouble() * 0.002 - 0.0003,
        size = r.nextDouble() * 14 + 10,
        emoji = _emojis[r.nextInt(_emojis.length)],
        rotationSpeed = (r.nextDouble() - 0.5) * 0.02;

  void update(Size screenSize) {
    x += vx;
    y += vy;
    if (x < -0.05) x = 1.05;
    if (x > 1.05) x = -0.05;
    if (y < -0.1) y = 1.1;
  }
}

class _EmojiParticlePainter extends CustomPainter {
  final List<_FunParticle> particles;
  final double pulse;

  _EmojiParticlePainter({required this.particles, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final pos = Offset(p.x * size.width, p.y * size.height);
      final alpha = 0.3 + 0.4 * math.sin(pulse * math.pi + i * 0.7);

      // Draw emoji text
      final textSpan = TextSpan(
        text: p.emoji,
        style: TextStyle(
          fontSize: p.size + (math.sin(pulse * math.pi + i) * 3),
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));

      // Soft glow behind each emoji
      final glowPaint = Paint()
        ..color = const Color(0xFFFFE66D).withValues(alpha: alpha * 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, p.size * 1.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
