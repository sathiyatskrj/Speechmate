import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// First-launch-only onboarding (3 slides).
/// After completion, sets 'onboarding_done' = true and navigates to nextScreen.
class OnboardingScreen extends StatefulWidget {
  final Widget nextScreen;
  const OnboardingScreen({super.key, required this.nextScreen});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_Slide> _slides = [
    _Slide(
      icon: Icons.wifi_off_rounded,
      title: 'Works Offline',
      body: 'SpeechMate runs entirely on your device. No internet needed — perfect for the Andaman & Nicobar Islands.',
      gradient: [const Color(0xFF0D9488), const Color(0xFF115E59)],
    ),
    _Slide(
      icon: Icons.record_voice_over_rounded,
      title: 'Voice Translation',
      body: 'Speak in English, Hindi, Tamil or Bengali — hear the Nicobarese translation instantly with on-device AI.',
      gradient: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
    ),
    _Slide(
      icon: Icons.diversity_3_rounded,
      title: 'Preserve Heritage',
      body: 'Help document endangered Nicobarese and Great Andamanese languages for future generations.',
      gradient: [const Color(0xFFEC4899), const Color(0xFFBE185D)],
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Skip', style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500,
                )),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: s.gradient),
                            boxShadow: [BoxShadow(color: s.gradient.first.withOpacity(0.4), blurRadius: 30)],
                          ),
                          child: Icon(s.icon, color: Colors.white, size: 50),
                        ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                        const SizedBox(height: 48),
                        Text(s.title, style: GoogleFonts.outfit(
                          fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
                        )).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 16),
                        Text(s.body, style: GoogleFonts.inter(
                          fontSize: 15, color: const Color(0xFF94A3B8), height: 1.6,
                        ), textAlign: TextAlign.center).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots + Button
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(children: List.generate(3, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: _currentPage == i ? const Color(0xFF0D9488) : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ))),
                  // Next / Get Started
                  GestureDetector(
                    onTap: () {
                      if (_currentPage == _slides.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(duration: 300.ms, curve: Curves.easeInOut);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.4), blurRadius: 12)],
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title, body;
  final List<Color> gradient;
  const _Slide({required this.icon, required this.title, required this.body, required this.gradient});
}
