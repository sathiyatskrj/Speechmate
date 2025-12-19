import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class NatureScreen extends StatelessWidget {
  const NatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AudioService audioService = AudioService();

    final List<Map<String, dynamic>> natureItems = [
      {
        "word": "Grass",
        "emoji": "🌱",
      },
      {
        "word": "Leaf",
        "emoji": "🍃",
      },
      {
        "word": "Tree",
        "emoji": "🌳",
        "audio": "assets/audio/nature/tree.mp3",
      },
      {
        "word": "Forest",
        "emoji": "🌲",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nature"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: natureItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = natureItems[index];

            return InkWell(
              onTap: () {
                if (item['audio'] != null) {
                  audioService.playAsset(item['audio']);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['emoji'],
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['word'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item['audio'] != null)
                      const Icon(Icons.volume_up, size: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
