import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';
import '../services/progress_service.dart';
import 'level_learning_screen.dart';
import '../widgets/background.dart';

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
        const SnackBar(content: Text("Complete previous levels to unlock this one!")),
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
      appBar: AppBar(
        title: const Text("Teacher Certification Path"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Background(
        colors: const [Color(0xFF2E3192), Color(0xFF1BFFFF)], // Deep Blue to Cyan
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final isLocked = level > _currentLevel;
                  final isCompleted = level < _currentLevel;
                  final isCurrent = level == _currentLevel;
                  
                  return GestureDetector(
                    onTap: () => _openLevel(level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.white.withOpacity(0.5) : Colors.white,
                        borderRadius: BorderRadius.circular(25), // Softer corners
                        border: isCurrent ? Border.all(color: Colors.amber, width: 3) : null,
                        boxShadow: [
                           if (!isLocked)
                            BoxShadow(
                              color: isCurrent ? Colors.amber.withOpacity(0.4) : Colors.blueAccent.withOpacity(0.2),
                              blurRadius: isCurrent ? 20 : 15,
                              offset: const Offset(0, 5),
                            )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLocked 
                                  ? Colors.grey[400] 
                                  : (isCompleted ? Colors.green : Colors.amber),
                              gradient: isLocked 
                                  ? null 
                                  : LinearGradient(
                                      colors: isCompleted 
                                          ? [Colors.green, Colors.greenAccent]
                                          : [Colors.orange, Colors.amber],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              boxShadow: [
                                  if (!isLocked)
                                    BoxShadow(
                                        color: (isCompleted ? Colors.green : Colors.amber).withOpacity(0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4)
                                    )
                              ]
                            ),
                            child: Icon(
                              isLocked ? Icons.lock : (isCompleted ? Icons.check : Icons.play_arrow_rounded),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Level $level",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
                                    color: isLocked ? Colors.grey[600] : Colors.black87,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                    children: [
                                        if (isCurrent) 
                                            const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.star, size: 16, color: Colors.amber)),
                                        Text(
                                          isLocked ? "Locked" : (isCompleted ? "Completed" : "Current Mission"),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                            color: isLocked ? Colors.grey[500] : (isCurrent ? Colors.amber[800] : Colors.green),
                                          ),
                                        ),
                                    ],
                                )
                              ],
                            ),
                          ),
                          if (!isLocked)
                             Icon(
                               Icons.arrow_forward_ios_rounded,
                               color: isCompleted ? Colors.green : Colors.amber,
                               size: 20,
                             ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
