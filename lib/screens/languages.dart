import 'package:flutter/material.dart';
import 'package:speechmate/screens/student_dash.dart';
import 'package:speechmate/screens/ga_hub_screen.dart';
import 'package:speechmate/screens/mock_language_screen.dart';
import 'package:speechmate/screens/document_translation_hub.dart';
import 'package:speechmate/screens/chat_translate_screen.dart';
import 'package:speechmate/screens/beta_chat_screen.dart';
import 'package:speechmate/screens/voice_translator_screen.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:speechmate/core/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';



class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  double? get buttonWidth => 280;
  double? get buttonHeight => 70;


  @override
  void initState() {
    super.initState();
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
                const SizedBox(height: 40),
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
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentDash())),
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

                        const SizedBox(height: 30),

                        // ────── TRANSLATION TOOLS SECTION ──────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            children: [
                              const Expanded(child: Divider(color: Colors.white24)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "🛠️ Translation Tools",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Colors.white24)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Document Translator Hub
                        _buildToolButton(
                          label: "Document Translator",
                          icon: Icons.auto_stories_rounded,
                          colors: [const Color(0xFF00BCD4), const Color(0xFF0097A7)],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentTranslationHub())),
                        ),

                        // Text Translator (Chat & Translate)
                        _buildToolButton(
                          label: "Text Translator",
                          icon: Icons.translate_rounded,
                          colors: [const Color(0xFFFF7043), const Color(0xFFE64A19)],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatTranslateScreen())),
                        ),

                        // Voice Translator
                        _buildToolButton(
                          label: "Voice Translator",
                          icon: Icons.record_voice_over_rounded,
                          colors: [const Color(0xFFEC407A), const Color(0xFFAD1457)],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceTranslatorScreen())),
                        ),

                        // Dialect Radar (Beta Chat)
                        _buildToolButton(
                          label: "Dialect Radar (βeta)",
                          icon: Icons.forum_rounded,
                          colors: [const Color(0xFF7C4DFF), const Color(0xFF536DFE)],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BetaChatScreen(isStudent: false))),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          "*More languages and tools coming soon.",
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

  Widget _buildToolButton({required String label, required IconData icon, required List<Color> colors, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 5),
      child: TapScale(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
    );
  }
}
