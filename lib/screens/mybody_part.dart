import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speechmate/widgets/body_part_buttons.dart';

class BodyPartsScreen extends StatelessWidget {
  BodyPartsScreen({super.key});

  final AudioPlayer _player = AudioPlayer();

  Future<void> playAudio(String path) async {
    await _player.stop();
    await _player.play(AssetSource(path));
  }

  final List<BodyPartItem> bodyParts = [
    BodyPartItem(
      name: 'Head',
      image: 'assets/images/head.png',
      audio: 'audio/body_parts/head.mp3',
    ),
    BodyPartItem(
      name: 'Ear',
      image: 'assets/images/ear.png',
      audio: 'audio/body_parts/ear.mp3',
    ),
    BodyPartItem(
      name: 'Eye',
      image: 'assets/images/eye.png',
      audio: 'audio/body_parts/eye.mp3',
    ),
    BodyPartItem(
      name: 'Hair',
      image: 'assets/images/hair.png',
      audio: 'audio/body_parts/hair.mp3',
    ),
    BodyPartItem(
      name: 'Hand',
      image: 'assets/images/hand.png',
      audio: 'audio/body_parts/hand.mp3',
    ),
    BodyPartItem(
      name: 'Leg',
      image: 'assets/images/legs.png',
      audio: 'audio/body_parts/leg.mp3',
    ),
    BodyPartItem(
      name: 'Mouth',
      image: 'assets/images/mouth.png',
      audio: 'audio/body_parts/mouth.mp3',
    ),
    BodyPartItem(
      name: 'Nose',
      image: 'assets/images/nose.png',
      audio: 'audio/body_parts/nose.mp3',
    ),
    BodyPartItem(
      name: 'Stomach',
      image: 'assets/images/stomach.png',
      audio: 'audio/body_parts/stomach.mp3',
    ),
    BodyPartItem(
      name: 'Foot',
      image: 'assets/images/foot.png',
      audio: 'audio/body_parts/foot.mp3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Body',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5DA9E9),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // MAIN IMAGE
          Expanded(
            flex: 3,
            child: Image.asset(
              'assets/images/body_parts.png',
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 8),

          // BUTTON GRID
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bodyParts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final part = bodyParts[index];
                  return BodyPartButton(
                    item: part,
                    onTap: () => playAudio(part.audio),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
