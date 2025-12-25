import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';
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
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final isLocked = level > _currentLevel;
                  final isCompleted = level < _currentLevel;
                  
                  return GestureDetector(
                    onTap: () => _openLevel(level),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.white.withOpacity(0.5) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                           if (!isLocked)
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.2),
                              blurRadius: 15,
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
                                  : (isCompleted ? Colors.green : Colors.blueAccent),
                              gradient: isLocked 
                                  ? null 
                                  : LinearGradient(
                                      colors: isCompleted 
                                          ? [Colors.green, Colors.greenAccent]
                                          : [Colors.blue, Colors.blueAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                            ),
                            child: Icon(
                              isLocked ? Icons.lock : (isCompleted ? Icons.check : Icons.star),
                              color: Colors.white,
                              size: 30,
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
                                    fontWeight: FontWeight.bold,
                                    color: isLocked ? Colors.grey[600] : Colors.black87,
                                  ),
                                ),
                                Text(
                                  isLocked ? "Locked" : (isCompleted ? "Completed" : "Start Learning"),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isLocked ? Colors.grey[500] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLocked)
                             Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: isCompleted ? Colors.green : Colors.blueAccent,
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
