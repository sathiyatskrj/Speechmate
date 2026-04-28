import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../../services/dictionary_service.dart';
import '../../services/database_manager.dart';
import '../../services/progress_service.dart';
import 'games_hub_screen.dart';

class FlashCardGame extends StatefulWidget {
  const FlashCardGame({super.key});

  @override
  State<FlashCardGame> createState() => _FlashCardGameState();
}

class _FlashCardGameState extends State<FlashCardGame> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  
  List<Map<String, dynamic>> _words = [];
  int _currentIndex = 0;
  bool _showTranslation = false;
  bool _isLoading = true;
  bool _isWon = false;
  int _knownCount = 0;
  int _learningCount = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
    _loadWords();
  }
  
  @override 
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    setState(() { _isLoading = true; _isWon = false; _currentIndex = 0; _knownCount = 0; _learningCount = 0; });
    
    List<Map<String, dynamic>> data = await DictionaryService().loadDictionary(DictionaryType.words);
    
    if (data.isEmpty) {
      try {
        final db = await DatabaseManager.instance.database;
        data = await db.query('words', limit: 200);
      } catch (_) {}
    }
    
    if (data.isEmpty) {
      data = [
        {'english': 'Water', 'nicobarese': 'Mak'},
        {'english': 'Sun', 'nicobarese': 'Nyöt'},
        {'english': 'Moon', 'nicobarese': 'Talay'},
        {'english': 'Fish', 'nicobarese': 'Hā'},
        {'english': 'Tree', 'nicobarese': 'Tōt'},
        {'english': 'Fire', 'nicobarese': 'Chö'},
        {'english': 'Rain', 'nicobarese': 'Öt'},
        {'english': 'Earth', 'nicobarese': 'Chu-ah'},
        {'english': 'Wind', 'nicobarese': 'Tāh'},
        {'english': 'Stone', 'nicobarese': 'Tuh'},
      ];
    }
    
    data = data.where((w) {
      final eng = w['english']?.toString().trim() ?? '';
      final nic = w['nicobarese']?.toString().trim() ?? '';
      return eng.isNotEmpty && nic.isNotEmpty;
    }).toList();
    
    data.shuffle();
    setState(() {
      _words = data.take(10).toList();
      _isLoading = false;
      _showTranslation = false;
    });
  }

  void _flipCard() {
    if (_showTranslation) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showTranslation = !_showTranslation);
  }

  void _markKnown() async {
    _knownCount++;
    await ProgressService().markWordAsLearned();
    _nextCard();
  }

  void _markLearning() {
    _learningCount++;
    _nextCard();
  }

  void _nextCard() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _showTranslation = false;
        _flipController.reset();
      });
    } else {
      setState(() => _isWon = true);
      ProgressService().recordQuizTaken();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Flash Cards", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFa18cd1).withValues(alpha: 0.8), const Color(0xFFfbc2eb).withValues(alpha: 0.8)],
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
            colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb), Color(0xFFFFF5F5)],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _isWon ? _buildCompletionScreen()
            : Column(
                children: [
                  const SizedBox(height: 16),
                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text("${_currentIndex + 1}/${_words.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (_currentIndex + 1) / _words.length,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // The Card
                  GestureDetector(
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final angle = _flipAnimation.value * pi;
                        final isBack = angle >= pi / 2;
                        
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          alignment: Alignment.center,
                          child: Transform(
                            transform: Matrix4.identity()..rotateY(isBack ? pi : 0),
                            alignment: Alignment.center,
                            child: Container(
                              height: 320,
                              width: MediaQuery.of(context).size.width * 0.8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isBack 
                                    ? [const Color(0xFF6A11CB), const Color(0xFF2575FC)]
                                    : [Colors.white, const Color(0xFFF8F8FF)],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isBack ? Colors.purple : Colors.black).withValues(alpha: 0.2),
                                    blurRadius: 25,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isBack ? Icons.translate : Icons.abc,
                                    size: 40,
                                    color: isBack ? Colors.white.withValues(alpha: 0.4) : Colors.purple.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Text(
                                      isBack ? (_words[_currentIndex]['nicobarese'] ?? '') : (_words[_currentIndex]['english'] ?? ''),
                                      style: TextStyle(
                                        fontSize: 34, 
                                        fontWeight: FontWeight.bold,
                                        color: isBack ? Colors.white : Colors.black87,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (isBack ? Colors.white : Colors.purple).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isBack ? "Nicobarese" : "English",
                                      style: TextStyle(fontSize: 13, color: isBack ? Colors.white70 : Colors.purple.shade300, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "tap to flip",
                                    style: TextStyle(fontSize: 12, color: (isBack ? Colors.white : Colors.grey).withValues(alpha: 0.5)),
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
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.close_rounded,
                          label: "Still Learning",
                          color: Colors.orange,
                          onTap: _markLearning,
                        ),
                        _buildActionButton(
                          icon: Icons.check_rounded,
                          label: "I Know This!",
                          color: Colors.green,
                          onTap: _markKnown,
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
    return _isWon ? CelebrationOverlay(child: content) : content;
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🎓", style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text("Session Complete!", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResultStat("✅ Known", "$_knownCount", Colors.green),
                _buildResultStat("📖 Learning", "$_learningCount", Colors.orange),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _loadWords,
              icon: const Icon(Icons.refresh),
              label: const Text("Start New Set"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
