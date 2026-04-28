import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/dictionary_service.dart';
import '../../services/database_manager.dart';
import '../../services/progress_service.dart';
import '../../widgets/tap_scale.dart';
import 'games_hub_screen.dart';

class ScrambleGame extends StatefulWidget {
  const ScrambleGame({super.key});

  @override
  State<ScrambleGame> createState() => _ScrambleGameState();
}

class _ScrambleGameState extends State<ScrambleGame> with TickerProviderStateMixin {
  Map<String, dynamic>? _currentWord;
  List<String> _shuffledLetters = [];
  final List<String> _userAnswer = [];
  bool _isLoading = true;
  bool _isCorrect = false;
  int _streak = 0;
  int _score = 0;

  late AnimationController _correctAnim;

  @override
  void initState() {
    super.initState();
    _correctAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadNextWord();
  }

  @override
  void dispose() {
    _correctAnim.dispose();
    super.dispose();
  }

  Future<void> _loadNextWord() async {
    setState(() { _isLoading = true; _isCorrect = false; _userAnswer.clear(); });
    
    List<Map<String, dynamic>> allWords = await DictionaryService().loadDictionary(DictionaryType.words);
    
    if (allWords.isEmpty) {
      try {
        final db = await DatabaseManager.instance.database;
        allWords = await db.query('words', limit: 200);
      } catch (e) { debugPrint('Silent error caught: $e'); }
    }
    
    if (allWords.isEmpty) {
      allWords = [
        {'english': 'Water', 'nicobarese': 'Mak'},
        {'english': 'Sun', 'nicobarese': 'Nyot'},
        {'english': 'Fish', 'nicobarese': 'Ha'},
        {'english': 'Tree', 'nicobarese': 'Tot'},
        {'english': 'Fire', 'nicobarese': 'Cho'},
      ];
    }
    
    // Filter for words with 3-8 letters for better gameplay
    var validWords = allWords.where((w) {
      final s = w['nicobarese']?.toString().trim() ?? '';
      return s.length >= 3 && s.length <= 8 && !s.contains(" "); 
    }).toList();
    
    if (validWords.isEmpty) {
      // Fallback if filter is too strict
      validWords = allWords.where((w) {
        final s = w['nicobarese']?.toString().trim() ?? '';
        return s.isNotEmpty && !s.contains(" ");
      }).toList();
    }
    
    if (validWords.isEmpty) validWords = List.from(allWords);

    validWords.shuffle();
    final wordData = validWords.first;
    final target = wordData['nicobarese'].toString().trim().toLowerCase();
    
    List<String> chars = target.split('');
    // Ensure shuffle actually changes the order (retry if same as original)
    for (int i = 0; i < 10; i++) {
      chars.shuffle();
      if (chars.join('') != target) break;
    }

    setState(() {
      _currentWord = wordData;
      _shuffledLetters = chars;
      _isLoading = false;
    });
  }

  void _onLetterTap(String letter, int index) {
    setState(() {
      _userAnswer.add(letter);
      _shuffledLetters.removeAt(index);
    });
    _checkAnswer();
  }

  void _onAnswerTap(String letter, int index) {
    setState(() {
      _shuffledLetters.add(letter);
      _userAnswer.removeAt(index);
      _isCorrect = false;
    });
  }

  void _checkAnswer() {
    final target = _currentWord!['nicobarese'].toString().trim().toLowerCase();
    final attempted = _userAnswer.join("");
    
    if (attempted == target) {
      setState(() {
        _isCorrect = true;
        _streak++;
        _score += 50 * _streak; // Streak bonus
      });
      _correctAnim.forward(from: 0);
      ProgressService().markWordAsLearned();
    }
  }

  void _clearAnswer() {
    setState(() {
      _shuffledLetters.addAll(_userAnswer);
      _userAnswer.clear();
      _isCorrect = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Word Scramble", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF84fab0).withValues(alpha: 0.8), const Color(0xFF8fd3f4).withValues(alpha: 0.8)],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF84fab0), Color(0xFF8fd3f4), Color(0xFFF0F8FF)],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  const SizedBox(height: 12),
                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBadge("🏆", "$_score"),
                        _buildBadge("🔥", "$_streak streak"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // English word to translate
                  const Text("Spell in Nicobarese:", style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                     decoration: BoxDecoration(
                       color: Colors.white.withValues(alpha: 0.5),
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: Colors.white),
                     ),
                     child: Text(
                       _currentWord!['english']?.toString() ?? '', 
                       style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                     ),
                  ),
                  const Spacer(),
                  
                  // Answer Area
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    constraints: const BoxConstraints(minHeight: 70),
                    decoration: BoxDecoration(
                      color: _isCorrect 
                        ? Colors.green.withValues(alpha: 0.2) 
                        : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isCorrect ? Colors.green : Colors.white.withValues(alpha: 0.6),
                        width: _isCorrect ? 3 : 1.5,
                      ),
                    ),
                    child: _userAnswer.isEmpty
                      ? Center(child: Text("Tap letters below ↓", style: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 16)))
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: _userAnswer.asMap().entries.map((e) {
                            return GestureDetector(
                              onTap: () => _onAnswerTap(e.value, e.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: _isCorrect ? Colors.green.shade400 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _isCorrect ? Colors.green : Colors.teal.shade300),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  e.value, 
                                  style: TextStyle(
                                    fontSize: 22, 
                                    fontWeight: FontWeight.bold,
                                    color: _isCorrect ? Colors.white : Colors.teal.shade800,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  ),
                  
                  if (_userAnswer.isNotEmpty && !_isCorrect)
                    TextButton.icon(
                      onPressed: _clearAnswer,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Clear"),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                    ),

                  const Spacer(),
                  
                  // Available Letters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Text("Available Letters", style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: _shuffledLetters.asMap().entries.map((e) {
                              return TapScale(
                                onTap: () => _onLetterTap(e.value, e.key),
                                child: Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF5F5F5)]),
                                    border: Border.all(color: Colors.teal.shade200, width: 1.5),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3))],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(e.value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_isCorrect)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
                      child: Column(
                        children: [
                          const Text("🎉 Correct!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _loadNextWord,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text("Next Word"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF84fab0),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
        ),
      ),
    );
    return _isCorrect ? CelebrationOverlay(child: content) : content;
  }

  Widget _buildBadge(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text("$emoji $text", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}
