import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/progress_service.dart';
import 'level_learning_screen.dart';
import '../widgets/background.dart';
import 'dart:math';

class TeacherLevelsScreen extends StatefulWidget {
  const TeacherLevelsScreen({super.key});

  @override
  State<TeacherLevelsScreen> createState() => _TeacherLevelsScreenState();
}

class _TeacherLevelsScreenState extends State<TeacherLevelsScreen> {
  final ProgressService _progressService = ProgressService();
  int _currentLevel = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final level = await _progressService.getTeacherLevel();
    if (mounted) {
      setState(() {
        _currentLevel = level;
        _isLoading = false;
      });
    }
  }

  void _openLevel(int level) {
    if (level > _currentLevel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete previous neurons to activate this pathway!")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelLearningScreen(level: level),
      ),
    ).then((_) => _loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Road Map to Learn Nicobarese"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Background(
        colors: const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], // Deep Space/Bio Dark
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Stack(
                      children: [
                        // The Axon (Connection Path)
                        CustomPaint(
                          size: Size(constraints.maxWidth, 1200), // Approx height for 10 items
                          painter: NeuralPathPainter(totalLevels: 10),
                        ),
                        
                        // The Neurons (Levels)
                        Padding(
                          padding: const EdgeInsets.only(top: 100, bottom: 50),
                          child: Column(
                            children: List.generate(10, (index) {
                                final level = index + 1;
                                return _buildNeuron(level, constraints.maxWidth);
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                }
            ),
      ),
    );
  }

  Widget _buildNeuron(int level, double width) {
    final isLocked = level > _currentLevel;
    final isCompleted = level < _currentLevel;
    final isCurrent = level == _currentLevel;
    
    // Zigzag alignment
    final double offset = (level % 2 == 0) ? 50 : -50;
    
    return Container(
      height: 120, // Spacing
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: GestureDetector(
          onTap: () => _openLevel(level),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocked ? Colors.grey[800] : (isCurrent ? Colors.cyan : Colors.greenAccent),
                  boxShadow: [
                    if (!isLocked)
                      BoxShadow(
                        color: (isCurrent ? Colors.cyan : Colors.green).withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                  ],
                  border: Border.all(
                      color: Colors.white.withOpacity(isLocked ? 0.2 : 0.8),
                      width: isCurrent ? 3 : 1
                  ),
                ),
                child: Center(
                  child: isConvertedText(level, isLocked, isCompleted),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1), 
                  end: isCurrent ? const Offset(1.1, 1.1) : const Offset(1, 1),
                  duration: const Duration(seconds: 2), 
                  curve: Curves.easeInOut
              ), // Breathing effect for Biology Engine
              
              const SizedBox(height: 5),
              Text(
                "Level $level",
                style: TextStyle(
                  color: isLocked ? Colors.white30 : Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [if (!isLocked) const Shadow(color: Colors.cyan, blurRadius: 10)]
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * level)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget isConvertedText(int level, bool isLocked, bool isCompleted) {
      if (isLocked) return const Icon(Icons.lock, color: Colors.white30);
      if (isCompleted) return const Icon(Icons.check, color: Colors.white);
      return Text("$level", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white));
  }
}

class NeuralPathPainter extends CustomPainter {
  final int totalLevels;
  
  NeuralPathPainter({required this.totalLevels});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Start top center (approx where first item is)
    double startX = size.width / 2 - 50; // Level 1 offset
    double startY = 140; // Level 1 vertical center approx (100 padding + 40 half height)
    
    path.moveTo(startX, startY);

    for (int i = 1; i < totalLevels; i++) {
        // Next point
        double nextX = size.width / 2 + ((i + 1) % 2 == 0 ? 50 : -50);
        double nextY = startY + 120; // 120 item height
        
        // Control points for curvy biology look
        double cp1X = startX;
        double cp1Y = startY + 60;
        double cp2X = nextX;
        double cp2Y = nextY - 60;
        
        path.cubicTo(cp1X, cp1Y, cp2X, cp2Y, nextX, nextY);
        
        startX = nextX;
        startY = nextY;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
