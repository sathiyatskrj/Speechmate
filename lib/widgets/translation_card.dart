import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String nicobarese;
  final String english;
  final bool isError;
  final bool searchedNicobarese;
  final bool showSpeaker;
  final VoidCallback? onSpeakerTap;
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
    this.onSpeakerTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    final String topText = searchedNicobarese ? english : nicobarese;
    final String bottomLabel = searchedNicobarese ? 'Nicobarese' : 'English';
    final String bottomText = searchedNicobarese ? nicobarese : english;

    return Container(
      width: screenWidth * 0.9,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  topText,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 22 : 26,
                    fontWeight: FontWeight.w600,
                    color: isError ? Colors.redAccent : Colors.black,
                  ),
                ),
              ),

              if (showSpeaker && !isError)
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: onSpeakerTap,
                  iconSize: isSmallScreen ? 20 : 24,
                ),

              if (!isError && onFavoriteToggle != null)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFavorite ? Colors.amber : Colors.grey,
                    size: isSmallScreen ? 24 : 28,
                  ),
                  onPressed: onFavoriteToggle,
                ),
            ],
          ),

          if (!isError) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "$bottomLabel: $bottomText",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
                
                if (onReport != null)
                  InkWell(
                    onTap: onReport,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: isSmallScreen ? 14 : 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Report",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: isSmallScreen ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
