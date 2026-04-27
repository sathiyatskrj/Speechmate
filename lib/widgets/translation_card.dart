import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String nicobarese;
  final String english;
  final bool isError;
  final bool searchedNicobarese;
  
  // Speaker
  final bool showSpeaker;
  final VoidCallback? onSpeak; // Renamed from onSpeakerTap
  
  // Favorites & Report
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onReport;

  const TranslationCard({
    super.key,
    required this.nicobarese,
    required this.english,
    this.isError = false,
    this.searchedNicobarese = false,
    this.showSpeaker = false,
    this.onSpeak,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isError ? Colors.redAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isError ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
             BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isError ? "Not Found" : (searchedNicobarese ? "English Translation" : "Nicobarese Translation"),
                style: TextStyle(
                  color: isError ? Colors.redAccent : Colors.cyanAccent,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSpeaker && !isError)
                    IconButton(
                      onPressed: onSpeak,
                      icon: const Icon(Icons.volume_up_rounded, color: Colors.cyanAccent),
                      tooltip: "Pronounce",
                    ),
                  if (onFavoriteToggle != null && !isError)
                    IconButton(
                      onPressed: onFavoriteToggle,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : Colors.white54,
                      ),
                    ),
                  if (onReport != null && !isError)
                    IconButton(
                      onPressed: onReport,
                      icon: const Icon(Icons.flag_outlined, color: Colors.white54),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            nicobarese,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          if (!isError && english.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                english,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ]
        ],
      ),
    );
  }
}
