import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String english;
  final String nicobarese;
  final bool isError;
  final VoidCallback? onPlayAudio;

  const TranslationCard({
    super.key,
    required this.english,
    required this.nicobarese,
    required this.isError,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              english,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    nicobarese,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isError ? Colors.red : Colors.black,
                    ),
                  ),
                ),
                if (onPlayAudio != null)
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: onPlayAudio,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
