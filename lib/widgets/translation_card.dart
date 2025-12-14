import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String nicobarese;
  final String english;
  final bool isError;

  // NEW (optional)
  final bool showSpeaker;
  final VoidCallback? onSpeakerTap;

  const TranslationCard({
    super.key,
    required this.nicobarese,
    required this.english,
    this.isError = false,
    this.showSpeaker = false, // default OFF
    this.onSpeakerTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      width: screenSize.width * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔊 + Nicobarese word row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  nicobarese,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: isError ? Colors.redAccent : Colors.black,
                  ),
                ),
              ),

              // Speaker button (ONLY when enabled & not error)
              if (showSpeaker && !isError)
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded),
                  color: Colors.black87,
                  onPressed: onSpeakerTap,
                ),
            ],
          ),

          if (!isError) ...[
            const SizedBox(height: 8),
            Text(
              "English: $english",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
