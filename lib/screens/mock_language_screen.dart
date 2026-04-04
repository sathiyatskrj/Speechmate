import 'package:flutter/material.dart';
import 'package:speechmate/widgets/background.dart';

class MockLanguageScreen extends StatelessWidget {
  final String languageName;

  const MockLanguageScreen({super.key, required this.languageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(languageName),
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
      ),
      body: Background(
        colors: const [Color(0xFF7FFFD4), Color(0xFF00E5FF)],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 30),
                Text(
                  "$languageName is Under Construction!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Our linguists and community partners are actively working on digitizing this beautiful language.\n\nPlease check back in a future update to start learning!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Go Back", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
