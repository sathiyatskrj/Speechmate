import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';
import '../services/smart_quiz_service.dart';
import '../services/logger_service.dart';
import '../core/app_colors.dart';
import '../widgets/background.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final DictionaryService dictionaryService = DictionaryService();
  final SmartQuizService smartQuizService = SmartQuizService();
  
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
      // Load dictionary first
      await dictionaryService.loadDictionary(DictionaryType.words);
      
      // ADAPTIVE LEARNING: Try to load missed words first
      List<Map<String, dynamic>> missed = [];
      try {
        missed = await smartQuizService.getMissedWords();
      } catch (_) {}
      
      List<Map<String, dynamic>> fresh = [];
      try {
        fresh = await dictionaryService.getRandomWords(5);
      } catch (_) {}
      
      // Mix 2 missed words (if any) with 3 fresh words
      List<Map<String, dynamic>> quizSet = [];
      if (missed.isNotEmpty) {
          missed.shuffle();
          quizSet.addAll(missed.take(2));
      }
      quizSet.addAll(fresh.take(5 - quizSet.length));
      quizSet.shuffle();
      
      // If still empty, use mock data so the quiz doesn't crash
      if (quizSet.isEmpty) {
        quizSet = [
          {"english": "Hello", "nicobarese": "Harao"},
          {"english": "Water", "nicobarese": "Dāk"},
          {"english": "Fish", "nicobarese": "Hīchā"},
          {"english": "House", "nicobarese": "Pati"},
          {"english": "Tree", "nicobarese": "Dāng"},
        ];
      }
      
      if (mounted) {
        setState(() {
          questions = quizSet;
          currentIndex = 0;
          score = 0;
          isLoading = false;
        });
        _generateOptions();
      }
    } catch (e) {
      LoggerService.error('Failed to load quiz', e);
      if (mounted) {
        // Fallback mock data
        setState(() {
          questions = [
            {"english": "Hello", "nicobarese": "Harao"},
            {"english": "Water", "nicobarese": "Dāk"},
            {"english": "Fish", "nicobarese": "Hīchā"},
          ];
          currentIndex = 0;
          score = 0;
          isLoading = false;
        });
        _generateOptions();
      }
    }
  }

  void _generateOptions() async {
    if (currentIndex >= questions.length || questions.isEmpty) return;

    try {
      final correctWord = questions[currentIndex];
      final correctEnglish = correctWord['english']?.toString() ?? 'Unknown';
      
      List<Map<String, dynamic>> wrong = [];
      try {
        wrong = await dictionaryService.getRandomWords(3);
      } catch (_) {}
      
      List<String> opts = [correctEnglish];
      for (var w in wrong) {
        final eng = w['english']?.toString() ?? '';
        if (eng.isNotEmpty && eng != correctEnglish) {
          opts.add(eng);
        }
      }
      
      // Ensure we have at least 3 options
      final mockOptions = ['Sun', 'Moon', 'Rain', 'Wind', 'Fire', 'Stone'];
      int mockIdx = 0;
      while (opts.length < 4 && mockIdx < mockOptions.length) {
        if (!opts.contains(mockOptions[mockIdx])) {
          opts.add(mockOptions[mockIdx]);
        }
        mockIdx++;
      }
      
      opts.shuffle();
      
      if (mounted) {
        setState(() {
          options = opts;
          correctOptionIndex = opts.indexOf(correctEnglish);
          if (correctOptionIndex == -1) correctOptionIndex = 0; 
          answered = false;
          selectedOption = null;
        });
      }
    } catch (e) {
      LoggerService.error('Error generating quiz options', e);
    }
  }

  void _submitAnswer(int optionIndex) {
    if (answered || optionIndex >= options.length) return; // Safety check
    
    setState(() {
      answered = true;
      selectedOption = optionIndex;
      if (optionIndex == correctOptionIndex) {
        score++;
        smartQuizService.markCorrect(questions[currentIndex]);
      } else {
        smartQuizService.markMissed(questions[currentIndex]);
      }
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
        title: const Text("Language Quiz", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
               AppColors.studentAccent.withValues(alpha: 0.8),
               Colors.black
            ]
          )
        ),
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
                       color: Colors.white.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: Colors.white24),
                       boxShadow: [BoxShadow(blurRadius: 10, color: AppColors.studentAccent.withValues(alpha: 0.2))]
                     ),
                     child: Column(
                       children: [
                         const Text("Translate this:", style: TextStyle(color: Colors.white54)),
                         const SizedBox(height: 10),
                         Text(
                           questions[currentIndex]['nicobarese'] ?? questions[currentIndex]['great_andamanese'] ?? '',
                           style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                           textAlign: TextAlign.center,
                         ),
                       ],
                     ),
                   ),
                   
                   const SizedBox(height: 40),
                   
                   ...List.generate(options.length, (index) {
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
                           backgroundColor: color == Colors.white ? Colors.white.withValues(alpha: 0.2) : color,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color == Colors.white ? Colors.white24 : color)),
                         ),
                         onPressed: () => _submitAnswer(index),
                         child: Text(
                           options.length > index ? options[index] : '',
                           style: TextStyle(
                             fontSize: 18, 
                             color: Colors.white
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
