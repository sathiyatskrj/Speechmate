import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// KAHOOT SERVICE — Live Offline Classroom Quiz Engine
// Teacher broadcasts questions via local mesh, students answer in real-time
// ============================================================================

enum QuizRole { teacher, student }
enum QuizState { lobby, question, answer, results, finished }

class KahootQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final int timeLimitSeconds;

  KahootQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.timeLimitSeconds = 15,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'timeLimitSeconds': timeLimitSeconds,
  };

  factory KahootQuestion.fromJson(Map<String, dynamic> json) => KahootQuestion(
    question: json['question'],
    options: List<String>.from(json['options']),
    correctIndex: json['correctIndex'],
    timeLimitSeconds: json['timeLimitSeconds'] ?? 15,
  );
}

class KahootPlayerScore {
  final String name;
  final String avatar;
  int totalScore;
  int correctAnswers;
  int currentStreak;

  KahootPlayerScore({
    required this.name,
    this.avatar = '👤',
    this.totalScore = 0,
    this.correctAnswers = 0,
    this.currentStreak = 0,
  });
}

class KahootService {
  static final KahootService _instance = KahootService._internal();
  factory KahootService() => _instance;
  KahootService._internal();

  QuizRole _role = QuizRole.student;
  QuizState _state = QuizState.lobby;
  List<KahootQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<String, KahootPlayerScore> _scores = {};
  Timer? _questionTimer;
  int _timeRemaining = 0;
  final _stateController = StreamController<QuizState>.broadcast();

  QuizRole get role => _role;
  QuizState get state => _state;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get totalQuestions => _questions.length;
  int get timeRemaining => _timeRemaining;
  KahootQuestion? get currentQuestion =>
      _currentQuestionIndex < _questions.length ? _questions[_currentQuestionIndex] : null;
  Map<String, KahootPlayerScore> get scores => _scores;
  Stream<QuizState> get stateStream => _stateController.stream;

  /// Create a new quiz session as teacher
  void createSession(List<KahootQuestion> questions) {
    _role = QuizRole.teacher;
    _questions = questions;
    _currentQuestionIndex = 0;
    _scores.clear();
    _state = QuizState.lobby;
    _stateController.add(_state);
    debugPrint('[Kahoot] Session created with ${questions.length} questions.');
  }

  /// Join a quiz session as student
  void joinSession(String playerName, {String avatar = '👤'}) {
    _role = QuizRole.student;
    _scores[playerName] = KahootPlayerScore(name: playerName, avatar: avatar);
    debugPrint('[Kahoot] $playerName joined the quiz.');
  }

  /// Start broadcasting the first question (teacher only)
  void startQuiz() {
    if (_role != QuizRole.teacher || _questions.isEmpty) return;
    _currentQuestionIndex = 0;
    _showNextQuestion();
  }

  void _showNextQuestion() {
    if (_currentQuestionIndex >= _questions.length) {
      _state = QuizState.finished;
      _stateController.add(_state);
      _saveResults();
      return;
    }

    _state = QuizState.question;
    _stateController.add(_state);

    final q = _questions[_currentQuestionIndex];
    _timeRemaining = q.timeLimitSeconds;

    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeRemaining--;
      if (_timeRemaining <= 0) {
        timer.cancel();
        _revealAnswer();
      }
    });
  }

  /// Submit an answer (student)
  /// Points = correctness × speed bonus (faster = more points, max 1000)
  void submitAnswer(String playerName, int selectedIndex) {
    final q = currentQuestion;
    if (q == null) return;

    final score = _scores[playerName];
    if (score == null) return;

    final isCorrect = selectedIndex == q.correctIndex;
    if (isCorrect) {
      // Speed bonus: max 1000 points, scaled by time remaining
      final speedRatio = _timeRemaining / q.timeLimitSeconds;
      final points = (500 + (500 * speedRatio)).round();
      score.totalScore += points;
      score.correctAnswers++;
      score.currentStreak++;
      // Streak bonus
      if (score.currentStreak >= 3) {
        score.totalScore += 100; // Streak bonus
      }
    } else {
      score.currentStreak = 0;
    }
  }

  void _revealAnswer() {
    _state = QuizState.answer;
    _stateController.add(_state);

    // Auto advance to next question after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _currentQuestionIndex++;
      _showNextQuestion();
    });
  }

  /// Advance to answer reveal (teacher manual control)
  void revealAnswer() => _revealAnswer();

  /// Get sorted leaderboard
  List<KahootPlayerScore> getLeaderboard() {
    final list = _scores.values.toList();
    list.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return list;
  }

  /// Save quiz results to SharedPreferences
  Future<void> _saveResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('kahoot_history') ?? [];
      final result = {
        'date': DateTime.now().toIso8601String(),
        'questions': _questions.length,
        'players': _scores.length,
        'topScore': getLeaderboard().isNotEmpty ? getLeaderboard().first.totalScore : 0,
      };
      history.add(jsonEncode(result));
      await prefs.setStringList('kahoot_history', history);
    } catch (e) {
      debugPrint('[Kahoot] Save error: $e');
    }
  }

  /// Generate sample quiz questions from Nicobarese vocabulary
  static List<KahootQuestion> generateVocabQuiz({int count = 10}) {
    final rng = Random();
    final allWords = [
      {'en': 'Water', 'ni': 'Mak'},
      {'en': 'Fire', 'ni': 'Tāmeūyö'},
      {'en': 'Tree', 'ni': 'Chōn'},
      {'en': 'Fish', 'ni': 'Kāk'},
      {'en': 'Dog', 'ni': 'Am'},
      {'en': 'Mother', 'ni': 'Kikanö Yöng Nyiö'},
      {'en': 'Father', 'ni': 'Kikònyö Yöng'},
      {'en': 'Sun', 'ni': 'Kaha'},
      {'en': 'Sea', 'ni': 'Mai'},
      {'en': 'Friend', 'ni': 'Hòl'},
      {'en': 'Happy', 'ni': 'Ramölön'},
      {'en': 'Sad', 'ni': 'Hārivlön'},
      {'en': 'Head', 'ni': 'Kūi'},
      {'en': 'Hand', 'ni': 'Kūlòich'},
      {'en': 'Village', 'ni': 'Tūhet'},
      {'en': 'Island', 'ni': 'Panam'},
      {'en': 'Coconut', 'ni': 'Kūk'},
      {'en': 'Mountain', 'ni': 'Marōngö'},
      {'en': 'School', 'ni': 'Iskul'},
      {'en': 'Book', 'ni': 'Tö hakööpö Mat Lipööre'},
    ];

    allWords.shuffle(rng);
    final selected = allWords.take(count.clamp(1, allWords.length)).toList();

    return selected.map((word) {
      // Build 3 wrong options
      final wrongOptions = allWords
          .where((w) => w['ni'] != word['ni'])
          .toList()
        ..shuffle(rng);
      final options = [
        word['ni']!,
        ...wrongOptions.take(3).map((w) => w['ni']!),
      ]..shuffle(rng);

      return KahootQuestion(
        question: 'What is "${word['en']}" in Nicobarese?',
        options: options,
        correctIndex: options.indexOf(word['ni']!),
        timeLimitSeconds: 15,
      );
    }).toList();
  }

  void dispose() {
    _questionTimer?.cancel();
    _stateController.close();
  }
}
