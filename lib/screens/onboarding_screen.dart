import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A 4-slide animated onboarding screen for first-time users.
///
/// Uses `has_seen_onboarding` SharedPreferences key to show only once.
/// Premium glassmorphic design matching the existing SpeechMate aesthetic.
class OnboardingScreen extends StatefulWidget {
  final Widget nextScreen;
  const OnboardingScreen({super.key, required this.nextScreen});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  static const _slides = [
    _SlideData(
      emoji: '🌏',
      title: 'Welcome to SpeechMate',
      subtitle: 'Where Language Barriers End',
      description:
          'Learn endangered Nicobarese and Great Andamanese vocabulary — completely offline.',
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    _SlideData(
      emoji: '👆',
      title: 'Tap to Learn',
      subtitle: 'Explore 2,400+ Words',
      description:
          'Tap any card to discover Nicobarese translations with audio pronunciations and emoji cues.',
      gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
    ),
    _SlideData(
      emoji: '🎙️',
      title: 'Speak to Search',
      subtitle: 'On-Device Voice Input',
      description:
          'Use your voice to search words — powered by on-device AI. No internet required.',
      gradient: [Color(0xFFfc5c7d), Color(0xFF6a82fb)],
    ),
    _SlideData(
      emoji: '🎮',
      title: 'Play & Level Up',
      subtitle: 'Learn Through Games',
      description:
          'Earn XP, unlock achievements, and evolve your virtual pet companion through learning!',
      gradient: [Color(0xFFf09819), Color(0xFFedde5d)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _slides[_currentPage].gradient,
              ),
            ),
          ),
          // Page content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        _currentPage == _slides.length - 1 ? '' : 'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) =>
                        _buildSlide(_slides[index], index),
                  ),
                ),
                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicators
                      Row(
                        children: List.generate(
                          _slides.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentPage == i ? 28 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      // Next / Get Started button
                      GestureDetector(
                        onTap: () {
                          if (_currentPage == _slides.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = _currentPage == _slides.length - 1
                                ? 1.0 + (_pulseController.value * 0.05)
                                : 1.0;
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  _currentPage == _slides.length - 1 ? 28 : 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPage == _slides.length - 1
                                      ? "Let's Go!"
                                      : 'Next',
                                  style: TextStyle(
                                    color: _slides[_currentPage].gradient[0],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_currentPage == _slides.length - 1) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.rocket_launch_rounded,
                                      color: _slides[_currentPage].gradient[0],
                                      size: 20),
                                ] else ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: _slides[_currentPage].gradient[0],
                                      size: 18),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_SlideData slide, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating emoji with glassmorphic container
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                    0, -12 * Curves.easeInOut.transform(_floatController.value)),
                child: child,
              );
            },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Center(
                    child: Text(
                      slide.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            slide.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Subtitle pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              slide.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Description
          Text(
            slide.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;

  const _SlideData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
  });
}
