import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/widgets/background.dart';

class MemoryPalaceScreen extends StatefulWidget {
  const MemoryPalaceScreen({super.key});

  @override
  State<MemoryPalaceScreen> createState() => _MemoryPalaceScreenState();
}

class _MemoryPalaceScreenState extends State<MemoryPalaceScreen> {
  final List<Map<String, dynamic>> _villageNodes = [
    {'name': 'Coconut Grove', 'term': 'Nyo-Hóm', 'icon': Icons.park, 'x': 0.1, 'y': 0.4, 'color': Color(0xFF81C784)},
    {'name': 'Fisherman\'s Jetty', 'term': 'Pū-Tōt', 'icon': Icons.anchor, 'x': 0.5, 'y': 0.7, 'color': Color(0xFF64B5F6)},
    {'name': 'Elder\'s Hut', 'term': 'U-Mem', 'icon': Icons.home, 'x': 0.8, 'y': 0.3, 'color': Color(0xFFFFB74D)},
    {'name': 'Sandy Beach', 'term': 'Cō-Pū', 'icon': Icons.waves, 'x': 0.3, 'y': 0.8, 'color': Color(0xFFFFF176)},
    {'name': 'Village Well', 'term': 'Ngō-Inrē', 'icon': Icons.water_drop, 'x': 0.6, 'y': 0.2, 'color': Color(0xFF4FC3F7)},
  ];

  void _showWordDetail(Map<String, dynamic> node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: node['color'])),
        title: Text(node['term'], style: TextStyle(color: node['color'], fontSize: 28, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(node['icon'], size: 80, color: node['color']),
            const SizedBox(height: 20),
            Text("In English: ${node['name']}", style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 10),
            const Text("Spatial memory links this word to the specific location in your community.", 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.volume_up, size: 40, color: Colors.amberAccent), onPressed: () {}),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: node['color'], foregroundColor: Colors.black),
                child: const Text("Got it"),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Memory Palace 🏰", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Background(colors: [Color(0xFF2E7D32), Color(0xFF004D40)]), // Deep deep green
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                   // Large stylised background text
                   const Center(
                     child: Opacity(
                       opacity: 0.05,
                       child: Text("TUHET", style: TextStyle(fontSize: 150, color: Colors.white, fontWeight: FontWeight.bold)),
                     ),
                   ),
                   
                   // Interactive nodes
                   ..._villageNodes.map((node) {
                      return Positioned(
                        top: constraints.maxHeight * node['y'],
                        left: constraints.maxWidth * node['x'],
                        child: GestureDetector(
                           onTap: () => _showWordDetail(node),
                           child: Column(
                             children: [
                               Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: node['color'], width: 2),
                                    boxShadow: [
                                      BoxShadow(color: node['color'].withOpacity(0.2), blurRadius: 10)
                                    ]
                                 ),
                                 child: Icon(node['icon'], color: node['color'], size: 30),
                               ),
                               const SizedBox(height: 5),
                               Text(node['term'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                             ],
                           ).animate().fadeIn(delay: Duration(milliseconds: 200 * _villageNodes.indexOf(node))).scale(),
                        ),
                      );
                   }).toList(),
                ],
              );
            },
          ),
          
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                 color: Colors.black38,
                 borderRadius: BorderRadius.circular(25),
                 border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                children: [
                  Text("Spatial Learning Mode", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("Walk through your village mentally and tap nodes to recall the names of places and objects.", 
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ).animate().slideY(begin: 1, end: 0),
          )
        ],
      ),
    );
  }
}
