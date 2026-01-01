import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/dictionary_service.dart';
import '../widgets/background.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

class LevelLearningScreen extends StatefulWidget {
  final int level;
  const LevelLearningScreen({super.key, required this.level});

  @override
  State<LevelLearningScreen> createState() => _LevelLearningScreenState();
}

enum LearningStep { learn, quiz }

class _LevelLearningScreenState extends State<LevelLearningScreen> with SingleTickerProviderStateMixin {
  final DictionaryService _dictionaryService = DictionaryService();
  final ProgressService _progressService = ProgressService();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  List<Map<String, dynamic>> _words = [];
  bool _isLoading = true;
  
  // Game State
  int _currentIndex = 0;
  LearningStep _currentStep = LearningStep.learn;
  bool _quizAnswered = false;
  bool _quizCorrect = false;
  List<String> _quizOptions = [];
  
  // Animations
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0, end: 10).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _loadWords();
  }
  
  @override
  void dispose() {
    _shakeController.dispose();
    _audioPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final words = await _dictionaryService.getWordsForLevel(widget.level);
    if (mounted) {
      setState(() {
        _words = words;
        _isLoading = false;
      });
      _startLearnStep();
    }
  }

  Future<void> _playWordAudio(String word) async {
    // 1. Try playing asset file specific to word (Game-like quality)
    try {
      // Assuming filenames are lowercase and spaces replaced by underscores, e.g. "Good Morning" -> "good_morning.mp3"
      final filename = word.toLowerCase().replaceAll(' ', '_');
      // We will try to play from specific words folder, falling back to TTS if fails
      // Note: User said they will provide audio. For now we try to play.
      // If the file doesn't exist, audioplayers usually throws or logs error. 
      // We'll catch and fallback to TTS.
      // Since we don't know exact path, we'll try 'audio/words/' first.
      await _audioPlayer.play(AssetSource('audio/words/$filename.mp3'));
    } catch (e) {
      // 2. Fallback to TTS (Robot voice)
      debugPrint("Audio file not found for $word, using TTS. Error: $e");
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.speak(word);
    }
  }

  void _playSoundEffect(bool isCorrect) async {
      try {
          final file = isCorrect ? 'audio/success.mp3' : 'audio/error.mp3';
          // If these files don't exist yet, this might fail silently or log error
          // We assume user will add them or we will add them later. 
          // For now, let's just try. 
          await _sfxPlayer.play(AssetSource(file));
      } catch (_) {}
  }

  void _startLearnStep() {
    setState(() {
       _currentStep = LearningStep.learn;
       _quizAnswered = false;
    });
    // Auto-play audio on entry
    if (_currentIndex < _words.length) {
        _playWordAudio(_words[_currentIndex]['english'] ?? '');
    }
  }

  void _startQuizStep() {
     if (_currentIndex >= _words.length) return;
     
     final currentWord = _words[_currentIndex];
     final correctAnswer = currentWord['nicobarese'] ?? '';
     
     // Generate distractors
     final random = Random();
     final Set<String> options = {correctAnswer};
     
     // Try to find 2 other random words from the same level
     while (options.length < 3 && options.length < _words.length) {
         final randomWord = _words[random.nextInt(_words.length)];
         final wrongAnswer = randomWord['nicobarese'] ?? '';
         if (wrongAnswer.isNotEmpty) {
             options.add(wrongAnswer);
         }
     }
     
     // If we still don't have enough (e.g. level has < 3 words), just use what we have
     
     setState(() {
         _quizOptions = options.toList()..shuffle();
         _currentStep = LearningStep.quiz;
         _quizAnswered = false;
     });
  }

  void _checkAnswer(String selectedAnswer) {
      if (_quizAnswered) return;
      
      final currentWord = _words[_currentIndex];
      final correctAnswer = currentWord['nicobarese'] ?? '';
      final isCorrect = selectedAnswer == correctAnswer;
      
      setState(() {
          _quizAnswered = true;
          _quizCorrect = isCorrect;
      });
      
      _playSoundEffect(isCorrect);
      
      if (!isCorrect) {
          _shakeController.forward(from: 0);
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                 content: Text("Oops! The correct answer is $correctAnswer"),
                 backgroundColor: Colors.redAccent,
                 duration: const Duration(seconds: 2),
             )
          );
      } else {
             // Celebration!
      }
      
      // Auto advance or show button? Button is better for pacing.
  }

  void _advance() {
      if (_currentIndex < _words.length - 1) {
          setState(() {
              _currentIndex++;
          });
          _startLearnStep();
      } else {
          _completeLevel();
      }
  }

  Future<void> _completeLevel() async {
    await _progressService.unlockNextLevel(widget.level);
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Level Completed! 🎉", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                const Icon(Icons.stars_rounded, size: 80, color: Colors.amber),
                const SizedBox(height: 20),
                Text("You have mastered Level ${widget.level}!", textAlign: TextAlign.center),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to levels screen
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("Awesome!"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Level ${widget.level}"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Background(
        colors: const [Color(0xFF6A11CB), Color(0xFF2575FC)], // Professional Blue/Purple gradient
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: Column(
                  children: [
                     // Progress Bar
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                       child: ClipRRect(
                           borderRadius: BorderRadius.circular(10),
                           child: LinearProgressIndicator(
                               value: (_currentIndex + (_currentStep == LearningStep.quiz && _quizAnswered ? 0.9 : 0.0)) / _words.length,
                               backgroundColor: Colors.white24,
                               color: Colors.greenAccent,
                               minHeight: 8,
                           ),
                       ),
                     ),
                     
                     Expanded(
                         child: AnimatedSwitcher(
                             duration: const Duration(milliseconds: 400),
                             child: _currentStep == LearningStep.learn 
                                 ? _buildLearnCard() 
                                 : _buildQuizCard(),
                         ),
                     ),
                  ],
                ),
            ),
      ),
    );
  }
  
  Widget _buildLearnCard() {
      final word = _words[_currentIndex];
      return Center(
          child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                  ],
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      const Text("LEARN", style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      Text(word['english'] ?? '', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      Text(word['nicobarese'] ?? '', style: const TextStyle(fontSize: 24, color: Colors.indigo, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                      const SizedBox(height: 40),
                      GestureDetector(
                          onTap: () => _playWordAudio(word['english'] ?? ''),
                          child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                              child: const Icon(Icons.volume_up_rounded, size: 40, color: Colors.blue),
                          ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Tap to listen", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                      const SizedBox(height: 40),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: _startQuizStep,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("I know this!", style: TextStyle(fontSize: 18)),
                          ),
                      ),
                  ],
              ),
          ),
      );
  }
  
  Widget _buildQuizCard() {
      final word = _words[_currentIndex];
      return AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
            return Transform.translate(
                offset: Offset(_shakeAnimation.value * sin(_shakeController.value * pi * 4), 0),
                child: child,
            );
        },
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
                children: [
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0,5))],
                        ),
                        child: Column(
                            children: [
                                const Text("QUIZ MODE", style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                Text("What is '${word['english']}' in Nicobarese?", 
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                    textAlign: TextAlign.center,
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 30),
                    ..._quizOptions.map((option) {
                        bool isSelected = _quizAnswered && option == (word['nicobarese'] ?? '');
                        bool isWrong = _quizAnswered && option != (word['nicobarese'] ?? '') && !_quizCorrect; // Highlight wrong only if user clicked it? 
                        // Actually, simpler logic: 
                        // If answered:
                        // - Correct option -> Green
                        // - Other options -> Grey or Red if wrong selected?
                        // Let's keep it simple: Correct is Green.
                        
                        Color color = Colors.white;
                        Color textColor = Colors.black87;
                        if (_quizAnswered) {
                            if (option == (word['nicobarese'] ?? '')) {
                                color = Colors.green.shade100;
                                textColor = Colors.green.shade900;
                            } else {
                                color = Colors.grey.shade100;
                                textColor = Colors.grey;
                            }
                        }
                        
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: GestureDetector(
                                onTap: () => _checkAnswer(option),
                                child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                                    decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: _quizAnswered && option == (word['nicobarese'] ?? '') 
                                                ? Colors.green 
                                                : Colors.transparent,
                                            width: 2
                                        ),
                                        boxShadow: [
                                            if (!_quizAnswered)
                                               BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                                        ]
                                    ),
                                    child: Row(
                                        children: [
                                            Expanded(child: Text(option, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor))),
                                            if (_quizAnswered && option == (word['nicobarese'] ?? ''))
                                                const Icon(Icons.check_circle, color: Colors.green),
                                        ],
                                    ),
                                ),
                            ),
                        );
                    }).toList(),
                    
                    const SizedBox(height: 20),
                    
                    if (_quizAnswered)
                        FadeTransition(
                            opacity: const AlwaysStoppedAnimation(1), // Could animate
                            child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: _advance,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: _quizCorrect ? Colors.green : Colors.orange,
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    child: Text(_quizCorrect ? "Continue" : "Try Next", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                            ),
                        ),
                ],
            ),
        ),
      );
  }
}

