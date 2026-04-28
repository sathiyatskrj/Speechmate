import 'package:flutter/material.dart';
import 'package:speechmate/widgets/background.dart';

class DialectHeatmapScreen extends StatefulWidget {
  const DialectHeatmapScreen({super.key});

  @override
  State<DialectHeatmapScreen> createState() => _DialectHeatmapScreenState();
}

class _DialectHeatmapScreenState extends State<DialectHeatmapScreen> {
  final List<Map<String, dynamic>> _hotspots = [
    {'name': 'Car Nicobar', 'dialect': 'Pū (Car)', 'speakers': '~29,000', 'top': 0.15, 'left': 0.45, 'color': const Color(0xFFFF5252)},
    {'name': 'Nancowry', 'dialect': 'Central Nicobarese', 'speakers': '~10,000', 'top': 0.45, 'left': 0.55, 'color': const Color(0xFFFFD740)},
    {'name': 'Little Andaman', 'dialect': 'Önge (Rel.)', 'speakers': '~100', 'top': 0.65, 'left': 0.4, 'color': const Color(0xFF69F0AE)},
    {'name': 'Great Andaman', 'dialect': 'Aka-Jeru / Great Andamanese', 'speakers': '<5', 'top': 0.05, 'left': 0.55, 'color': const Color(0xFF40C4FF)},
    {'name': 'Campbell Bay', 'dialect': 'Southern Nicobarese', 'speakers': '~5,000', 'top': 0.85, 'left': 0.6, 'color': const Color(0xFFE040FB)},
  ];

  void _showDialectDetails(Map<String, dynamic> hotspot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: hotspot['color'], width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: hotspot['color'], radius: 8),
                const SizedBox(width: 10),
                Text(hotspot['name'], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            Text("Main Dialect: ${hotspot['dialect']}", style: const TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 5),
            Text("Estimated Speakers: ${hotspot['speakers']}", style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.volume_up),
                    label: const Text("Listen to Greeting"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hotspot['color'],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Island Explorer 🗺️", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Background(colors: [Color(0xFF001529), Color(0xFF00334E)]),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Flutter coded map of Nicobar & Andaman
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.15,
                      child: CustomPaint(
                        painter: _MapPainter(),
                      ),
                    ),
                  ),
                  
                  // Hotspots
                  ..._hotspots.map((spot) {
                    return Positioned(
                      top: constraints.maxHeight * spot['top'],
                      left: constraints.maxWidth * spot['left'],
                      child: GestureDetector(
                        onTap: () => _showDialectDetails(spot),
                        child: _PulseNode(color: spot['color']),
                      ),
                    );
                  }),
                  
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.touch_app, color: Colors.cyanAccent),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              "Tapping hotspots reveals dialect distribution across the archipelago.",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PulseNode extends StatefulWidget {
  final Color color;
  const _PulseNode({required this.color});

  @override
  State<_PulseNode> createState() => _PulseNodeState();
}

class _PulseNodeState extends State<_PulseNode> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 30 * _controller.value + 10,
              height: 30 * _controller.value + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 1 - _controller.value),
              ),
            ),
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // A stylized representation of the Andaman and Nicobar Islands
    Path path = Path();
    
    // North/Middle/South Andaman
    path.moveTo(size.width * 0.55, size.height * 0.05);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.1, size.width * 0.55, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width * 0.52, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.55, size.height * 0.35, size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.3, size.width * 0.45, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.1, size.width * 0.55, size.height * 0.05);

    // Little Andaman
    path.moveTo(size.width * 0.4, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.62, size.width * 0.42, size.height * 0.68);
    path.quadraticBezierTo(size.width * 0.38, size.height * 0.67, size.width * 0.38, size.height * 0.62);
    path.quadraticBezierTo(size.width * 0.38, size.height * 0.58, size.width * 0.4, size.height * 0.6);

    // Car Nicobar
    path.moveTo(size.width * 0.45, size.height * 0.15);
    path.addOval(Rect.fromCircle(center: Offset(size.width * 0.45, size.height * 0.15), radius: size.width * 0.04));

    // Nancowry group
    path.moveTo(size.width * 0.55, size.height * 0.45);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.48, size.width * 0.52, size.height * 0.52);
    path.quadraticBezierTo(size.width * 0.48, size.height * 0.48, size.width * 0.55, size.height * 0.45);

    // Great Nicobar (Campbell Bay)
    path.moveTo(size.width * 0.55, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.65, size.height * 0.85, size.width * 0.6, size.height * 0.95);
    path.quadraticBezierTo(size.width * 0.55, size.height * 0.9, size.width * 0.5, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.8, size.width * 0.55, size.height * 0.8);

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Connective dashed lines for shipping routes or cultural ties
    final dashPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    _drawDashedLine(canvas, Offset(size.width * 0.52, size.height * 0.3), Offset(size.width * 0.45, size.height * 0.15), dashPaint);
    _drawDashedLine(canvas, Offset(size.width * 0.52, size.height * 0.3), Offset(size.width * 0.42, size.height * 0.6), dashPaint);
    _drawDashedLine(canvas, Offset(size.width * 0.42, size.height * 0.6), Offset(size.width * 0.52, size.height * 0.52), dashPaint);
    _drawDashedLine(canvas, Offset(size.width * 0.52, size.height * 0.52), Offset(size.width * 0.55, size.height * 0.8), dashPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const int dashWidth = 5;
    const int dashSpace = 5;
    double startX = p1.dx;
    double startY = p1.dy;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = (Offset(dx, dy)).distance;
    double dashCount = distance / (dashWidth + dashSpace);
    
    double dxStep = dx / dashCount;
    double dyStep = dy / dashCount;
    
    for (int i = 0; i < dashCount.floor(); i++) {
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + dxStep * (dashWidth / (dashWidth + dashSpace)), startY + dyStep * (dashWidth / (dashWidth + dashSpace))),
        paint,
      );
      startX += dxStep;
      startY += dyStep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
