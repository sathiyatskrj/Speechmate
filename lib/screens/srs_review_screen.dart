import 'package:flutter/material.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/srs_engine.dart';

class SrsReviewScreen extends StatefulWidget {
  const SrsReviewScreen({super.key});

  @override
  State<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends State<SrsReviewScreen> {
  List<Map<String, dynamic>> _dueCards = [];
  bool _isLoading = true;
  bool _showAnswer = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDueCards();
  }

  Future<void> _loadDueCards() async {
    final cards = await DatabaseManager.instance.getDueFlashcards();
    setState(() {
      _dueCards = cards;
      _isLoading = false;
      _showAnswer = false;
      _currentIndex = 0;
    });
  }

  void _flipCard() {
    setState(() {
      _showAnswer = true;
    });
  }

  Future<void> _gradeCard(int grade) async {
    if (_currentIndex >= _dueCards.length) return;
    
    final currentCard = _dueCards[_currentIndex];
    final String wordId = currentCard['word_id'] as String;
    
    await SRSEngine.processReview(wordId, grade);
    
    setState(() {
      _currentIndex++;
      _showAnswer = false;
    });
  }

  Widget _buildGradeButton(String label, int grade, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _gradeCard(grade),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_dueCards.isEmpty || _currentIndex >= _dueCards.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Review')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              SizedBox(height: 16),
              Text("You're all caught up for today!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final card = _dueCards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Review (${_currentIndex + 1}/${_dueCards.length})'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: InkWell(
                  onTap: _showAnswer ? null : _flipCard,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.grey.shade50],
                      ),
                    ),
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card['english'] as String,
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        if (_showAnswer)
                          Text(
                            card['nicobarese'] as String,
                            style: const TextStyle(fontSize: 42, color: Colors.indigo, fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          )
                        else
                          const Text(
                            "Tap to reveal answer",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_showAnswer)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGradeButton("Again", 0, Colors.redAccent),
                  _buildGradeButton("Hard", 2, Colors.orangeAccent),
                  _buildGradeButton("Good", 3, Colors.blueAccent),
                  _buildGradeButton("Easy", 5, Colors.green),
                ],
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                onPressed: _flipCard,
                child: const Text('Show Answer', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
