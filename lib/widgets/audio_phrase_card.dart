import 'package:flutter/material.dart';

class AudioPhraseCard extends StatelessWidget {
  final String text;
  final VoidCallback onPlay;

  const AudioPhraseCard({
    super.key,
    required this.text,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 20),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.blue),
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}
