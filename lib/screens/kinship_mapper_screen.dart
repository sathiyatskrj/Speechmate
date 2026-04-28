import 'package:flutter/material.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/widgets/background.dart';

class KinshipMapperScreen extends StatefulWidget {
  const KinshipMapperScreen({super.key});

  @override
  State<KinshipMapperScreen> createState() => _KinshipMapperScreenState();
}

class _KinshipMapperScreenState extends State<KinshipMapperScreen> {
  final DatabaseManager _db = DatabaseManager.instance;
  final FlutterTts _tts = FlutterTts();
  List<Map<String, dynamic>> _terms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadTerms() async {
    final results = await _db.queryAll('kinship');
    if (!mounted) return;
    setState(() {
      _terms = results;
      _isLoading = false;
    });
  }

  Future<void> _playTerm(String term) async {
    await _tts.speak(term);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Kinship Mapper (Tuhet) 🌳", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Background(colors: [Color(0xFF3E2723), Color(0xFF1B5E20)]),
          SafeArea(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
              : InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 2,
                    height: MediaQuery.of(context).size.height * 1.5,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background connecting lines
                        CustomPaint(
                          size: const Size(double.infinity, double.infinity),
                          painter: KinshipTreePainter(),
                        ),
                        
                        // Interactive Nodes positioned in a tree
                        Positioned(top: 100, child: _buildNode('Elder (Mem)', 'Grandparents', 'mem')),
                        Positioned(top: 250, left: MediaQuery.of(context).size.width * 0.5, child: _buildNode('Parent (Yom)', 'Father/Mother', 'parent')),
                        Positioned(top: 250, right: MediaQuery.of(context).size.width * 0.5, child: _buildNode('Spouse (Piha)', 'Partner', 'spouse')),
                        Positioned(top: 400, child: _buildNode('Self', 'You', null, isSelf: true)),
                        Positioned(top: 550, left: MediaQuery.of(context).size.width * 0.4, child: _buildNode('Younger (Kahem)', 'Siblings', 'younger_sibling')),
                        Positioned(top: 550, right: MediaQuery.of(context).size.width * 0.4, child: _buildNode('Child (Kun)', 'Next Gen', 'child')),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(String title, String subtitle, String? relKey, {bool isSelf = false}) {
    final termData = relKey != null 
        ? _terms.firstWhere((t) => t['rel_key'] == relKey, orElse: () => {})
        : null;
    
    return GestureDetector(
      onTap: () {
        if (termData != null && termData['native_term'] != null) {
          _playTerm(termData['native_term']);
          _showTermDetail(termData);
        }
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelf ? Colors.amberAccent : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelf ? Colors.orange : Colors.white24, width: 2),
          boxShadow: [
            if (isSelf) BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 15)
          ],
        ),
        child: Column(
          children: [
            Icon(
              isSelf ? Icons.person : Icons.people_outline,
              color: isSelf ? Colors.black : Colors.amberAccent,
            ),
            const SizedBox(height: 8),
            Text(
              termData?['native_term'] ?? title,
              style: TextStyle(
                color: isSelf ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              termData?['english_label'] ?? subtitle,
              style: TextStyle(
                color: isSelf ? Colors.black54 : Colors.white54,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().scale(delay: 200.ms),
    );
  }

  void _showTermDetail(Map<String, dynamic> term) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: Text(term['native_term'], style: const TextStyle(color: Colors.amberAccent, fontSize: 24, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("In English: ${term['english_label']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(term['description'], style: const TextStyle(color: Colors.white70, height: 1.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.amberAccent),
            onPressed: () => _playTerm(term['native_term']),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it", style: TextStyle(color: Colors.cyanAccent)),
          )
        ],
      ),
    );
  }
}

/// Custom Canvas Painter to draw dynamic, glowing connection lines between kinship nodes
class KinshipTreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final centerX = size.width / 2;
    
    // Elder to Self
    canvas.drawLine(Offset(centerX, 150), Offset(centerX, 400), paint);
    
    // Parent to Self
    canvas.drawLine(Offset(centerX - 100, 300), Offset(centerX, 400), paint);
    
    // Spouse to Self
    canvas.drawLine(Offset(centerX + 100, 300), Offset(centerX, 400), paint);
    
    // Self to Younger
    canvas.drawLine(Offset(centerX, 450), Offset(centerX - 80, 550), paint);
    
    // Self to Child
    canvas.drawLine(Offset(centerX, 450), Offset(centerX + 80, 550), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
