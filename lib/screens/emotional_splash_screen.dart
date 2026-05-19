import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/services/database_manager.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:speechmate/services/whisper_service.dart';

/// Premium splash screen for SpeechMate Educational Edition.
/// Deep ocean-twilight theme with organic firefly particles.
/// Designed for a warm, institutional, professional feel.
class EmotionalSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const EmotionalSplashScreen({super.key, required this.nextScreen});

  @override
  State<EmotionalSplashScreen> createState() => _EmotionalSplashScreenState();
}

class _EmotionalSplashScreenState extends State<EmotionalSplashScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  // ── Staged Animations ──
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _titleFade;
  late Animation<double> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _badgeFade;
  late Animation<double> _skipFade;

  // ── State ──
  double _loadProgress = 0.0;
  bool _isPreloading = true;
  int _taglineIndex = 0;

  // ── Particles ──
  final List<_Firefly> _fireflies = [];
  final math.Random _rng = math.Random();

  // ── Audio ──
  final AudioPlayer _ambientPlayer = AudioPlayer();

  // ── Constants ──
  static const _taglines = [
    'Speak  ·  Learn  ·  Explore',
    'Your Island Language Buddy',
    'Making Words Fun & Easy',
  ];

  // ── Deep ocean palette ──
  static const _bgTop = Color(0xFF0B1628);
  static const _bgMid = Color(0xFF132742);
  static const _bgBot = Color(0xFF1B3A5C);
  static const _accentTeal = Color(0xFF4ECDC4);
  static const _accentCoral = Color(0xFFFF6B6B);
  static const _accentGold = Color(0xFFFFD166);
  static const _textPrimary = Color(0xFFF0F4F8);
  static const _textSecondary = Color(0xFFABC4DD);

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning, Explorer!';
    if (h < 17) return 'Good Afternoon, Champion!';
    return 'Good Evening, Superstar!';
  }

  String get _greetingEmoji {
    final h = DateTime.now().hour;
    if (h < 12) return '🌅';
    if (h < 17) return '☀️';
    return '🌙';
  }

  // ════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _seedFireflies();
    _setupAnimations();
    _playAmbientAudio();
    _preloadData();
  }

  void _seedFireflies() {
    for (int i = 0; i < 35; i++) {
      _fireflies.add(_Firefly(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        radius: 1.2 + _rng.nextDouble() * 2.5,
        speed: 0.08 + _rng.nextDouble() * 0.15,
        phase: _rng.nextDouble() * math.pi * 2,
        brightness: 0.3 + _rng.nextDouble() * 0.7,
        hueShift: _rng.nextInt(3), // 0=teal, 1=gold, 2=coral
      ));
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
    );
    _titleSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.28, 0.52, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.28, 0.48, curve: Curves.easeIn),
    );
    _subtitleFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.42, 0.62, curve: Curves.easeIn),
    );
    _badgeFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.55, 0.75, curve: Curves.easeIn),
    );
    _skipFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.45, 0.6, curve: Curves.easeIn),
    );

    // Rotate taglines
    _pulseController.addListener(() {
      if (_pulseController.value > 0.98 && mounted) {
        setState(() => _taglineIndex = (_taglineIndex + 1) % _taglines.length);
      }
    });

    _mainController.forward();
    _mainController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        _navigateNext();
      }
    });
  }

  // ── Audio ──
  Future<void> _playAmbientAudio() async {
    try {
      await _ambientPlayer.setVolume(0.0);
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setSource(AssetSource('audio/ambient.mp3'));
      await _ambientPlayer.seek(const Duration(seconds: 2));
      await _ambientPlayer.resume();
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

  // ── Preload ──
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

    // Fire-and-forget Whisper warm-up so voice features have zero cold-start
    WhisperService().initialize().then((_) {
      debugPrint('[Splash] Whisper warm-up complete.');
    }).catchError((e) {
      debugPrint('[Splash] Whisper warm-up skipped: $e');
    });
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
    _particleController.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (_mainController.value > 0.3) _skipSplash();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ═══ DEEP OCEAN GRADIENT ═══
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgTop, _bgMid, _bgBot],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ═══ ANIMATED AURORA GLOW ═══
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _AuroraGlowPainter(
                    pulse: _pulseController.value,
                  ),
                );
              },
            ),

            // ═══ FIREFLY PARTICLES ═══
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _FireflyPainter(
                    fireflies: _fireflies,
                    time: _particleController.value,
                    pulse: _pulseController.value,
                  ),
                );
              },
            ),

            // ═══ SUBTLE OCEAN WAVE ═══
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _OceanWavePainter(
                    time: _particleController.value * math.pi * 2,
                  ),
                );
              },
            ),

            // ═══ CENTER CONTENT ═══
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, _) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 50),
                          _buildGreeting(),
                          const SizedBox(height: 35),
                          _buildLogo(),
                          const SizedBox(height: 32),
                          _buildTitle(),
                          const SizedBox(height: 14),
                          _buildTagline(),
                          const SizedBox(height: 28),
                          _buildBadges(),
                          const SizedBox(height: 40),
                          if (_isPreloading) _buildProgress(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // ═══ TAP TO CONTINUE ═══
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (_, __) => Opacity(
                  opacity: _skipFade.value * 0.6,
                  child: const Center(
                    child: Text(
                      'TAP ANYWHERE TO CONTINUE',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ═══ VERSION ═══
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (_, __) => Opacity(
                  opacity: _badgeFade.value * 0.4,
                  child: Center(
                    child: Text(
                      'v1.4.9  •  Educational Edition',
                      style: TextStyle(
                        color: _textSecondary.withValues(alpha: 0.5),
                        fontSize: 10,
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

  // ── Greeting pill ──
  Widget _buildGreeting() {
    return Opacity(
      opacity: _logoFade.value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _accentTeal.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_greetingEmoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              _greeting,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _accentGold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logo circle ──
  Widget _buildLogo() {
    return Transform.scale(
      scale: _logoScale.value,
      child: Opacity(
        opacity: _logoFade.value,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_accentTeal, Color(0xFF2196F3)],
            ),
            boxShadow: [
              BoxShadow(
                color: _accentTeal.withValues(alpha: 0.35),
                blurRadius: 30,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFF2196F3).withValues(alpha: 0.2),
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
                    Icons.translate_rounded,
                    color: _accentTeal,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Title + subtitle ──
  Widget _buildTitle() {
    return Transform.translate(
      offset: Offset(0, _titleSlide.value),
      child: Opacity(
        opacity: _titleFade.value,
        child: Column(
          children: [
            Text(
              'SPEECHMATE',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
                letterSpacing: 4.0,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: _accentTeal.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Where Language Barriers End',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textSecondary.withValues(alpha: 0.85),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rotating tagline ──
  Widget _buildTagline() {
    return Opacity(
      opacity: _subtitleFade.value,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Text(
          _taglines[_taglineIndex],
          key: ValueKey(_taglineIndex),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _accentGold.withValues(alpha: 0.7),
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // ── Feature badges ──
  Widget _buildBadges() {
    return Opacity(
      opacity: _badgeFade.value,
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _badge('🎙️ Voice', _accentCoral),
          _badge('📸 Camera', const Color(0xFFE17055)),
          _badge('🌐 Offline', _accentTeal),
          _badge('🏝️ Islands', const Color(0xFF6C5CE7)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Progress bar ──
  Widget _buildProgress() {
    return Opacity(
      opacity: _logoFade.value,
      child: Column(
        children: [
          SizedBox(
            width: 220,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _loadProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(_accentTeal),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Preparing your journey…',
            style: TextStyle(
              color: _textSecondary.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// AURORA GLOW — Subtle ambient light blobs
// ═══════════════════════════════════════════════════════

class _AuroraGlowPainter extends CustomPainter {
  final double pulse;
  _AuroraGlowPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    // Top-left teal glow
    final c1 = Offset(size.width * 0.15, size.height * 0.18);
    p.shader = RadialGradient(colors: [
      const Color(0xFF4ECDC4).withValues(alpha: 0.06 + 0.03 * pulse),
      const Color(0xFF4ECDC4).withValues(alpha: 0.0),
    ]).createShader(Rect.fromCircle(center: c1, radius: size.width * 0.5));
    canvas.drawCircle(c1, size.width * 0.5, p);

    // Bottom-right coral glow
    final c2 = Offset(size.width * 0.85, size.height * 0.75);
    p.shader = RadialGradient(colors: [
      const Color(0xFFFF6B6B).withValues(alpha: 0.04 + 0.02 * pulse),
      const Color(0xFFFF6B6B).withValues(alpha: 0.0),
    ]).createShader(Rect.fromCircle(center: c2, radius: size.width * 0.45));
    canvas.drawCircle(c2, size.width * 0.45, p);

    // Center gold glow (very subtle)
    final c3 = Offset(size.width * 0.5, size.height * 0.42);
    p.shader = RadialGradient(colors: [
      const Color(0xFFFFD166).withValues(alpha: 0.03 + 0.015 * pulse),
      const Color(0xFFFFD166).withValues(alpha: 0.0),
    ]).createShader(Rect.fromCircle(center: c3, radius: size.width * 0.4));
    canvas.drawCircle(c3, size.width * 0.4, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════
// FIREFLY PARTICLES — Organic, drifting light dots
// ═══════════════════════════════════════════════════════

class _Firefly {
  double x, y, radius, speed, phase, brightness;
  int hueShift;
  _Firefly({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.brightness,
    required this.hueShift,
  });
}

class _FireflyPainter extends CustomPainter {
  final List<_Firefly> fireflies;
  final double time;
  final double pulse;

  static const _hueColors = [
    Color(0xFF4ECDC4), // teal
    Color(0xFFFFD166), // gold
    Color(0xFFFF6B6B), // coral
  ];

  _FireflyPainter({
    required this.fireflies,
    required this.time,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < fireflies.length; i++) {
      final f = fireflies[i];
      final t = time * f.speed * math.pi * 2 + f.phase;

      // Gentle sinusoidal drift
      final px = f.x * size.width + math.sin(t * 0.8 + i) * 25;
      final py = f.y * size.height + math.cos(t * 0.6 + i * 0.4) * 20;

      // Pulsing alpha
      final alpha = f.brightness *
          (0.3 + 0.4 * math.sin(t * 1.5 + i * 0.7).abs()) *
          (0.8 + 0.2 * pulse);

      final color = _hueColors[f.hueShift];
      final paint = Paint()
        ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.radius * 1.5);

      canvas.drawCircle(Offset(px, py), f.radius, paint);

      // Brighter core
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: (alpha * 0.6).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), f.radius * 0.35, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════
// OCEAN WAVE — Subtle wave at the bottom
// ═══════════════════════════════════════════════════════

class _OceanWavePainter extends CustomPainter {
  final double time;
  _OceanWavePainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    _drawWave(canvas, size, paint, 0.88, 12, 1.5, time,
        const Color(0xFF4ECDC4).withValues(alpha: 0.06));
    _drawWave(canvas, size, paint, 0.91, 8, 2.0, time * 0.7 + 1.5,
        const Color(0xFF2196F3).withValues(alpha: 0.05));
    _drawWave(canvas, size, paint, 0.94, 6, 2.5, time * 1.3 + 3.0,
        const Color(0xFF4ECDC4).withValues(alpha: 0.04));
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double yOff,
      double amp, double freq, double phase, Color color) {
    paint.color = color;
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 4) {
      final y = size.height * yOff +
          math.sin((x / size.width) * freq * math.pi * 2 + phase) * amp;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
