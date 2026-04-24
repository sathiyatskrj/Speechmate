import 'dart:math';
import 'package:flutter/material.dart';

class TranslatedTextBlock {
  final Rect rect;
  final String original;
  final String translation;
  final double confidence;

  TranslatedTextBlock({
    required this.rect,
    required this.original,
    required this.translation,
    this.confidence = 1.0,
  });
}

class LiveTextOverlayPainter extends CustomPainter {
  final List<TranslatedTextBlock> blocks;
  final Size imageSize;
  final Size screenSize;

  LiveTextOverlayPainter({required this.blocks, required this.imageSize, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      // Scale bounding box to screen dimensions
      final double left = block.rect.left * scaleX;
      final double top = block.rect.top * scaleY;
      final double width = max(block.rect.width * scaleX, 60);
      final double height = max(block.rect.height * scaleY, 30);
      
      final Rect scaledRect = Rect.fromLTWH(left, top, width, height);

      // Confidence-based color
      final Color accentColor = block.confidence >= 0.8
          ? Colors.cyanAccent
          : block.confidence >= 0.5
              ? Colors.amberAccent
              : Colors.orangeAccent;

      // Draw background box with rounded corners
      final Paint bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.75)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)), bgPaint);

      // Draw border with confidence-based color
      final Paint borderPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 2.5 : 1.5;
      canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)), borderPaint);

      // Draw translated text
      final TextSpan translationSpan = TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: i == 0 ? 15 : 13,
          fontWeight: FontWeight.bold,
        ),
        text: block.translation,
      );
      final TextPainter tp = TextPainter(
        text: translationSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout(minWidth: width, maxWidth: width);
      
      // Center vertically within the block
      final double textY = top + (height - tp.height) / 2;
      tp.paint(canvas, Offset(left, textY));

      // Draw small original text label above box
      final TextSpan origSpan = TextSpan(
        style: TextStyle(
          color: accentColor.withOpacity(0.8),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
        text: block.original,
      );
      final TextPainter origTp = TextPainter(
        text: origSpan,
        textDirection: TextDirection.ltr,
      );
      origTp.layout(maxWidth: width);
      final double origY = (top - origTp.height - 3).clamp(0, size.height);
      origTp.paint(canvas, Offset(left + 4, origY));
    }
  }

  @override
  bool shouldRepaint(LiveTextOverlayPainter oldDelegate) => true;
}

/// A dedicated widget to handle AR camera overlay logic.
class AROverlayController extends StatelessWidget {
  final List<TranslatedTextBlock> liveBlocks;
  final Size imageSize;
  final Size screenSize;

  const AROverlayController({
    super.key,
    required this.liveBlocks,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    if (liveBlocks.isEmpty) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: CustomPaint(
        painter: LiveTextOverlayPainter(
          blocks: liveBlocks,
          imageSize: imageSize,
          screenSize: screenSize,
        ),
      ),
    );
  }
}
