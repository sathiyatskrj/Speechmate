import 'package:flutter/material.dart';

class TranslationCard extends StatelessWidget {
  final String nicobarese;
  final String english;
  final bool isError;
  final bool searchedNicobarese;
  
  // Speaker
  final bool showSpeaker;
  final VoidCallback? onSpeakerTap;
  
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
    this.onSpeakerTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width < 400;

    // Responsive font sizes
    final topFontSize = isSmallScreen ? 20.0 : (isMediumScreen ? 23.0 : 26.0);
    final bottomFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
    final cardPadding = isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 20.0);

    final String topText = searchedNicobarese ? english : nicobarese;
    final String bottomLabel = searchedNicobarese ? 'Nicobarese' : 'English';
    final String bottomText = searchedNicobarese ? nicobarese : english;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: screenSize.width * 0.95,
      ),
      padding: EdgeInsets.all(cardPadding),
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
                    fontSize: topFontSize,
                    fontWeight: FontWeight.w600,
                    color: isError ? Colors.redAccent : Colors.black,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),

              if (showSpeaker && !isError)
                IconButton(
                  icon: Icon(Icons.volume_up_rounded, size: isSmallScreen ? 22 : 24),
                  onPressed: onSpeakerTap,
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                ),
              if (onFavoriteToggle != null && !isError)
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                    size: isSmallScreen ? 20 : 22,
                  ),
                  onPressed: onFavoriteToggle,
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                ),
              if (onReport != null && !isError)
                IconButton(
                  icon: Icon(Icons.flag_outlined, size: isSmallScreen ? 18 : 20),
                  onPressed: onReport,
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                ),
            ],
          ),

          if (!isError) ...[
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              "$bottomLabel: $bottomText",
              style: TextStyle(
                fontSize: bottomFontSize,
                color: Colors.black54,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ],
        ],
      ),
    );
  }
}
