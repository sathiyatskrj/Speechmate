import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/tile_buttons.dart';

class NaturePage extends StatelessWidget {
  NaturePage({super.key});

  final AudioPlayer _player = AudioPlayer();

  final List<Map<String, String>> natureItems = [
    {"emoji": "☀️", "text": "Sun", "audio": "sun.mp3"},
    {"emoji": "🌳", "text": "Tree", "audio": "tree.mp3"},
    {"emoji": "🌊", "text": "Sea", "audio": "sea.mp3"},
    {"emoji": "⛰️", "text": "Mountain", "audio": "mountain.mp3"},
    {"emoji": "🏞️", "text": "River", "audio": "river.mp3"},
    {"emoji": "🌸", "text": "Flower", "audio": "flower.mp3"},
    {"emoji": "🌧️", "text": "Rain", "audio": "rain.mp3"},
    {"emoji": "🔥", "text": "Fire", "audio": "fire.mp3"},
    {"emoji": "🌱", "text": "Soil", "audio": "soil.mp3"},
    {"emoji": "☁️", "text": "Cloud", "audio": "cloud.mp3"},
  ];

  final List<Color> colors = [
    Color(0xFF5DA9E9),
    Color(0xFF8BC34A),
    Color(0xFF26C6DA),
    Color(0xFF795548),
    Color(0xFF4FC3F7),
    Color(0xFFE91E63),
    Color(0xFF90A4AE),
    Color(0xFFFF7043),
    Color(0xFF8D6E63),
    Color(0xFF64B5F6),
  ];

  Future<void> _playAudio(String fileName) async {
    await _player.stop();
    await _player.play(AssetSource('audio/nature/$fileName'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1F6),
      appBar: AppBar(
        title: const Text(
          'Nature',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: natureItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final item = natureItems[index];
            return TileButtons(
              emoji: item['emoji']!,
              text: item['text']!,
              color: colors[index],
              onTap: () => _playAudio(item['audio']!),
            );
          },
        ),
      ),
    );
  }
}
