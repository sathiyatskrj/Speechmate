import 'package:flutter/material.dart';
import 'package:speechmate/screens/landing_page.dart';
import 'package:speechmate/screens/ga_hub_screen.dart';
import 'package:speechmate/screens/mock_language_screen.dart';
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.studentAccent.withOpacity(0.4), Colors.black],
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
                          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LandingPage())),
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
                          "*More languages coming soon to the hub.",
                          style: TextStyle(fontSize: 12, color: Colors.white54, fontStyle: FontStyle.italic),
                        ),
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
              boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
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
