import 'package:flutter/material.dart';
import '../widgets/background.dart';
import '../widgets/button.dart';
import '../widgets/tap_scale.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String selectedRole = ""; // student / teacher

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: [Color(0xFFB3F4FF), Color(0xFF00D1FF),],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              "Welcome to Speechmate",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "your personal bilingual assistant",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 40),
            const Text(
              "Select your role.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // STUDENT BUTTON
            _roleButton(
              title: "STUDENT 🎓",
              selected: selectedRole == "student",
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6F6F),
                  Color(0xFFB03FFF),
                ],
              ),
              onTap: () {
                setState(() => selectedRole = "student");
              },
            ),

            const SizedBox(height: 20),

            // TEACHER BUTTON
            _roleButton(
              title: "TEACHER 🏫",
              selected: selectedRole == "teacher",
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF9F80FF),
                  Color(0xFF6FB8FF),
                ],
              ),
              onTap: () {
                setState(() => selectedRole = "teacher");
              },
            ),

            const Spacer(),

            // NEXT BUTTON
            Center(
              child: NextButton(selectedRole: selectedRole),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _roleButton({
    required String title,
    required bool selected,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 1),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}