import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/kahoot_service.dart';

// ============================================================================
// KAHOOT QUIZ SCREEN — Live Offline Classroom Quiz UI
// Teacher creates + broadcasts, students answer with countdown timer
// ============================================================================

class KahootQuizScreen extends StatefulWidget {
  final QuizRole role;
  const KahootQuizScreen({super.key, this.role = QuizRole.teacher});

  @override
  State<KahootQuizScreen> createState() => _KahootQuizScreenState();
}

class _KahootQuizScreenState extends State<KahootQuizScreen>
    with TickerProviderStateMixin {
  final KahootService _kahoot = KahootService();
  late AnimationController _timerController;
  StreamSubscription? _stateSub;

  QuizState _state = QuizState.lobby;
  int? _selectedAnswer;
  bool _answered = false;

  // Kahoot signature colors for 4 answer blocks
  static const List<Color> _optionColors = [
    Color(0xFFE21B3C), // Red
    Color(0xFF1368CE), // Blue
    Color(0xFFD89E00), // Gold
    Color(0xFF26890C), // Green
  ];
  static const List<IconData> _optionIcons = [
    Icons.change_history_rounded,   // Triangle
    Icons.diamond_outlined,         // Diamond
    Icons.circle_outlined,          // Circle
    Icons.square_outlined,          // Square
  ];

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    if (widget.role == QuizRole.teacher) {
      // Generate quiz and create session
      final questions = KahootService.generateVocabQuiz(count: 8);
      _kahoot.createSession(questions);
      // Add simulated students
      _kahoot.joinSession('Asha K.', avatar: '🌺');
      _kahoot.joinSession('Ravi M.', avatar: '🐬');
      _kahoot.joinSession('Priya S.', avatar: '🦋');
      _kahoot.joinSession('Ajay T.', avatar: '🐢');
      _kahoot.joinSession('You (Teacher)', avatar: '🏫');
    }

    _stateSub = _kahoot.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _state = state;
          if (state == QuizState.question) {
            _selectedAnswer = null;
            _answered = false;
            final q = _kahoot.currentQuestion;
            if (q != null) {
              _timerController.duration = Duration(seconds: q.timeLimitSeconds);
              _timerController.forward(from: 0);
            }
            // Simulate AI students answering
            _simulateStudentAnswers();
          }
        });
      }
    });
  }

  void _simulateStudentAnswers() {
    final q = _kahoot.currentQuestion;
    if (q == null) return;
    // Simulated students answer with varying accuracy
    for (final name in ['Asha K.', 'Ravi M.', 'Priya S.', 'Ajay T.']) {
      Future.delayed(Duration(milliseconds: 2000 + (1000 * name.length % 5)), () {
        // 70% chance of correct answer
        final answer = (name.hashCode % 10 < 7) ? q.correctIndex : ((q.correctIndex + 1) % 4);
        _kahoot.submitAnswer(name, answer);
      });
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _stateSub?.cancel();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });
    _kahoot.submitAnswer('You (Teacher)', index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF46178F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          _state == QuizState.lobby
              ? 'Live Quiz'
              : _state == QuizState.finished
                  ? 'Results'
                  : 'Q${_kahoot.currentQuestionIndex + 1}/${_kahoot.totalQuestions}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF46178F), Color(0xFF2C0B5A)],
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case QuizState.lobby:
        return _buildLobby();
      case QuizState.question:
        return _buildQuestion();
      case QuizState.answer:
        return _buildAnswerReveal();
      case QuizState.results:
      case QuizState.finished:
        return _buildResults();
    }
  }

  Widget _buildLobby() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Nicobarese\nVocabulary Quiz',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            '${_kahoot.totalQuestions} questions · ${_kahoot.scores.length} players',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Player list
          ..._kahoot.scores.entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.value.avatar, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(e.value.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 15)),
              ],
            ),
          )),

          const SizedBox(height: 32),

          // Start button (teacher only)
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              _kahoot.startQuiz();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 20),
                ],
              ),
              child: const Text('START QUIZ',
                  style: TextStyle(
                      color: Color(0xFF46178F), fontSize: 18, fontWeight: FontWeight.w900)),
            ),
          ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _kahoot.currentQuestion!;

    return Column(
      children: [
        // Timer bar
        AnimatedBuilder(
          animation: _timerController,
          builder: (ctx, _) => LinearProgressIndicator(
            value: 1.0 - _timerController.value,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              _timerController.value > 0.7 ? Colors.red : Colors.greenAccent,
            ),
            minHeight: 6,
          ),
        ),

        // Time remaining
        Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedBuilder(
            animation: _timerController,
            builder: (ctx, _) => Text(
              '${_kahoot.timeRemaining}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        // Question
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20),
              ],
            ),
            child: Text(
              q.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ).animate().fadeIn().slideY(begin: -0.1),

        const Spacer(),

        // Answer grid (2×2)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildOptionBlock(q.options[0], 0),
                  const SizedBox(width: 8),
                  _buildOptionBlock(q.options[1], 1),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildOptionBlock(q.options[2], 2),
                  const SizedBox(width: 8),
                  _buildOptionBlock(q.options[3], 3),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOptionBlock(String text, int index) {
    final isSelected = _selectedAnswer == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: isSelected
                ? _optionColors[index].withValues(alpha: 0.5)
                : _optionColors[index],
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Colors.white, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: _optionColors[index].withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_optionIcons[index], color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.2),
    );
  }

  Widget _buildAnswerReveal() {
    final q = _kahoot.currentQuestion;
    if (q == null) return const SizedBox();
    final isCorrect = _selectedAnswer == q.correctIndex;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isCorrect ? '✅' : '❌',
            style: const TextStyle(fontSize: 64),
          ).animate().scale(begin: const Offset(0.3, 0.3)),
          const SizedBox(height: 16),
          Text(
            isCorrect ? 'Correct!' : 'Wrong!',
            style: TextStyle(
              color: isCorrect ? Colors.greenAccent : Colors.redAccent,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Answer: ${q.options[q.correctIndex]}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final leaderboard = _kahoot.getLeaderboard();

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('🏆', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        const Text('Final Results',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final player = leaderboard[index];
              final rankEmoji = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '${index + 1}';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Text(rankEmoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Text(player.avatar, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(player.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          Text('${player.correctAnswers}/${_kahoot.totalQuestions} correct',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      '${player.totalScore}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 80 * index)).slideX(begin: 0.1);
            },
          ),
        ),

        // Back button
        Padding(
          padding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Text('Done',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}
