import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
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

class _LevelLearningScreenState extends State<LevelLearningScreen> with TickerProviderStateMixin {
  final DictionaryService _dictionaryService = DictionaryService();
  final ProgressService _progressService = ProgressService();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  
  List<Map<String, dynamic>> _words = [];
  bool _isLoading = true;
  
  // Game State
  int _currentIndex = 0;
  LearningStep _currentStep = LearningStep.learn;
  bool _quizAnswered = false;
  bool _quizCorrect = false;
  List<String> _quizOptions = [];
  
  // Physics Animation Controllers
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0, end: 10).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _loadWords();
  }
  
  @override
  void dispose() {
    _shakeController.dispose();
    _confettiController.dispose();
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
    try {
      final filename = word.toLowerCase().replaceAll(' ', '_');
      await _audioPlayer.play(AssetSource('audio/words/$filename.mp3'));
    } catch (e) {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.speak(word);
    }
  }

  void _playSoundEffect(bool isCorrect) async {
      try {
          final file = isCorrect ? 'audio/success.mp3' : 'audio/error.mp3';
          await _sfxPlayer.play(AssetSource(file));
      } catch (_) {}
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
     if (_currentIndex >= _words.length) return;
     
     final currentWord = _words[_currentIndex];
     final correctAnswer = currentWord['nicobarese'] ?? '';
     
     final random = Random();
     final Set<String> options = {correctAnswer};
     
     while (options.length < 3 && options.length < _words.length) {
         final randomWord = _words[random.nextInt(_words.length)];
         final wrongAnswer = randomWord['nicobarese'] ?? '';
         if (wrongAnswer.isNotEmpty) {
             options.add(wrongAnswer);
         }
     }
     
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
             const SnackBar(
                 content: Text("Re-calibrating... Try again!"),
                 backgroundColor: Colors.redAccent,
                 behavior: SnackBarBehavior.floating,
             )
          );
      } else {
             // CHEMISTRY ENGINE: Reaction!
             _confettiController.play();
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
          title: const Text("Reaction Complete! 🧪", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                const Icon(Icons.science, size: 80, color: Colors.purpleAccent).animate().scale(duration: 1.seconds, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                Text("Experiment Successful.\nLevel ${widget.level} Mastered.", textAlign: TextAlign.center),
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
              child: const Text("Excellent"),
            ),
          ],
        ),
      );
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Lab Module ${widget.level}"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Background(
            colors: const [Color(0xFF240b36), Color(0xFFc31432)], // Dark Plasma Gradient
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SafeArea(
                    child: Column(
                      children: [
                         // Biology Engine: Fluid Progress
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
                                 switchInCurve: Curves.elasticOut, // Physics Engine: Springy transition
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
          
          // Chemistry Engine: Particle System
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLearnCard() {
      final word = _words[_currentIndex];
      return Center(
          key: const ValueKey('learn'),
          child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15))
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.2))
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      const Icon(Icons.biotech, size: 40, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text("OBSERVE", style: TextStyle(color: Colors.grey[700], letterSpacing: 2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      Text(word['english'] ?? '', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo), textAlign: TextAlign.center)
                        .animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 10),
                      Text(word['nicobarese'] ?? '', style: const TextStyle(fontSize: 24, color: Colors.purple, fontWeight: FontWeight.w500), textAlign: TextAlign.center)
                        .animate(delay: 300.ms).fadeIn().slideY(begin: 0.3),
                      
                      const SizedBox(height: 40),
                      GestureDetector(
                          onTap: () {
                              _playWordAudio(word['english'] ?? '');
                              // Add a little pulse animation on tap could be nice, but simple for now
                          },
                          child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Colors.blue, Colors.cyan]), 
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)]
                              ),
                              child: const Icon(Icons.volume_up_rounded, size: 40, color: Colors.white),
                          ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.05, duration: 1.seconds), // Breathing
                      
                      const SizedBox(height: 10),
                      const Text("Tap to analyze audio", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
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
                              child: const Text("Commence Test", style: TextStyle(fontSize: 18)),
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
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0,10))],
                        ),
                        child: Column(
                            children: [
                                const Text("HYPOTHESIS TEST", style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                Text("Select translation for:\n'${word['english']}'", 
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
                        ).animate().slideX(begin: 0.2, duration: 400.ms, curve: Curves.easeOutQuad, delay: Duration(milliseconds: _quizOptions.indexOf(option) * 100)); // Staggered entry
                    }),
                    
                    const SizedBox(height: 20),
                    
                    if (_quizAnswered)
                        FadeTransition(
                            opacity: const AlwaysStoppedAnimation(1),
                            child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: _advance,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: _quizCorrect ? Colors.green : Colors.orange,
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        elevation: 5
                                    ),
                                    child: Text(_quizCorrect ? "Proceed" : "Retry Next", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                            ),
                        ).animate().scale(duration: 300.ms),
                ],
            ),
        ),
      );
  }
}

