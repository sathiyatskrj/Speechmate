import 'package:flutter/material.dart';
import '../../services/dictionary_service.dart';
import 'games_hub_screen.dart';

class WordMatchGame extends StatefulWidget {
  const WordMatchGame({super.key});

  @override
  State<WordMatchGame> createState() => _WordMatchGameState();
}

class _WordMatchGameState extends State<WordMatchGame> {
  final DictionaryService _dictionaryService = DictionaryService();
  List<String> _items = [];
  Map<String, String> _pairs = {}; // Item -> Match
  
  String? _selectedItem;
  List<String> _matchedItems = [];
  bool _isLoading = true;
  bool _isWon = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  Future<void> _startNewGame() async {
    setState(() => _isLoading = true);
    final allWords = await _dictionaryService.loadDictionary(DictionaryType.words);
    
    // Pick 6 random pairs
    allWords.shuffle();
    final gameWords = allWords.take(6);
    
    _pairs.clear();
    List<String> tempItems = [];
    
    for (var w in gameWords) {
      String eng = w['english'];
      String nic = w['nicobarese'];
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
        });
        
        if (_matchedItems.length == _items.length) {
          setState(() => _isWon = true);
        }
      } else {
        // Mismatch
        setState(() => _selectedItem = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Try again!"), duration: Duration(milliseconds: 500), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      appBar: AppBar(title: const Text("Match the Words"), backgroundColor: Colors.pinkAccent),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Tap a word, then find its match!",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isSelected = _selectedItem == item;
                    final isMatched = _matchedItems.contains(item);
                    
                    return GestureDetector(
                      onTap: () => _onItemTap(item),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isMatched 
                              ? Colors.green.withOpacity(0.2) 
                              : isSelected ? Colors.blue.withOpacity(0.3) : Colors.white,
                          border: Border.all(
                            color: isMatched ? Colors.green : isSelected ? Colors.blue : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (!isMatched)
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: isMatched 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
                          : Text(item, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ),
              if (_isWon)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton.icon(
                    onPressed: _startNewGame,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Play Again"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
    );

    return _isWon ? CelebrationOverlay(child: content) : content;
  }
}
