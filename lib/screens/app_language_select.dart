import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/screens/languages.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import '../widgets/background.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  double? get buttonWidth => 220;
  double? get buttonHeight => 48;

  Future<void> selectLanguage(BuildContext context, String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
    await prefs.setString('language', langCode);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Languages()),
    );
  }

  Widget _buildLanguageButton({required BuildContext context, required String label, required String langCode, required List<Color> colors}) {
    return Column(
      children: [
        TapScale(
          onTap: () => selectLanguage(context, langCode),
          child: Container(
            width: buttonWidth,
            height: buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: const [Color(0xFF7FFFD4), Color(0xFF00E5FF)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Select App Language",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildLanguageButton(context: context, label: "English", langCode: "en", colors: [const Color(0xFFE91E63), const Color(0xFFFF6F00)]),
                    _buildLanguageButton(context: context, label: "हिंदी (Hindi)", langCode: "hi", colors: [const Color(0xFF8E24AA), const Color(0xFF1E88E5)]),
                    _buildLanguageButton(context: context, label: "தமிழ் (Tamil)", langCode: "ta", colors: [const Color(0xFF43A047), const Color(0xFFFDD835)]),
                    _buildLanguageButton(context: context, label: "മലയാളം (Malayalam)", langCode: "ml", colors: [const Color(0xFFE53935), const Color(0xFF43A047)]),
                    _buildLanguageButton(context: context, label: "বাংলা (Bengali)", langCode: "bn", colors: [const Color(0xFF00ACC1), const Color(0xFF5E35B1)]),
                    _buildLanguageButton(context: context, label: "తెలుగు (Telugu)", langCode: "te", colors: [const Color(0xFFFF6F00), const Color(0xFFE91E63)]),
                    const SizedBox(height: 20),
                    const Text(
                      "*UI texts will be updated dynamically in a future update.",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
