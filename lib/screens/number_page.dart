import 'package:flutter/material.dart';
import 'package:speechmate/widgets/number_button.dart';
import 'package:audioplayers/audioplayers.dart';

class NumberPage extends StatelessWidget {
  NumberPage({super.key});

  final AudioPlayer _player = AudioPlayer();

  final List<Color> colors = [
    const Color(0xFF5DA9E9), // 1
    const Color(0xFF8BC34A), // 2
    const Color(0xFFFF9800), // 3
    const Color(0xFFE91E63), // 4
    const Color(0xFF26C6DA), // 5
    const Color(0xFFFFC107), // 6
    const Color(0xFFFF7043), // 7
    const Color(0xFF4DD0E1), // 8
    const Color(0xFF8BC34A), // 9
    const Color(0xFF64B5F6), // 10
  ];

  void _playNumber(int number) async {
    await _player.stop();
    await _player.play(AssetSource('audio/numbers/$number.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1F6),
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Numbers ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              TextSpan(
                text: '1-10',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: 10,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final number = index + 1;
            return NumberButton(
              number: '$number',
              color: colors[index],
              onTap: () => _playNumber(number),
            );
          },
        ),
      ),
    );
  }
}
