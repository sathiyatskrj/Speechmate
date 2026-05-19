import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../services/dictionary_service.dart';
import '../services/whisper_service.dart';
import '../services/pronunciation_scorer.dart';
import '../widgets/background.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';

class LevelLearningScreen extends StatefulWidget {
  final int level;
  const LevelLearningScreen({super.key, required this.level});

  @override
  State<LevelLearningScreen> createState() => _LevelLearningScreenState();
}

enum LearningStep { learn, pronounce, quiz }

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

  // Pronunciation State
  final WhisperService _whisperService = WhisperService();
  AudioRecorder? _audioRecorder;
  bool _isPronounceRecording = false;
  bool _isPronounceProcessing = false;
  int _pronounceScore = -1; // -1 = not scored yet
  String _pronounceLabel = '';
  String _pronounceTranscription = '';

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
    _audioRecorder?.dispose();
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
       _pronounceScore = -1;
       _pronounceLabel = '';
       _pronounceTranscription = '';
    });
    if (_currentIndex < _words.length) {
        _playWordAudio(_words[_currentIndex]['english'] ?? '');
    }
  }

  void _startPronounceStep() {
    setState(() {
      _currentStep = LearningStep.pronounce;
      _pronounceScore = -1;
      _pronounceLabel = '';
      _pronounceTranscription = '';
      _isPronounceRecording = false;
      _isPronounceProcessing = false;
    });
  }

  Future<void> _togglePronounceRecording() async {
    if (_isPronounceProcessing) return;

    if (_isPronounceRecording) {
      // Stop and score
      String? path;
      try {
        path = await _audioRecorder!.stop();
      } catch (e) {
        debugPrint('[Pronunciation] Stop error: $e');
      }

      HapticFeedback.lightImpact();
      if (mounted) setState(() { _isPronounceRecording = false; _isPronounceProcessing = true; });

      if (path != null && File(path).existsSync()) {
        try {
          final transcription = await _whisperService.transcribe(path);
          final expected = _words[_currentIndex]['nicobarese']?.toString() ?? '';
          final score = PronunciationScorer.score(transcription.trim(), expected);
          final label = PronunciationScorer.label(score);

          if (mounted) {
            setState(() {
              _pronounceScore = score;
              _pronounceLabel = label;
              _pronounceTranscription = transcription.trim();
              _isPronounceProcessing = false;
            });
          }
        } catch (e) {
          debugPrint('[Pronunciation] Transcribe error: $e');
          if (mounted) setState(() { _isPronounceProcessing = false; _pronounceLabel = 'Could not process. Try again.'; });
        }
        // Clean up temp file
        try { File(path).deleteSync(); } catch (_) {}
      } else {
        if (mounted) setState(() => _isPronounceProcessing = false);
      }
    } else {
      // Start recording
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();

      if (!await _audioRecorder!.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required')));
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/pronounce_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder!.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        path: path,
      );

      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _isPronounceRecording = true);
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
                                   : _currentStep == LearningStep.pronounce
                                       ? _buildPronounceCard()
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
                              onPressed: _startPronounceStep,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  elevation: 5
                              ),
                              child: const Text("Practice Speaking", style: TextStyle(fontSize: 18)),
                          ),
                      ),
                  ],
              ),
          ),
      );
  }

  Widget _buildPronounceCard() {
      if (_words.isEmpty || _currentIndex >= _words.length) {
        return const Center(child: Text("Loading...", style: TextStyle(color: Colors.white)));
      }
      final word = _words[_currentIndex];
      final nicWord = word['nicobarese']?.toString() ?? '';

      // Score color
      Color scoreColor = Colors.grey;
      if (_pronounceScore >= 90) scoreColor = Colors.greenAccent;
      else if (_pronounceScore >= 70) scoreColor = Colors.lightGreen;
      else if (_pronounceScore >= 50) scoreColor = Colors.amber;
      else if (_pronounceScore >= 0) scoreColor = Colors.redAccent;

      return Center(
          key: const ValueKey('pronounce'),
          child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 15))
                  ],
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      const Icon(Icons.mic, size: 36, color: Colors.deepPurple),
                      const SizedBox(height: 8),
                      Text("PRONOUNCE", style: TextStyle(color: Colors.grey[700], letterSpacing: 2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text("Say this word:", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(nicWord, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple), textAlign: TextAlign.center)
                        .animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 6),
                      Text("(${word['english'] ?? ''})", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      const SizedBox(height: 8),

                      // Listen button
                      TextButton.icon(
                        onPressed: () => _playWordAudio(word['english'] ?? ''),
                        icon: const Icon(Icons.volume_up_rounded, size: 20),
                        label: const Text("Listen first"),
                        style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                      ),

                      const SizedBox(height: 20),

                      // Mic button
                      GestureDetector(
                          onTap: _isPronounceProcessing ? null : _togglePronounceRecording,
                          child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isPronounceRecording
                                        ? [Colors.red, Colors.redAccent]
                                        : _isPronounceProcessing
                                            ? [Colors.grey, Colors.grey.shade400]
                                            : [Colors.deepPurple, Colors.purpleAccent],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isPronounceRecording ? Colors.red : Colors.deepPurple).withValues(alpha: 0.4),
                                      blurRadius: 20, spreadRadius: 3,
                                    )
                                  ],
                              ),
                              child: Icon(
                                _isPronounceRecording ? Icons.stop_rounded
                                    : _isPronounceProcessing ? Icons.hourglass_top_rounded
                                    : Icons.mic_rounded,
                                size: 40, color: Colors.white,
                              ),
                          ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPronounceRecording ? "Tap to stop" : _isPronounceProcessing ? "Scoring..." : "Tap to record",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),

                      // Score result
                      if (_pronounceScore >= 0) ...[
                        const SizedBox(height: 20),
                        // Score ring
                        SizedBox(
                          width: 80, height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _pronounceScore / 100,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                              ),
                              Text("$_pronounceScore", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: scoreColor)),
                            ],
                          ),
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 8),
                        Text(_pronounceLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (_pronounceTranscription.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text("You said: \"$_pronounceTranscription\"", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic)),
                          ),
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: _startQuizStep,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _pronounceScore >= 0 ? Colors.green : Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  elevation: 5,
                              ),
                              child: Text(
                                _pronounceScore >= 0 ? "Continue to Quiz" : "Skip to Quiz",
                                style: const TextStyle(fontSize: 18),
                              ),
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
