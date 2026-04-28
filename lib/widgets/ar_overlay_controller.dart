import 'dart:math';
import 'package:flutter/material.dart';

class TranslatedTextBlock {
  final Rect rect;
  final String original;
  final String translation;
  final double confidence;
  final bool isObject;
  final Map<String, String>? info;

  TranslatedTextBlock({
    required this.rect,
    required this.original,
    required this.translation,
    this.confidence = 1.0,
    this.isObject = false,
    this.info,
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

      if (block.isObject) {
         _drawJarvisHud(canvas, scaledRect, block, size);
      } else {
         _drawNormalText(canvas, scaledRect, block, i, size);
      }
    }
  }

  void _drawJarvisHud(Canvas canvas, Rect rect, TranslatedTextBlock block, Size size) {
     const Color hudColor = Colors.cyanAccent;
     
     // 1. Draw corner brackets
     final Paint bracketPaint = Paint()
       ..color = hudColor
       ..style = PaintingStyle.stroke
       ..strokeWidth = 3.0;
       
     const double cornerLength = 20.0;
     
     // Top-Left
     canvas.drawPath(Path()..moveTo(rect.left, rect.top + cornerLength)..lineTo(rect.left, rect.top)..lineTo(rect.left + cornerLength, rect.top), bracketPaint);
     // Top-Right
     canvas.drawPath(Path()..moveTo(rect.right - cornerLength, rect.top)..lineTo(rect.right, rect.top)..lineTo(rect.right, rect.top + cornerLength), bracketPaint);
     // Bottom-Left
     canvas.drawPath(Path()..moveTo(rect.left, rect.bottom - cornerLength)..lineTo(rect.left, rect.bottom)..lineTo(rect.left + cornerLength, rect.bottom), bracketPaint);
     // Bottom-Right
     canvas.drawPath(Path()..moveTo(rect.right, rect.bottom - cornerLength)..lineTo(rect.right, rect.bottom)..lineTo(rect.right - cornerLength, rect.bottom), bracketPaint);

     // 2. Center Crosshair
     final Offset center = rect.center;
     final Paint crosshairPaint = Paint()
       ..color = hudColor.withValues(alpha: 0.5)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 1.0;
     canvas.drawLine(Offset(center.dx - 10, center.dy), Offset(center.dx + 10, center.dy), crosshairPaint);
     canvas.drawLine(Offset(center.dx, center.dy - 10), Offset(center.dx, center.dy + 10), crosshairPaint);
     canvas.drawCircle(center, 4.0, crosshairPaint);

     // 3. Info Panel Line
     final double lineEndX = rect.right + 40;
     final double lineEndY = rect.top - 20;
     
     final Paint linePaint = Paint()
       ..color = hudColor.withValues(alpha: 0.7)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 1.5;
       
     canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right + 20, rect.top - 20), linePaint);
     canvas.drawLine(Offset(rect.right + 20, rect.top - 20), Offset(lineEndX + 100, lineEndY), linePaint);

     // 4. Info Panel Background
     final Rect infoRect = Rect.fromLTWH(lineEndX, lineEndY - 80, 140, 120);
     final Paint bgPaint = Paint()
       ..color = Colors.black87
       ..style = PaintingStyle.fill;
     canvas.drawRect(infoRect, bgPaint);
     
     final Paint infoBorderPaint = Paint()
       ..color = hudColor.withValues(alpha: 0.5)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 1.0;
     canvas.drawRect(infoRect, infoBorderPaint);

     // 5. Text Drawing
     double currentY = infoRect.top + 5;
     
     _drawText(canvas, "TARGET: ${block.original.toUpperCase()}", lineEndX + 5, currentY, hudColor, 10, true);
     currentY += 15;
     _drawText(canvas, "TR: ${block.translation.toUpperCase()}", lineEndX + 5, currentY, Colors.white, 11, true);
     currentY += 15;
     
     if (block.info != null) {
       for (var entry in block.info!.entries) {
          if (currentY > infoRect.bottom - 15) break;
          String text = "${entry.key.toUpperCase()}: ${entry.value}";
          if (text.length > 20) text = "${text.substring(0, 18)}...";
          _drawText(canvas, text, lineEndX + 5, currentY, hudColor.withValues(alpha: 0.8), 9, false);
          currentY += 12;
       }
     }
  }

  void _drawText(Canvas canvas, String text, double x, double y, Color color, double fontSize, bool bold) {
     final TextSpan span = TextSpan(
       style: TextStyle(
         color: color,
         fontSize: fontSize,
         fontWeight: bold ? FontWeight.bold : FontWeight.normal,
         fontFamily: 'Courier', // Monospace for HUD look
       ),
       text: text,
     );
     final TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
     tp.layout();
     tp.paint(canvas, Offset(x, y));
  }

  void _drawNormalText(Canvas canvas, Rect scaledRect, TranslatedTextBlock block, int i, Size size) {
      // Confidence-based color
      final Color accentColor = block.confidence >= 0.8
          ? Colors.cyanAccent
          : block.confidence >= 0.5
              ? Colors.amberAccent
              : Colors.orangeAccent;

      // Draw background box with rounded corners
      final Paint bgPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.75)
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
      tp.layout(minWidth: scaledRect.width, maxWidth: scaledRect.width);
      
      // Center vertically within the block
      final double textY = scaledRect.top + (scaledRect.height - tp.height) / 2;
      tp.paint(canvas, Offset(scaledRect.left, textY));

      // Draw small original text label above box
      final TextSpan origSpan = TextSpan(
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.8),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
        text: block.original,
      );
      final TextPainter origTp = TextPainter(
        text: origSpan,
        textDirection: TextDirection.ltr,
      );
      origTp.layout(maxWidth: scaledRect.width);
      final double origY = (scaledRect.top - origTp.height - 3).clamp(0, size.height);
      origTp.paint(canvas, Offset(scaledRect.left + 4, origY));
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
