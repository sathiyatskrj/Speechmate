import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/dictionary_service.dart';
import '../../services/database_manager.dart';
import '../../services/progress_service.dart';
import '../../widgets/tap_scale.dart';
import 'games_hub_screen.dart';

class WordMatchGame extends StatefulWidget {
  const WordMatchGame({super.key});

  @override
  State<WordMatchGame> createState() => _WordMatchGameState();
}

class _WordMatchGameState extends State<WordMatchGame> with TickerProviderStateMixin {
  List<String> _items = [];
  final Map<String, String> _pairs = {}; // Item -> Match
  
  String? _selectedItem;
  final List<String> _matchedItems = [];
  bool _isLoading = true;
  bool _isWon = false;
  int _score = 0;
  int _round = 1;
  int _mistakes = 0;
  
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _startNewGame();
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    super.dispose();
  }

  Future<void> _startNewGame() async {
    setState(() => _isLoading = true);
    
    // Try primary dictionary, fall back to ALL words if empty
    List<Map<String, dynamic>> allWords = await DictionaryService().loadDictionary(DictionaryType.words);
    
    if (allWords.isEmpty) {
      // Fallback: query ALL words from database regardless of category
      try {
        final db = await DatabaseManager.instance.database;
        allWords = await db.query('words', limit: 200);
      } catch (e) { debugPrint('Silent error caught: $e'); }
    }
    
    if (allWords.isEmpty) {
      // Hard fallback
      allWords = [
        {'english': 'Water', 'nicobarese': 'Mak'},
        {'english': 'Sun', 'nicobarese': 'Nyöt'},
        {'english': 'Moon', 'nicobarese': 'Talay'},
        {'english': 'Fish', 'nicobarese': 'Hā'},
        {'english': 'Tree', 'nicobarese': 'Tōt'},
        {'english': 'Fire', 'nicobarese': 'Chö'},
      ];
    }
    
    // Filter words with valid Nicobarese translations
    allWords = allWords.where((w) {
      final eng = w['english']?.toString().trim() ?? '';
      final nic = w['nicobarese']?.toString().trim() ?? '';
      return eng.isNotEmpty && nic.isNotEmpty && eng != nic;
    }).toList();
    
    // Pick 6 random pairs
    allWords.shuffle();
    final gameWords = allWords.take(6).toList();
    
    _pairs.clear();
    List<String> tempItems = [];
    
    for (var w in gameWords) {
      String eng = w['english'].toString().trim();
      String nic = w['nicobarese'].toString().trim();
      _pairs[eng] = nic;
      _pairs[nic] = eng;
      tempItems.add(eng);
      tempItems.add(nic);
    }
    
    tempItems.shuffle();
    
    setState(() {
      _items = tempItems;
      _matchedItems.clear();
      _selectedItem = null;
      _isWon = false;
      _isLoading = false;
    });
  }

  void _onItemTap(String item) {
    if (_matchedItems.contains(item)) return;

    if (_selectedItem == null) {
      setState(() => _selectedItem = item);
    } else {
      if (_selectedItem == item) {
        setState(() => _selectedItem = null); // deselect
      } else if (_pairs[_selectedItem] == item) {
        // Match found!
        setState(() {
          _matchedItems.add(item);
          _matchedItems.add(_selectedItem!);
          _selectedItem = null;
          _score += 50;
        });
        
        if (_matchedItems.length == _items.length) {
          setState(() {
            _isWon = true;
            _score += 200; // Completion bonus
          });
          ProgressService().recordQuizTaken(); // Award XP
        }
      } else {
        // Mismatch
        _mistakes++;
        setState(() => _selectedItem = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("❌ Try again!"), 
            duration: const Duration(milliseconds: 500), 
            backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Word Match", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFF9A9E).withValues(alpha: 0.8), const Color(0xFFFECFEF).withValues(alpha: 0.8)],
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
            colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4), Color(0xFFFFF5F5)],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  const SizedBox(height: 12),
                  // Score Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatBadge("🏆 Score", "$_score", Colors.amber),
                        _buildStatBadge("🎯 Round", "$_round", Colors.cyan),
                        _buildStatBadge("❌ Misses", "$_mistakes", Colors.redAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "Tap a word, then find its matching translation!",
                        style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final isSelected = _selectedItem == item;
                        final isMatched = _matchedItems.contains(item);
                        
                        return TapScale(
                          onTap: () => _onItemTap(item),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: isMatched 
                                  ? LinearGradient(colors: [Colors.green.shade300, Colors.green.shade100])
                                  : isSelected 
                                    ? LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade100])
                                    : null,
                              color: isMatched || isSelected ? null : Colors.white,
                              border: Border.all(
                                color: isMatched ? Colors.green : isSelected ? Colors.blue : Colors.grey.shade300,
                                width: isSelected ? 3 : 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (!isMatched)
                                  BoxShadow(color: (isSelected ? Colors.blue : Colors.black).withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: isMatched 
                              ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 34)
                              : Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Text(
                                    item, 
                                    textAlign: TextAlign.center, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: item.length > 8 ? 12 : 14,
                                      color: isSelected ? Colors.blue.shade900 : Colors.black87,
                                    ),
                                  ),
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isWon)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text("🎉 Perfect Match!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _round++);
                              _startNewGame();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text("Play Again"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9A9E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
        ),
      ),
    );

    return _isWon ? CelebrationOverlay(child: content) : content;
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.black.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
