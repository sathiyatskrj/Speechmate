import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/widgets/background.dart';

class DialectHeatmapScreen extends StatefulWidget {
  const DialectHeatmapScreen({super.key});

  @override
  State<DialectHeatmapScreen> createState() => _DialectHeatmapScreenState();
}

class _DialectHeatmapScreenState extends State<DialectHeatmapScreen> {
  final List<Map<String, dynamic>> _hotspots = [
    {'name': 'Car Nicobar', 'dialect': 'Pū (Car)', 'speakers': '~29,000', 'top': 0.15, 'left': 0.45, 'color': Color(0xFFFF5252)},
    {'name': 'Nancowry', 'dialect': 'Central Nicobarese', 'speakers': '~10,000', 'top': 0.45, 'left': 0.55, 'color': Color(0xFFFFD740)},
    {'name': 'Little Andaman', 'dialect': 'Önge (Rel.)', 'speakers': '~100', 'top': 0.65, 'left': 0.4, 'color': Color(0xFF69F0AE)},
    {'name': 'Great Andaman', 'dialect': 'Aka-Jeru / Great Andamanese', 'speakers': '<5', 'top': 0.05, 'left': 0.55, 'color': Color(0xFF40C4FF)},
    {'name': 'Campbell Bay', 'dialect': 'Southern Nicobarese', 'speakers': '~5,000', 'top': 0.85, 'left': 0.6, 'color': Color(0xFFE040FB)},
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
                  // Stylized Map Placeholder (Real implementation would use a SVG/Image)
                  Center(
                    child: Opacity(
                      opacity: 0.2,
                      child: Icon(Icons.map, size: constraints.maxWidth * 0.8, color: Colors.cyanAccent),
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
                  }).toList(),
                  
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
                color: widget.color.withOpacity(1 - _controller.value),
              ),
            ),
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
