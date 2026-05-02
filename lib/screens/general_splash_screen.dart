import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/services/database_manager.dart';
import 'dart:math' as math;

class GeneralSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const GeneralSplashScreen({super.key, required this.nextScreen});

  @override
  State<GeneralSplashScreen> createState() => _GeneralSplashScreenState();
}

class _GeneralSplashScreenState extends State<GeneralSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  double _loadProgress = 0.0;
  bool _isPreloading = true;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _mainController.forward();
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });

    _preloadData();
  }

  Future<void> _preloadData() async {
    try {
      setState(() => _loadProgress = 0.2);
      await DatabaseManager.instance.database;
      if (!mounted) return;
      setState(() => _loadProgress = 0.5);

      await DatabaseManager.instance.seedCategoryFromJson('main', 'assets/data/dictionary.json');
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

  void _navigateNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background subtle gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F2FD), Colors.white],
              ),
            ),
          ),
          
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/logo_main.png',
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => const Icon(Icons.language, color: Colors.blue, size: 60),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          "SPEECHMATE",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1565C0),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Global Language Platform",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_isPreloading)
            Positioned(
              bottom: 60,
              left: 40,
              right: 40,
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (_, __) => Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _loadProgress,
                          minHeight: 4,
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Preparing your experience...',
                        style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
