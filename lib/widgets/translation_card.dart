import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String nicobarese;
  final String english;
  final bool isError;
  final VoidCallback? onPlayAudio;

  TranslationCard({
    super.key,
    required this.nicobarese,
    required this.english,
    this.isError = false,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nicobarese,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "English: $english",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          if (onPlayAudio != null)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: onPlayAudio,
            ),
        ],
      ),
    );
  }
}
