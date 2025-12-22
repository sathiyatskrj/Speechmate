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
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width < 400;

    // Responsive font sizes
    final topFontSize = isSmallScreen ? 20.0 : (isMediumScreen ? 22.0 : 26.0);
    final bottomFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
    final cardPadding = isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 20.0);

    // Decide what goes on top & bottom
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
          // 🔊 + Top word
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
                    height: 1.2,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),

              if (showSpeaker && !isError)
                IconButton(
                  icon: Icon(
                    Icons.volume_up_rounded,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  onPressed: onSpeakerTap,
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                  constraints: const BoxConstraints(),
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
                height: 1.3,
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
