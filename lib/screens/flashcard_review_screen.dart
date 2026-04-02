import 'package:flutter/material.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/srs_engine.dart';
import 'package:speechmate/widgets/background.dart';
import 'dart:math' as math;

class FlashcardReviewScreen extends StatefulWidget {
  const FlashcardReviewScreen({super.key});

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen> {
  List<Map<String, dynamic>> _dueCards = [];
  bool _isLoading = true;
  bool _isFlipped = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDueCards();
  }

  Future<void> _loadDueCards() async {
    final cards = await DatabaseManager.instance.getDueFlashcards();
    if (mounted) {
      setState(() {
        _dueCards = cards;
        _isLoading = false;
        _isFlipped = false;
        _currentIndex = 0;
      });
    }
  }

  void _handleGrade(int grade) async {
    final card = _dueCards[_currentIndex];
    final wordId = card['word_id'] as String;
    
    await SRSEngine.processReview(wordId, grade);

    if (mounted) {
      if (_currentIndex < _dueCards.length - 1) {
        setState(() {
          _currentIndex++;
          _isFlipped = false;
        });
      } else {
        // Finished
        setState(() {
          _dueCards.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Spaced Repetition Review"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Background(
        colors: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _dueCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 80, color: Colors.greenAccent),
                          const SizedBox(height: 20),
                          const Text("You're all caught up!", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text("No flashcards due right now.", style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueAccent),
                            child: const Text("Go Back"),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text("Card ${_currentIndex + 1} of ${_dueCards.length}", style: const TextStyle(color: Colors.white70)),
                        ),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: GestureDetector(
                                onTap: () {
                                  if (!_isFlipped) setState(() => _isFlipped = true);
                                },
                                child: Dismissible(
                                  key: Key('${_dueCards[_currentIndex]['word_id']}_$_isFlipped'),
                                  direction: _isFlipped ? DismissDirection.horizontal : DismissDirection.none,
                                  background: Container(
                                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(horizontal: 30),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_outline, color: Colors.white, size: 50),
                                        Text('Good', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                      ],
                                    ),
                                  ),
                                  secondaryBackground: Container(
                                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 30),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.cancel_outlined, color: Colors.white, size: 50),
                                        Text('Fail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                      ],
                                    ),
                                  ),
                                  onDismissed: (direction) {
                                    if (direction == DismissDirection.startToEnd) {
                                      _handleGrade(4); // Good
                                    } else {
                                      _handleGrade(1); // Fail
                                    }
                                  },
                                  child: TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: _isFlipped ? pi : 0),
                                    duration: const Duration(milliseconds: 400),
                                    builder: (context, double value, child) {
                                      bool isFront = value < (pi / 2);
                                    return Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateY(value),
                                      child: isFront ? _buildCardFront() : Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()..rotateY(pi),
                                          child: _buildCardBack()),
                                    );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_isFlipped)
                           Padding(
                             padding: const EdgeInsets.all(20.0),
                             child: Column(
                               children: [
                                 const Text("How well did you know this?", style: TextStyle(color: Colors.white, fontSize: 16)),
                                 const SizedBox(height: 15),
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                   children: [
                                     _buildGradeBtn("Fail", 1, Colors.redAccent, "😖"),
                                     _buildGradeBtn("Hard", 3, Colors.orangeAccent, "😐"),
                                     _buildGradeBtn("Good", 4, Colors.green, "😊"),
                                     _buildGradeBtn("Easy", 5, Colors.blue, "🤩"),
                                   ],
                                 ),
                                 const SizedBox(height: 15),
                                 const Text("...or swipe card Left (Fail) / Right (Good)", style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic)),
                               ],
                             ),
                           )
                        else
                           const Padding(
                             padding: EdgeInsets.all(40.0),
                             child: Text("Tap card to reveal answer", style: TextStyle(color: Colors.white54, fontSize: 16)),
                           )
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    final card = _dueCards[_currentIndex];
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0,10))]
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           const Text("Translate to Nicobarese:", style: TextStyle(color: Colors.grey, fontSize: 16)),
           const SizedBox(height: 20),
           Text(card['english'] as String, style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      )
    );
  }

  Widget _buildCardBack() {
    final card = _dueCards[_currentIndex];
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0,10))]
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           const Text("Nicobarese Translation:", style: TextStyle(color: Colors.teal, fontSize: 16)),
           const SizedBox(height: 20),
           Text(card['nicobarese'] as String, style: const TextStyle(color: Colors.teal, fontSize: 36, fontWeight: FontWeight.bold)),
        ],
      )
    );
  }

  Widget _buildGradeBtn(String label, int grade, Color color, String emoji) {
    return GestureDetector(
      onTap: () => _handleGrade(grade),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
const double pi = math.pi;
