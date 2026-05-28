import 'package:flutter/material.dart';
import 'package:speechmate/screens/explorer_shell.dart';
import 'package:speechmate/screens/ga_hub_screen.dart';
import 'package:speechmate/screens/mock_language_screen.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:speechmate/core/app_colors.dart';
import 'package:speechmate/services/progress_service.dart';
import 'package:flutter_animate/flutter_animate.dart';



class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  double? get buttonWidth => 280;
  double? get buttonHeight => 70;

  int _xp = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final stats = await ProgressService().getProgressStats();
    if (mounted) {
      setState(() {
        _xp = stats['studentXP'] ?? 0;
        _streak = stats['dayStreak'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.onboardingStart.withValues(alpha: 0.5), AppColors.onboardingDeep],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ────── GAMIFICATION TOP BAR ──────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Streak Counter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              "$_streak Day${_streak == 1 ? '' : 's'}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideX(begin: -0.2),
                      
                      // XP Counter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.purpleAccent, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              "$_xp XP",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideX(begin: 0.2),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                Text(
                  AppStrings.get('selectLanguage'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Which heritage language do you wish to explore?",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 40),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildLanguageButton(
                          label: "Pū (Car Nicobarese)", 
                          langCode: "nc", 
                          colors: [const Color(0xFFE91E63), const Color(0xFFFF6F00)], 
                          icon: Icons.map,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerShell())),
                        ),
                        _buildLanguageButton(
                          label: "Aka-Jeru (Great Andamanese)", 
                          langCode: "gn", 
                          colors: [const Color(0xFF43A047), const Color(0xFFFDD835)], 
                          icon: Icons.terrain,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GAHubScreen())),
                        ),
                        const SizedBox(height: 20),
                        _buildLanguageButton(
                          label: "Onges", 
                          langCode: "on", 
                          colors: [const Color(0xFF8E24AA), const Color(0xFF1E88E5)], 
                          icon: Icons.water,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MockLanguageScreen(languageName: "Onges"))),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          "*More languages coming soon.",
                          style: TextStyle(fontSize: 12, color: Colors.white54, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton({required String label, required String langCode, required List<Color> colors, required VoidCallback onTap, IconData? icon}) {
    return Column(
      children: [
        TapScale(
          onTap: onTap,
          child: Container(
            width: buttonWidth,
            height: buttonHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (icon != null) Icon(icon, color: Colors.white, size: 28),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 15),
      ],
    );
  }
}
