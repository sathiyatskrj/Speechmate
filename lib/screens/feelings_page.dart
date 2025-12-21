import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/tile_buttons.dart';

class FeelingsPage extends StatelessWidget {
  FeelingsPage({super.key});

  final AudioPlayer _player = AudioPlayer();

  final List<Map<String, String>> natureItems = [
    {"emoji": "😨", "text": "Afraid", "audio": "afraid.mp3"},
    {"emoji": "😡", "text": "Angry", "audio": "angry.mp3"},
    {"emoji": "☺️", "text": "Happy", "audio": "happy.mp3"},
    {"emoji": "🙁", "text": "Sad", "audio": "sad.mp3"},
  ];

  final List<Color> colors = [
    Color(0xFF5DA9E9),
    Color(0xFFE91E63),
    Color(0xFFFF7043),
    Color(0xFF8BC34A),
  ];

  Future<void> _playAudio(String fileName) async {
    await _player.stop();
    await _player.play(AssetSource('audio/feelings/$fileName'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1F6),
      appBar: AppBar(
        title: const Text(
          'Feelings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF7043),
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
