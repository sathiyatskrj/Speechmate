import 'package:flutter/material.dart';
import '../widgets/background.dart';

class VoiceVaultScreen extends StatelessWidget {
  const VoiceVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Vault 🎙️"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Background(
        colors: const [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, size: 100, color: Colors.white54),
              const SizedBox(height: 20),
              const Text(
                "Preserve a Word",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Record native pronunciations here.\n(Coming Soon)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.radio_button_checked), 
                label: const Text("Start Recording"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
