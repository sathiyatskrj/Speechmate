import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';
import '../widgets/background.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final DictionaryService dictionaryService = DictionaryService();
  
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool answered = false;
  int? selectedOption;
  
  List<String> options = [];
  int correctOptionIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }


  Future<void> _loadQuiz() async {
    setState(() => isLoading = true);
    
    try {
      final randomWords = await dictionaryService.getRandomWords(5);
      
      if (randomWords.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load quiz words. Please try again.')),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      setState(() {
        questions = randomWords;
        currentIndex = 0;
        score = 0;
        isLoading = false;
      });
      
      _generateOptions();
    } catch (e) {
      print('ERROR loading quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz error: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _generateOptions() async {
    if (currentIndex >= questions.length || questions.isEmpty) return;

    try {
      final correctWord = questions[currentIndex];
      // Safely get wrong options, handling potential empty returns
      var wrong = await dictionaryService.getRandomWords(3);
      
      // Fallback if we can't get random words (shouldn't happen if dictionary loaded)
      if (wrong.isEmpty) {
         print("Warning: Could not get random words for wrong options");
         wrong = []; 
      }

      List<String> opts = [
        correctWord['english'] ?? 'Unknown',
        ...wrong.map((e) => e['english']?.toString() ?? 'Unknown')
      ];
      
      // Ensure we have unique options if possible, though strict uniqueness isn't critical for MVP
      opts.shuffle(); // Randomize position
      
      if (mounted) {
        setState(() {
          options = opts;
          correctOptionIndex = opts.indexOf(correctWord['english']);
          // Safety check: if shuffle messed up index finding (unlikely but safe)
          if (correctOptionIndex == -1) correctOptionIndex = 0; 
          
          answered = false;
          selectedOption = null;
        });
      }
    } catch (e) {
      print("Error generating options: $e");
      // Recovery: try to move to next or just show what we have
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error preparing question: $e")));
      }
    }
  }

  void _submitAnswer(int optionIndex) {
    if (answered) return;

    setState(() {
      answered = true;
      selectedOption = optionIndex;
      if (optionIndex == correctOptionIndex) score++;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (currentIndex < questions.length - 1) {
        setState(() => currentIndex++);
        _generateOptions();
      } else {
        _showScoreDialog();
      }
    });
  }

  void _showScoreDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Quiz Completed!"),
        content: Text("You scored $score / ${questions.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadQuiz();
            },
            child: const Text("Play Again"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Quiz Mode", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: Background(
        colors: const [Color(0xFF845EC2), Color(0xFFD65DB1)],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
        child: isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Text(
                     "Question ${currentIndex + 1} / ${questions.length}",
                     textAlign: TextAlign.center,
                     style: const TextStyle(color: Colors.white70, fontSize: 16),
                   ),
                   const SizedBox(height: 20),
                   
                   Container(
                     padding: const EdgeInsets.all(30),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)]
                     ),
                     child: Column(
                       children: [
                         const Text("Translate this:", style: TextStyle(color: Colors.grey)),
                         const SizedBox(height: 10),
                         Text(
                           questions[currentIndex]['nicobarese'] ?? '',
                           style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                           textAlign: TextAlign.center,
                         ),
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 40),
                   
                   ...List.generate(4, (index) {
                     Color color = Colors.white;
                     if (answered) {
                       if (index == correctOptionIndex) {
                         color = Colors.greenAccent;
                       } else if (index == selectedOption) {
                         color = Colors.redAccent;
                       }
                     }
                     
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 12),
                       child: ElevatedButton(
                         style: ElevatedButton.styleFrom(
                           backgroundColor: color,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         onPressed: () => _submitAnswer(index),
                         child: Text(
                           options.length > index ? options[index] : '',
                           style: TextStyle(
                             fontSize: 18, 
                             color: answered ? Colors.white : Colors.black87
                           ),
                         ),
                       ),
                     );
                   }),
                ],
              ),
      ),
    );
  }
}
