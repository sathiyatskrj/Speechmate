import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String nicobarese;
  final String english;
  final bool isError;

  // NEW
  final bool searchedNicobarese;

  // Speaker
  final bool showSpeaker;
  final VoidCallback? onSpeakerTap;

  const TranslationCard({
    super.key,
    required this.nicobarese,
    required this.english,
    this.isError = false,
    this.searchedNicobarese = false, // default: English search
    this.showSpeaker = false,
    this.onSpeakerTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Decide what goes on top & bottom
    final String topText = searchedNicobarese ? english : nicobarese;

    final String bottomLabel = searchedNicobarese ? 'Nicobarese' : 'English';

    final String bottomText = searchedNicobarese ? nicobarese : english;

    return Container(
      width: screenSize.width * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔊 + Top word
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  topText,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: isError ? Colors.redAccent : Colors.black,
                  ),
                ),
              ),

              if (showSpeaker && !isError)
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: onSpeakerTap,
                ),
            ],
          ),

          if (!isError) ...[
            const SizedBox(height: 8),
            Text(
              "$bottomLabel: $bottomText",
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}
