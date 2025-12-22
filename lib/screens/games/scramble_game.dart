import 'package:flutter/material.dart';
import '../../services/dictionary_service.dart';
import 'games_hub_screen.dart';

class ScrambleGame extends StatefulWidget {
  const ScrambleGame({super.key});

  @override
  State<ScrambleGame> createState() => _ScrambleGameState();
}

class _ScrambleGameState extends State<ScrambleGame> {
  final DictionaryService _dictionaryService = DictionaryService();
  
  Map<String, dynamic>? _currentWord;
  List<String> _shuffledLetters = [];
  List<String> _userAnswer = [];
  bool _isLoading = true;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadNextWord();
  }

  Future<void> _loadNextWord() async {
    setState(() { _isLoading = true; _isCorrect = false; _userAnswer.clear(); });
    
    final allWords = await _dictionaryService.loadDictionary(DictionaryType.words);
    // Filter for words with 3-8 letters for better gameplay
    final validWords = allWords.where((w) {
      final s = w['nicobarese'].toString().trim();
      return s.length >= 3 && s.length <= 8 && !s.contains(" "); 
    }).toList();
    
    if (validWords.isEmpty) {
        // Fallback if filter is too strict
        validWords.addAll(allWords); 
    }

    validWords.shuffle();
    final wordData = validWords.first;
    final target = wordData['nicobarese'].toString().trim().toLowerCase();
    
    List<String> chars = target.split('');
    chars.shuffle();

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
      setState(() => _isCorrect = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      appBar: AppBar(title: const Text("Scramble"), backgroundColor: Colors.teal),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              const SizedBox(height: 30),
              const Text("Translate this into Nicobarese:", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                 decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                 child: Text(
                   _currentWord!['english'], 
                   style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.teal),
                 ),
              ),
              const Spacer(),
              
              // Answer Area
              Wrap(
                spacing: 8,
                children: _userAnswer.asMap().entries.map((e) {
                  return GestureDetector(
                    onTap: () => _onAnswerTap(e.value, e.key),
                    child: Chip(
                      label: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: _isCorrect ? Colors.greenAccent : Colors.amber.shade200,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              // Dashes/Placeholders if empty
              if (_userAnswer.isEmpty)
                Text("Tap letters below", style: TextStyle(color: Colors.grey.shade400)),

              const Spacer(),
              const Divider(),
              const Text("Available Letters:"),
              const SizedBox(height: 10),
              // Letters to pick
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _shuffledLetters.asMap().entries.map((e) {
                  return GestureDetector(
                    onTap: () => _onLetterTap(e.value, e.key),
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.teal),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                      ),
                      alignment: Alignment.center,
                      child: Text(e.value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              if (_isCorrect)
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
                   child: ElevatedButton(
                     onPressed: _loadNextWord,
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 50)),
                     child: const Text("Next Word ->", style: TextStyle(color: Colors.white)),
                   ),
                 )
            ],
          ),
    );
    return _isCorrect ? CelebrationOverlay(child: content) : content;
  }
}
