import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/services/database_manager.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

/// Child-friendly splash screen for SpeechMate Educational Edition.
/// Warm island theme with gentle floating words and cheerful colors.
/// Designed for children — bright, playful, and inviting.
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
  late AnimationController _floatController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _badgesOpacity;
  late Animation<double> _skipOpacity;

  double _loadProgress = 0.0;
  bool _isPreloading = true;

  // Gentle floating words — authentic island language words
  final List<_FloatingWord> _floatingWords = [];
  final math.Random _rng = math.Random();

  static const List<String> _islandWords = [
    'Minyuku', 'Kojito', 'Bulu', 'Töku', 'Lūng',
    'Kamorta', 'Onges', 'Jarawa', 'Shompen',
  ];

  // Ambient Audio
  final AudioPlayer _ambientPlayer = AudioPlayer();

  // Time-aware greeting
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, Explorer!';
    if (hour < 17) return 'Good Afternoon, Champion!';
    return 'Good Evening, Superstar!';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  // Rotating taglines
  int _currentTagline = 0;
  static const List<String> _taglines = [
    'Speak  •  Learn  •  Explore',
    'Your Island Language Buddy',
    'Making Words Fun & Easy',
  ];

  @override
  void initState() {
    super.initState();
    _initFloatingWords();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    // Logo scale in (0% - 40%)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.4, curve: Curves.elasticOut)),
    );
    _logoOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
    );

    // Title slide up (30% - 55%)
    _titleSlide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.3, 0.55, curve: Curves.easeOutCubic)),
    );
    _titleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.5, curve: Curves.easeIn),
    );

    // Subtitle (45% - 65%)
    _subtitleOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.45, 0.65, curve: Curves.easeIn),
    );

    // Feature badges (55% - 75%)
    _badgesOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.55, 0.75, curve: Curves.easeIn),
    );

    // Skip hint (40% - 55%)
    _skipOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.55, curve: Curves.easeIn),
    );

    // Rotate taglines every pulse cycle
    _pulseController.addListener(() {
      if (_pulseController.value > 0.98) {
        if (mounted) {
          setState(() {
            _currentTagline = (_currentTagline + 1) % _taglines.length;
          });
        }
      }
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

  void _initFloatingWords() {
    for (int i = 0; i < 14; i++) {
      _floatingWords.add(_FloatingWord(
        word: _islandWords[_rng.nextInt(_islandWords.length)],
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        speed: 0.15 + _rng.nextDouble() * 0.3,
        phase: _rng.nextDouble() * math.pi * 2,
        size: 12.0 + _rng.nextDouble() * 10,
        colorIndex: _rng.nextInt(5),
      ));
    }
  }

  Future<void> _playAmbientAudio() async {
    try {
      await _ambientPlayer.setVolume(0.0);
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer.setSource(AssetSource('audio/ambient_child.mp3'));
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
    _floatController.dispose();
    _ambientPlayer.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD166), // Warm sunny yellow
      body: GestureDetector(
        onTap: () {
          if (_mainController.value > 0.3) _skipSplash();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ═══ WARM ISLAND WAVE BACKGROUND ═══
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _IslandWavePainter(
                    time: _waveController.value * math.pi * 2,
                    pulse: _pulseController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // ═══ FLOATING ISLAND WORDS ═══
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _FloatingWordPainter(
                    words: _floatingWords,
                    time: _floatController.value,
                  ),
                );
              },
            ),

            // ═══ CENTER CONTENT ═══
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          // ── TIME-AWARE GREETING ──
                          Opacity(
                            opacity: _logoOpacity.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _greetingEmoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _greeting,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D3557),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── LOGO ──
                          Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFF6B6B),
                                      Color(0xFF4ECDC4),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B6B)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 25,
                                      spreadRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF4ECDC4)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 40,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
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
                                            Icons.child_care,
                                            color: Color(0xFFFF6B6B),
                                            size: 65),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ── APP NAME ──
                          Transform.translate(
                            offset: Offset(0, _titleSlide.value),
                            child: Opacity(
                              opacity: _titleOpacity.value,
                              child: Column(
                                children: [
                                  Text(
                                    'SpeechMate',
                                    style: TextStyle(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1D3557),
                                      letterSpacing: 2.0,
                                      height: 1.0,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Text(
                                      'Learn Authentic Island Words! 🏝️',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1D3557),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── ROTATING TAGLINE ──
                          Opacity(
                            opacity: _subtitleOpacity.value,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                _taglines[_currentTagline],
                                key: ValueKey(_currentTagline),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1D3557)
                                      .withValues(alpha: 0.7),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ── FEATURE BADGES ──
                          Opacity(
                            opacity: _badgesOpacity.value,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _featureBadge(
                                    '🎙️ Voice', const Color(0xFFFF6B6B)),
                                _featureBadge(
                                    '📸 Camera', const Color(0xFFE17055)),
                                _featureBadge(
                                    '🌐 Offline', const Color(0xFF4ECDC4)),
                                _featureBadge(
                                    '🏝️ Islands', const Color(0xFF6C5CE7)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ── PROGRESS BAR ──
                          if (_isPreloading)
                            Opacity(
                              opacity: _logoOpacity.value,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 50),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: 250,
                                      height: 10,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: LinearProgressIndicator(
                                          value: _loadProgress,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.35),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(Color(0xFF4ECDC4)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Packing your bags... 🎒',
                                      style: TextStyle(
                                        color: const Color(0xFF1D3557)
                                            .withValues(alpha: 0.7),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

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
                  opacity: _skipOpacity.value * 0.7,
                  child: Center(
                    child: Text(
                      'TAP ANYWHERE TO CONTINUE',
                      style: TextStyle(
                        color: const Color(0xFF1D3557)
                            .withValues(alpha: 0.45),
                        fontSize: 11,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ═══ VERSION ═══
            Positioned(
              bottom: 25,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (_, __) => Opacity(
                  opacity: _badgesOpacity.value * 0.5,
                  child: Center(
                    child: Text(
                      'v1.4.8 • Educational Edition',
                      style: TextStyle(
                        color: const Color(0xFF1D3557)
                            .withValues(alpha: 0.35),
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
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 6,
              spreadRadius: 1),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Gentle floating word for the background
// ═══════════════════════════════════════════════════

class _FloatingWord {
  String word;
  double x, y;
  double speed;
  double phase;
  double size;
  int colorIndex;

  _FloatingWord({
    required this.word,
    required this.x,
    required this.y,
    required this.speed,
    required this.phase,
    required this.size,
    required this.colorIndex,
  });
}

// ═══════════════════════════════════════════════════
// Warm island wave background — cheerful & child-friendly
// ═══════════════════════════════════════════════════

class _IslandWavePainter extends CustomPainter {
  final double time;
  final double pulse;

  _IslandWavePainter({required this.time, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    // Warm sunny base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFD166), // Warm yellow
            Color(0xFFFFC947), // Deeper gold
            Color(0xFFFFBE76), // Sunset peach
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final paint = Paint()..style = PaintingStyle.fill;

    // Gentle ocean waves at bottom
    _drawWave(canvas, size, paint, 0.72, 35, 1.5, time,
        const Color(0xFF4ECDC4).withValues(alpha: 0.25 + 0.05 * pulse));
    _drawWave(canvas, size, paint, 0.78, 45, 1.0, time * 1.2 + 2,
        const Color(0xFF45B7D1).withValues(alpha: 0.2 + 0.05 * pulse));
    _drawWave(canvas, size, paint, 0.85, 30, 2.0, time * 0.8 + 4,
        const Color(0xFF4ECDC4).withValues(alpha: 0.3 + 0.05 * pulse));

    // Soft coral cloud blobs — top area
    final blobPaint = Paint()..style = PaintingStyle.fill;
    final blob1 = Offset(
      size.width * (0.2 + 0.05 * math.sin(time * 0.5)),
      size.height * (0.08 + 0.02 * math.cos(time * 0.7)),
    );
    blobPaint.shader = RadialGradient(
      colors: [
        const Color(0xFFFF6B6B).withValues(alpha: 0.15 + 0.05 * pulse),
        const Color(0xFFFF6B6B).withValues(alpha: 0.0),
      ],
    ).createShader(
        Rect.fromCircle(center: blob1, radius: size.width * 0.35));
    canvas.drawCircle(blob1, size.width * 0.35, blobPaint);

    final blob2 = Offset(
      size.width * (0.8 + 0.04 * math.cos(time * 0.6)),
      size.height * (0.12 + 0.03 * math.sin(time * 0.5)),
    );
    blobPaint.shader = RadialGradient(
      colors: [
        const Color(0xFF6C5CE7).withValues(alpha: 0.1 + 0.04 * pulse),
        const Color(0xFF6C5CE7).withValues(alpha: 0.0),
      ],
    ).createShader(
        Rect.fromCircle(center: blob2, radius: size.width * 0.3));
    canvas.drawCircle(blob2, size.width * 0.3, blobPaint);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double yOffset,
      double amplitude, double frequency, double phase, Color color) {
    paint.color = color;
    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 4) {
      final y = size.height * yOffset +
          math.sin((x / size.width) * frequency * math.pi * 2 + phase) *
              amplitude;
      if (x == 0) {
        path.lineTo(0, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════
// Floating word painter — gentle drift, no physics chaos
// ═══════════════════════════════════════════════════

class _FloatingWordPainter extends CustomPainter {
  final List<_FloatingWord> words;
  final double time;

  static const List<Color> _colors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
    Color(0xFF6C5CE7),
    Color(0xFFE17055),
  ];

  _FloatingWordPainter({required this.words, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final t = time * word.speed * math.pi * 2 + word.phase;

      // Gentle sinusoidal drift — no bouncing, no collisions
      final px = word.x * size.width +
          math.sin(t * 0.7 + i) * 20;
      final py = word.y * size.height +
          math.cos(t * 0.5 + i * 0.3) * 15;

      final alpha = 0.15 + 0.1 * math.sin(t + i * 0.5);
      final color = _colors[word.colorIndex];

      final textSpan = TextSpan(
        text: word.word,
        style: TextStyle(
          fontSize: word.size,
          fontWeight: FontWeight.w800,
          color: color.withValues(alpha: alpha),
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              px - textPainter.width / 2, py - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
