import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/screens/languages.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import '../widgets/background.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  double? get buttonWidth => 220;
  double? get buttonHeight => 48;

  Future<void> selectEnglish(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);
    await prefs.setString('language', 'en');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Languages()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: [Color(0xFF7FFFD4), Color(0xFF00E5FF)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Select App Language",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            /// ENGLISH BUTTON
            TapScale(
              onTap: () {
                selectEnglish(context);
              },
              child: Container(
                width: buttonWidth,
                height: buttonHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF6F00)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "ENGLISH",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// HINDI BUTTON (DISABLED)
            Container(
              width: buttonWidth,
              height: buttonHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(133, 233, 30, 98),
                    Color.fromARGB(123, 255, 111, 0),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "HINDI*",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("*Hindi coming soon", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
