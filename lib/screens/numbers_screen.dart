import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class NumbersScreen extends StatelessWidget {
  const NumbersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    final numbers = [
      {"num": "1", "audio": "assets/audio/numbers/one.mp3"},
      {"num": "2", "audio": "assets/audio/numbers/two.mp3"},
      {"num": "3", "audio": "assets/audio/numbers/three.mp3"},
      {"num": "4", "audio": "assets/audio/numbers/four.mp3"},
      {"num": "5", "audio": "assets/audio/numbers/five.mp3"},
      {"num": "6", "audio": "assets/audio/numbers/six.mp3"},
      {"num": "7", "audio": "assets/audio/numbers/seven.mp3"},
      {"num": "8", "audio": "assets/audio/numbers/eight.mp3"},
      {"num": "9", "audio": "assets/audio/numbers/nine.mp3"},
      {"num": "10", "audio": "assets/audio/numbers/ten.mp3"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Numbers")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: numbers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final item = numbers[index];
          return InkWell(
            onTap: () => audioService.playAsset(item['audio']!),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  item['num']!,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
