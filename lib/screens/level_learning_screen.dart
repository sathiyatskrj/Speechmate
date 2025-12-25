import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/dictionary_service.dart';
import '../widgets/background.dart';

class LevelLearningScreen extends StatefulWidget {
  final int level;
  const LevelLearningScreen({super.key, required this.level});

  @override
  State<LevelLearningScreen> createState() => _LevelLearningScreenState();
}

class _LevelLearningScreenState extends State<LevelLearningScreen> {
  final DictionaryService _dictionaryService = DictionaryService();
  final ProgressService _progressService = ProgressService();
  final FlutterTts _flutterTts = FlutterTts();
  
  List<Map<String, dynamic>> _words = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await _dictionaryService.getWordsForLevel(widget.level);
    if (mounted) {
      setState(() {
        _words = words;
        _isLoading = false;
      });
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  void _nextPage() {
    if (_currentIndex < _words.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
          title: const Text("Level Completed! 🎉"),
          content: Text("You have mastered Level ${widget.level}! Next level unlocked."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to levels screen
              },
              child: const Text("Awesome!"),
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
        title: Text("Level ${widget.level} Learning"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Background(
        colors: const [Color(0xFF8EC5FC), Color(0xFFE0C3FC)], // Soft Blue/Purple
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                   const SizedBox(height: 100),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 20),
                     child: LinearProgressIndicator(
                       value: (_currentIndex + 1) / _words.length,
                       backgroundColor: Colors.white.withOpacity(0.5),
                       color: Colors.deepPurple,
                       minHeight: 10,
                       borderRadius: BorderRadius.circular(10),
                     ),
                   ),
                   const SizedBox(height: 20),
                   Expanded(
                     child: PageView.builder(
                       controller: _pageController,
                       physics: const NeverScrollableScrollPhysics(), // Disable swipe to force interaction
                       itemCount: _words.length,
                       onPageChanged: (index) {
                         setState(() {
                           _currentIndex = index;
                           _showTranslation = false;
                         });
                       },
                       itemBuilder: (context, index) {
                         final word = _words[index];
                         return Padding(
                           padding: const EdgeInsets.all(20.0),
                           child: Center(
                             child: GestureDetector(
                               onTap: () {
                                 setState(() {
                                   _showTranslation = !_showTranslation;
                                 });
                               },
                               child: AnimatedContainer(
                                 duration: const Duration(milliseconds: 400),
                                 curve: Curves.easeInOut,
                                 width: double.infinity,
                                 height: 400,
                                 padding: const EdgeInsets.all(30),
                                 decoration: BoxDecoration(
                                   color: Colors.white,
                                   borderRadius: BorderRadius.circular(30),
                                   boxShadow: [
                                     BoxShadow(
                                       color: Colors.black.withOpacity(0.1),
                                       blurRadius: 20,
                                       offset: const Offset(0, 10),
                                     )
                                   ],
                                 ),
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Text(
                                       _showTranslation ? "Nicobarese" : "English",
                                       style: TextStyle(
                                         fontSize: 14,
                                         color: Colors.grey[500],
                                         letterSpacing: 1.5,
                                       ),
                                     ),
                                     const SizedBox(height: 20),
                                     Text(
                                       _showTranslation ? (word['nicobarese'] ?? '') : (word['english'] ?? ''),
                                       textAlign: TextAlign.center,
                                       style: TextStyle(
                                         fontSize: 32,
                                         fontWeight: FontWeight.bold,
                                         color: _showTranslation ? Colors.deepPurple : Colors.black87,
                                       ),
                                     ),
                                     const SizedBox(height: 40),
                                     IconButton(
                                       icon: const Icon(Icons.volume_up_rounded, size: 40, color: Colors.blueAccent),
                                       onPressed: () => _speak(word['english'] ?? ''),
                                     ),
                                     const Spacer(),
                                     Text(
                                       _showTranslation ? "Tap to flip back" : "Tap to reveal Nicobarese",
                                       style: TextStyle(
                                         fontSize: 12,
                                         color: Colors.grey[400],
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                           ),
                         );
                       },
                     ),
                   ),
                   Padding(
                     padding: const EdgeInsets.all(30.0),
                     child: SizedBox(
                       width: double.infinity,
                       height: 55,
                       child: ElevatedButton(
                         onPressed: _showTranslation ? _nextPage : () {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text("Reveal the translation first!"), duration: Duration(milliseconds: 500)),
                           );
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.deepPurple,
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                           elevation: 5,
                         ),
                         child: Text(
                           _currentIndex == _words.length - 1 ? "Complete Level" : "Next Word",
                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                         ),
                       ),
                     ),
                   ),
                   const SizedBox(height: 20),
                ],
            ),
      ),
    );
  }
}
