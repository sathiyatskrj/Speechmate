import 'package:flutter/material.dart';
import 'package:speechmate/screens/landing_page.dart';
import 'package:speechmate/screens/mock_language_screen.dart';
import 'package:speechmate/widgets/background.dart';
import 'package:speechmate/widgets/tap_scale.dart';

class Languages extends StatelessWidget {
  const Languages({super.key});

  double? get buttonWidth => 220;
  double? get buttonHeight => 48;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: const [Color(0xFF7FFFD4), Color(0xFF00E5FF)],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Select a Language to translate/learn",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            /// NICO BUTTON
            TapScale(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                );
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
                  "Nicobarese",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// MORE BUTTON (DISABLED)
            /// ONGES BUTTON
            TapScale(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MockLanguageScreen(languageName: "Onges")),
                );
              },
              child: Container(
                width: buttonWidth,
                height: buttonHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E24AA), Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Onges",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// GREAT ANDAMANESE BUTTON
            TapScale(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MockLanguageScreen(languageName: "Great Andamanese")),
                );
              },
              child: Container(
                width: buttonWidth,
                height: buttonHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43A047), Color(0xFFFDD835)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Great Andamanese",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "*More languages coming soon",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
