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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width < 400;
    
    // Responsive font size
    final textFontSize = isSmallScreen ? 16.0 : (isMediumScreen ? 18.0 : 20.0);
    final horizontalPadding = isSmallScreen ? 10.0 : 15.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isSmallScreen ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: textFontSize,
                height: 1.3,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: Colors.blue,
              size: iconSize,
            ),
            onPressed: onPlay,
            padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
