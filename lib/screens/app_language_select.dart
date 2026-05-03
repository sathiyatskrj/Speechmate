import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/screens/languages.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import 'package:speechmate/core/app_colors.dart';
import 'package:speechmate/core/app_strings.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {

  @override
  void initState() {
    super.initState();
  }

  double? get buttonWidth => 280;
  double? get buttonHeight => 70;

  Future<void> selectLanguage(BuildContext context, String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
    await prefs.setString('language', langCode);

    // Reload strings immediately so the next screen reflects the chosen language
    await AppStrings.load();

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Languages()),
    );
  }

  Widget _buildLanguageButton({required BuildContext context, required String label, required String langCode, required List<Color> colors, IconData? icon}) {
    return Column(
      children: [
        TapScale(
          onTap: () => selectLanguage(context, langCode),
          child: Container(
            width: buttonWidth,
            height: buttonHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: colors.first.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (icon != null) Icon(icon, color: Colors.white, size: 28),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
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
                colors: [
                  AppColors.onboardingStart.withValues(alpha: 0.4),
                  AppColors.onboardingDeep,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Choose Your Mother Tongue",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Help us adapt to your community.",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 40),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildLanguageButton(context: context, label: "Pū (Car Nicobarese)", langCode: "nc", colors: [const Color(0xFF00796B), const Color(0xFF004D40)], icon: Icons.map),
                        _buildLanguageButton(context: context, label: "Aka-Jeru (Great Andamanese)", langCode: "gn", colors: [const Color(0xFFE64A19), const Color(0xFFD84315)], icon: Icons.terrain),
                        const SizedBox(height: 30),
                        const Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                              Expanded(child: Divider(color: Colors.white24, indent: 40, endIndent: 20)),
                              Text("Regional", style: TextStyle(color: Colors.white54, fontSize: 12)),
                              Expanded(child: Divider(color: Colors.white24, indent: 20, endIndent: 40)),
                           ]
                        ),
                        const SizedBox(height: 30),
                        _buildLanguageButton(context: context, label: "English", langCode: "en", colors: [const Color(0xFF455A64), const Color(0xFF263238)]),
                        _buildLanguageButton(context: context, label: "हिंदी (Hindi)", langCode: "hi", colors: [const Color(0xFF455A64), const Color(0xFF263238)]),
                        _buildLanguageButton(context: context, label: "தமிழ் (Tamil)", langCode: "ta", colors: [const Color(0xFF455A64), const Color(0xFF263238)]),
                        _buildLanguageButton(context: context, label: "മലയാളം (Malayalam)", langCode: "ml", colors: [const Color(0xFF455A64), const Color(0xFF263238)]),
                        _buildLanguageButton(context: context, label: "తెలుగు (Telugu)", langCode: "te", colors: [const Color(0xFF455A64), const Color(0xFF263238)]),
                        _buildLanguageButton(context: context, label: "বাংলা (Bengali)", langCode: "bn", colors: [const Color(0xFF455A64), const Color(0xFF263238)]),
                        const SizedBox(height: 40),
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
}
