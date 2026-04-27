import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/dictionary_service.dart';
import '../widgets/background.dart';
import 'dart:math';

class LevelLearningScreen extends StatefulWidget {
  final int level;
  const LevelLearningScreen({super.key, required this.level});

  @override
  State<LevelLearningScreen> createState() => _LevelLearningScreenState();
}

enum LearningStep { learn, quiz }

class _LevelLearningScreenState extends State<LevelLearningScreen> with TickerProviderStateMixin {
  final DictionaryService _dictionaryService = DictionaryService();
  final ProgressService _progressService = ProgressService();
  final TtsService _ttsService = TtsService();
  
  List<Map<String, dynamic>> _words = [];
  bool _isLoading = true;
  
  // Game State
  int _currentIndex = 0;
  LearningStep _currentStep = LearningStep.learn;
  bool _quizAnswered = false;
  bool _quizCorrect = false;
  List<String> _quizOptions = [];
  
  // Shake Animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0, end: 10).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _ttsService.init();
    _loadWords();
  }
  
  @override
  void dispose() {
    _shakeController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    try {
      final words = await _dictionaryService.getWordsForLevel(widget.level);
      if (mounted) {
        if (words.isEmpty) {
          // Fallback: load random words from the dictionary if level-specific words are empty
          final fallback = await _dictionaryService.getRandomWords(5);
          setState(() {
            _words = fallback;
            _isLoading = false;
          });
        } else {
          setState(() {
            _words = words;
            _isLoading = false;
          });
        }
        if (_words.isNotEmpty) {
          _startLearnStep();
        }
      }
    } catch (e) {
      debugPrint("Error loading words for level: $e");
      if (mounted) {
        // Ultimate fallback: use mock data so the screen doesn't crash
        setState(() {
          _words = [
            {"english": "Hello", "nicobarese": "Harao"},
            {"english": "Water", "nicobarese": "Dāk"},
            {"english": "Fish", "nicobarese": "Hīchā"},
            {"english": "House", "nicobarese": "Pati"},
            {"english": "Tree", "nicobarese": "Dāng"},
          ];
          _isLoading = false;
        });
        _startLearnStep();
      }
    }
  }

  Future<void> _playWordAudio(String word) async {
    try {
      // Smart lookup: searches all audio folders for matching file
      await _ttsService.speakNicobarese(word, englishWord: word);
    } catch (e) {
      debugPrint("TTS error: $e");
    }
  }

  void _startLearnStep() {
    setState(() {
       _currentStep = LearningStep.learn;
       _quizAnswered = false;
    });
    if (_currentIndex < _words.length) {
        _playWordAudio(_words[_currentIndex]['english'] ?? '');
    }
  }

  void _startQuizStep() {
     if (_words.isEmpty || _currentIndex >= _words.length) return;
     
     final currentWord = _words[_currentIndex];
     final correctAnswer = currentWord['nicobarese']?.toString() ?? '';
     
     if (correctAnswer.isEmpty) {
       // Skip quiz if no translation available
       _advance();
       return;
     }
     
     final random = Random();
     final Set<String> options = {correctAnswer};
     
     // Build wrong options from available words
     int attempts = 0;
     while (options.length < 3 && attempts < 20) {
         attempts++;
         if (_words.length <= 1) break;
         final randomWord = _words[random.nextInt(_words.length)];
         final wrongAnswer = randomWord['nicobarese']?.toString() ?? '';
         if (wrongAnswer.isNotEmpty && wrongAnswer != correctAnswer) {
             options.add(wrongAnswer);
         }
     }
     
     // If we still don't have 3 options, add mock options
     if (options.length < 3) {
       options.add("Tafūl");
       options.add("Hōdi");
     }
     
     setState(() {
         _quizOptions = options.toList()..shuffle();
         _currentStep = LearningStep.quiz;
         _quizAnswered = false;
     });
  }

  void _checkAnswer(String selectedAnswer) {
      if (_quizAnswered || _words.isEmpty) return;
      
      final currentWord = _words[_currentIndex];
      final correctAnswer = currentWord['nicobarese']?.toString() ?? '';
      final isCorrect = selectedAnswer == correctAnswer;
      
      setState(() {
          _quizAnswered = true;
          _quizCorrect = isCorrect;
      });
      
      if (!isCorrect) {
          _shakeController.forward(from: 0);
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
                 content: Text("Not quite! Try the next one."),
                 backgroundColor: Colors.redAccent,
                 behavior: SnackBarBehavior.floating,
             )
          );
      } else {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
                 content: Text("✅ Correct! Excellent work!"),
                 backgroundColor: Colors.green,
                 behavior: SnackBarBehavior.floating,
             )
          );
      }
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
          title: const Text("Level Complete! 🎉", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                const Icon(Icons.emoji_events, size: 80, color: Colors.amber).animate().scale(duration: 1.seconds, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                Text("Level ${widget.level} Mastered.\nGreat work!", textAlign: TextAlign.center),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text("Continue"),
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
        title: Text("Nicobarese Module ${widget.level}"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Background(
        colors: const [Color(0xFF240b36), Color(0xFFc31432)],
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _words.isEmpty
              ? const Center(child: Text("No words available for this level.", style: TextStyle(color: Colors.white70, fontSize: 16)))
              : SafeArea(
                  child: Column(
                    children: [
                       // Progress bar
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                         child: TweenAnimationBuilder<double>(
                             tween: Tween(begin: 0, end: (_currentIndex + (_currentStep == LearningStep.quiz && _quizAnswered ? 0.9 : 0.0)) / _words.length),
                             duration: const Duration(milliseconds: 800),
                             curve: Curves.easeOutCubic,
                             builder: (context, value, _) => ClipRRect(
                                 borderRadius: BorderRadius.circular(10),
                                 child: LinearProgressIndicator(
                                     value: value,
                                     backgroundColor: Colors.white12,
                                     color: Colors.cyanAccent,
                                     minHeight: 12,
                                 ),
                             ),
                         ),
                       ),
                       
                       Expanded(
                           child: AnimatedSwitcher(
                               duration: const Duration(milliseconds: 500),
                               switchInCurve: Curves.elasticOut,
                               switchOutCurve: Curves.easeIn,
                               transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
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
      if (_words.isEmpty || _currentIndex >= _words.length) {
        return const Center(child: Text("Loading...", style: TextStyle(color: Colors.white)));
      }
      final word = _words[_currentIndex];
      return Center(
          key: const ValueKey('learn'),
          child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 15))
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2))
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      const Icon(Icons.school, size: 40, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text("LEARN", style: TextStyle(color: Colors.grey[700], letterSpacing: 2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      Text(word['english'] ?? '', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo), textAlign: TextAlign.center)
                        .animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 10),
                      Text(word['nicobarese'] ?? '', style: const TextStyle(fontSize: 24, color: Colors.purple, fontWeight: FontWeight.w500), textAlign: TextAlign.center)
                        .animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
                      
                      const SizedBox(height: 40),
                      GestureDetector(
                          onTap: () => _playWordAudio(word['english'] ?? ''),
                          child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Colors.blue, Colors.cyan]), 
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.cyan.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2)]
                              ),
                              child: const Icon(Icons.volume_up_rounded, size: 40, color: Colors.white),
                          ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.05, duration: 1.seconds),
                      
                      const SizedBox(height: 10),
                      const Text("Tap to hear pronunciation", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
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
                                  elevation: 5
                              ),
                              child: const Text("Test Yourself", style: TextStyle(fontSize: 18)),
                          ),
                      ),
                  ],
              ),
          ),
      );
  }
  
  Widget _buildQuizCard() {
      if (_words.isEmpty || _currentIndex >= _words.length) {
        return const Center(child: Text("Loading...", style: TextStyle(color: Colors.white)));
      }
      final word = _words[_currentIndex];
      return AnimatedBuilder(
        key: const ValueKey('quiz'),
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
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0,10))],
                        ),
                        child: Column(
                            children: [
                                const Text("QUIZ", style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                Text("Select translation for:\n'${word['english'] ?? ''}'", 
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                                    textAlign: TextAlign.center,
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 30),
                    ..._quizOptions.map((option) {
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: GestureDetector(
                                onTap: () => _checkAnswer(option),
                                child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                                    decoration: BoxDecoration(
                                        color: _quizAnswered 
                                            ? (option == (word['nicobarese'] ?? '') ? Colors.green.shade100 : Colors.grey.shade100)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: _quizAnswered && option == (word['nicobarese'] ?? '') 
                                                ? Colors.green 
                                                : Colors.transparent,
                                            width: 3
                                        ),
                                        boxShadow: [
                                            if (!_quizAnswered)
                                               const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                                        ]
                                    ),
                                    child: Row(
                                        children: [
                                            Expanded(child: Text(option, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.indigo.shade900))),
                                            if (_quizAnswered && option == (word['nicobarese'] ?? ''))
                                                const Icon(Icons.check_circle, color: Colors.green)
                                                    .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                                        ],
                                    ),
                                ),
                            ),
                        ).animate().slideX(begin: 0.2, duration: 400.ms, curve: Curves.easeOutQuad, delay: Duration(milliseconds: _quizOptions.indexOf(option) * 100));
                    }),
                    
                    const SizedBox(height: 20),
                    
                    if (_quizAnswered)
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: _advance,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: _quizCorrect ? Colors.green : Colors.orange,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 5
                                ),
                                child: Text(_quizCorrect ? "Next Word" : "Continue", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                        ).animate().scale(duration: 300.ms),
                ],
            ),
        ),
      );
  }
}
