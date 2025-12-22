import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/dictionary_service.dart';
import 'games_hub_screen.dart';

class FlashCardGame extends StatefulWidget {
  const FlashCardGame({super.key});

  @override
  State<FlashCardGame> createState() => _FlashCardGameState();
}

class _FlashCardGameState extends State<FlashCardGame> with SingleTickerProviderStateMixin {
  final DictionaryService _dictionaryService = DictionaryService();
  late AnimationController _controller;
  late Animation<double> _animation;
  
  List<Map<String, dynamic>> _words = [];
  int _currentIndex = 0;
  bool _showTranslation = false;
  bool _isLoading = true;
  bool _isWon = false; // "Won" means finished the stack

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _loadWords();
  }
  
  @override 
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final data = await _dictionaryService.loadDictionary(DictionaryType.words);
    data.shuffle();
    setState(() {
      _words = data.take(10).toList(); // 10 cards per session
      _isLoading = false;
      _currentIndex = 0;
      _isWon = false;
      _showTranslation = false;
    });
  }

  void _flipCard() {
    if (_showTranslation) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showTranslation = !_showTranslation);
  }

  void _nextCard() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _showTranslation = false;
        _controller.reset();
      });
    } else {
      setState(() => _isWon = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      appBar: AppBar(title: const Text("Flash Cards"), backgroundColor: Colors.deepPurpleAccent),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _isWon 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Great Job!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _loadWords, child: const Text("Start New Set"))
                ],
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 20),
                Text("Card ${_currentIndex + 1}/${_words.length}", style: const TextStyle(fontSize: 18, color: Colors.grey)),
                const Spacer(),
                GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      // 3D Flip effect
                      final angle = _animation.value * pi;
                      final isBack = angle >= pi / 2;
                      
                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: Transform(
                          // If back, we need to correct the mirroring
                          transform: Matrix4.identity()..rotateY(isBack ? pi : 0),
                          alignment: Alignment.center,
                          child: Container(
                            height: 300,
                            width: 300,
                            decoration: BoxDecoration(
                              color: isBack ? Colors.deepPurpleAccent : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isBack ? _words[_currentIndex]['nicobarese'] : _words[_currentIndex]['english'],
                                  style: TextStyle(
                                    fontSize: 32, 
                                    fontWeight: FontWeight.bold,
                                    color: isBack ? Colors.white : Colors.black87
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  isBack ? "Nicobarese" : "English",
                                  style: TextStyle(
                                    fontSize: 14, 
                                    color: isBack ? Colors.white70 : Colors.grey
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _flipCard, 
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text("Flip", style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: _nextCard,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("Next Card", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
    return _isWon ? CelebrationOverlay(child: content) : content;
  }
}
