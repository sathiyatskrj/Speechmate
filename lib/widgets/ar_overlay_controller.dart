import 'package:flutter/material.dart';

class TranslatedTextBlock {
  final Rect rect;
  final String original;
  final String translation;

  TranslatedTextBlock({required this.rect, required this.original, required this.translation});
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

    for (var block in blocks) {
      // Scale bounding box to screen dimensions
      final double left = block.rect.left * scaleX;
      final double top = block.rect.top * scaleY;
      final double width = block.rect.width * scaleX;
      final double height = block.rect.height * scaleY;
      
      final Rect scaledRect = Rect.fromLTWH(left, top, width, height);

      // Draw background box
      final Paint bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)), bgPaint);

      // Draw border
      final Paint borderPaint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)), borderPaint);

      // Draw Text
      final TextSpan span = TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        text: block.translation,
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout(minWidth: width, maxWidth: width);
      
      // Center vertically within the block
      final double textY = top + (height - tp.height) / 2;
      tp.paint(canvas, Offset(left, textY));
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
