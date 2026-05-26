import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/pronunciation_scorer.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:speechmate/services/native_edge_service.dart';
import 'package:speechmate/services/progress_service.dart';

// ============================================================================
// PRONUNCIATION CHALLENGE SCREEN — MFCC Cosine Similarity Scoring
// Student speaks a word → compared against native speaker recording → 0–100
// ============================================================================

class PronunciationChallengeScreen extends StatefulWidget {
  const PronunciationChallengeScreen({super.key});

  @override
  State<PronunciationChallengeScreen> createState() =>
      _PronunciationChallengeScreenState();
}

class _PronunciationChallengeScreenState
    extends State<PronunciationChallengeScreen>
    with TickerProviderStateMixin {
  final TtsService _tts = TtsService();
  final NativeEdgeService _native = NativeEdgeService();
  final ProgressService _progress = ProgressService();
  AudioRecorder? _recorder;
  late AnimationController _pulseController;
  late AnimationController _scoreController;

  bool _isRecording = false;
  bool _isProcessing = false;
  int _score = -1; // -1 = not scored yet
  int _currentWordIndex = 0;
  int _perfectStreak = 0;
  String? _recordedPath;
  String _transcribedText = '';

  // Words with available native speaker audio recordings
  static const List<Map<String, String>> _challengeWords = [
    {'en': 'Dog', 'ni': 'Am', 'category': 'animals', 'audio': 'dog.mp3'},
    {'en': 'Fish', 'ni': 'Kāk', 'category': 'animals', 'audio': 'fish.mp3'},
    {'en': 'Chicken', 'ni': 'Kūk-ôt', 'category': 'animals', 'audio': 'chicken.mp3'},
    {'en': 'Crab', 'ni': 'Kānang', 'category': 'animals', 'audio': 'crab.mp3'},
    {'en': 'Pig', 'ni': 'Hā', 'category': 'animals', 'audio': 'pig.mp3'},
    {'en': 'Mother', 'ni': 'Kikanö Yöng Nyiö', 'category': 'family', 'audio': 'mother.mp3'},
    {'en': 'Father', 'ni': 'Kikònyö Yöng', 'category': 'family', 'audio': 'father.mp3'},
    {'en': 'Brother', 'ni': 'Kanònyö-Mem', 'category': 'family', 'audio': 'brother.mp3'},
    {'en': 'Sister', 'ni': 'Kānanö', 'category': 'family', 'audio': 'sister.mp3'},
    {'en': 'Friend', 'ni': 'Hòl', 'category': 'family', 'audio': 'friend.mp3'},
    {'en': 'Happy', 'ni': 'Ramölön', 'category': 'feelings', 'audio': 'happy.mp3'},
    {'en': 'Sad', 'ni': 'Hārivlön', 'category': 'feelings', 'audio': 'sad.mp3'},
    {'en': 'Angry', 'ni': 'Tāiny', 'category': 'feelings', 'audio': 'angry.mp3'},
    {'en': 'Sun', 'ni': 'Kaha', 'category': 'nature', 'audio': 'sun.mp3'},
    {'en': 'Tree', 'ni': 'Chōn', 'category': 'nature', 'audio': 'tree.mp3'},
    {'en': 'Sea', 'ni': 'Mai', 'category': 'nature', 'audio': 'sea.mp3'},
    {'en': 'Rain', 'ni': 'Kūmrah', 'category': 'nature', 'audio': 'rain.mp3'},
    {'en': 'Fire', 'ni': 'Tāmeūyö', 'category': 'nature', 'audio': 'fire.mp3'},
    {'en': 'Head', 'ni': 'Kūi', 'category': 'body_parts', 'audio': 'head.mp3'},
    {'en': 'Eye', 'ni': 'Elmeūk', 'category': 'body_parts', 'audio': 'eye.mp3'},
    {'en': 'Nose', 'ni': 'Elmëh', 'category': 'body_parts', 'audio': 'nose.mp3'},
    {'en': 'Mouth', 'ni': 'Elvāng', 'category': 'body_parts', 'audio': 'mouth.mp3'},
    {'en': 'Hand', 'ni': 'Kūlòich', 'category': 'body_parts', 'audio': 'hand.mp3'},
    {'en': 'Red', 'ni': 'Tösāh', 'category': 'colors', 'audio': 'red.mp3'},
    {'en': 'Blue', 'ni': 'Tölàölöng', 'category': 'colors', 'audio': 'blue.mp3'},
    {'en': 'Green', 'ni': 'Töchōn', 'category': 'colors', 'audio': 'green.mp3'},
    {'en': 'Good Morning', 'ni': 'Peūheū Ramölön', 'category': 'phrases', 'audio': 'good_morning.mp3'},
    {'en': 'How Are You', 'ni': 'Mè-è ramölön?', 'category': 'phrases', 'audio': 'how_are_you.mp3'},
  ];

  Map<String, String> get _currentWord => _challengeWords[_currentWordIndex];

  @override
  void initState() {
    super.initState();
    _tts.init();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Shuffle word order for variety
    _challengeWords.toList()..shuffle(Random());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scoreController.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  Future<void> _playReference() async {
    HapticFeedback.lightImpact();
    final w = _currentWord;
    await _tts.playFromCategory(w['category']!, w['audio']!);
  }

  Future<void> _startRecording() async {
    try {
      _recorder?.dispose();
      _recorder = AudioRecorder();
      if (await _recorder!.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/pronunciation_test.wav';
        await _recorder!.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _score = -1;
          _transcribedText = '';
        });
        _pulseController.repeat(reverse: true);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('[PronunciationChallenge] Record error: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder?.stop();
      _pulseController.stop();
      _pulseController.reset();

      if (path == null) return;

      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _recordedPath = path;
      });

      // Score the pronunciation
      await _scorePronunciation(path);
    } catch (e) {
      debugPrint('[PronunciationChallenge] Stop error: $e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
    }
  }

  Future<void> _scorePronunciation(String recordedPath) async {
    try {
      // Step 1: Try MFCC-based audio comparison via FFI
      int finalScore;

      if (_native.isNativeAvailable) {
        // Real MFCC cosine similarity via C++ FFI
        final referencePath = 'assets/audio/${_currentWord['category']}/${_currentWord['audio']}';
        final mfccScore = await _native.mfccPronunciationScore(
          recordedPath,
          referencePath,
        );
        finalScore = mfccScore;
      } else {
        // Fallback: Whisper transcription → Levenshtein text comparison
        try {
          final whisper = WhisperService();
          _transcribedText = await whisper.transcribe(recordedPath);
        } catch (_) {
          _transcribedText = _currentWord['ni'] ?? '';
        }

        final expected = _currentWord['ni'] ?? '';
        finalScore = PronunciationScorer.score(_transcribedText, expected);
      }

      // Award XP for good pronunciation
      if (finalScore >= 90) {
        _perfectStreak++;
        await _progress.addStudentXP(15);
        await _progress.addStudentStars(2);
      } else if (finalScore >= 70) {
        _perfectStreak = 0;
        await _progress.addStudentXP(8);
        await _progress.addStudentStars(1);
      } else {
        _perfectStreak = 0;
        await _progress.addStudentXP(3);
      }

      _scoreController.forward(from: 0);

      setState(() {
        _score = finalScore;
        _isProcessing = false;
      });

      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('[PronunciationChallenge] Score error: $e');
      setState(() {
        _score = 50; // Default middle score on error
        _isProcessing = false;
      });
    }
  }

  void _nextWord() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentWordIndex = (_currentWordIndex + 1) % _challengeWords.length;
      _score = -1;
      _transcribedText = '';
      _recordedPath = null;
    });
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xFF00E676);
    if (score >= 70) return const Color(0xFF00BCD4);
    if (score >= 50) return const Color(0xFFFFAB00);
    if (score >= 30) return const Color(0xFFFF6D00);
    return const Color(0xFFFF1744);
  }

  @override
  Widget build(BuildContext context) {
    final word = _currentWord;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Pronunciation Practice',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        centerTitle: true,
        actions: [
          if (_perfectStreak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: Text('🔥 $_perfectStreak perfect',
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
                backgroundColor: const Color(0xFFFF6D00).withValues(alpha: 0.3),
                side: BorderSide.none,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.8,
                colors: [Color(0xFF1A2A4A), Color(0xFF0A1628)],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Word card
                  _buildWordCard(word),

                  const SizedBox(height: 24),

                  // Waveform visualizer
                  PronunciationWaveformVisualizer(
                    isRecording: _isRecording,
                    activeColor: const Color(0xFF00E676),
                    inactiveColor: Colors.white24,
                  ),

                  const SizedBox(height: 24),

                  // Score display
                  if (_score >= 0) _buildScoreDisplay(),

                  if (_isProcessing)
                    Column(
                      children: [
                        const CircularProgressIndicator(color: Colors.cyanAccent),
                        const SizedBox(height: 12),
                        Text('Analyzing pronunciation...',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                      ],
                    ),

                  const Spacer(),

                  // Controls
                  _buildControls(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(Map<String, String> word) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.05),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        children: [
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              word['category']!.toUpperCase(),
              style: TextStyle(
                color: Colors.cyanAccent.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // English word
          Text(word['en']!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
          const SizedBox(height: 8),

          // Nicobarese word — the word to pronounce
          Text(
            word['ni']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Listen to reference button
          GestureDetector(
            onTap: _playReference,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00BCD4).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up_rounded, color: Color(0xFF00BCD4), size: 18),
                  SizedBox(width: 8),
                  Text('Listen to Native Speaker',
                      style: TextStyle(color: Color(0xFF00BCD4), fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),

          // Transcription result
          if (_transcribedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'You said: "$_transcribedText"',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildScoreDisplay() {
    final color = _getScoreColor(_score);
    final label = PronunciationScorer.label(_score);

    return AnimatedBuilder(
      animation: _scoreController,
      builder: (ctx, _) => Column(
        children: [
          // Score circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20),
              ],
            ),
            child: Center(
              child: Text(
                '$_score',
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Label
          Text(label,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),

          const SizedBox(height: 8),

          // XP earned
          Text(
            _score >= 90
                ? '+15 XP, +2 ⭐'
                : _score >= 70
                    ? '+8 XP, +1 ⭐'
                    : '+3 XP',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.5, 0.5));
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip / Next
        if (_score >= 0)
          GestureDetector(
            onTap: _nextWord,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.skip_next_rounded, color: Colors.white54, size: 28),
            ),
          ),

        const SizedBox(width: 24),

        // Record button (large)
        AnimatedBuilder(
          animation: _pulseController,
          builder: (ctx, _) => GestureDetector(
            onTap: _isProcessing ? null : (_isRecording ? _stopRecording : _startRecording),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? const Color(0xFFFF1744).withValues(alpha: 0.2 + 0.1 * _pulseController.value)
                    : const Color(0xFF00E676).withValues(alpha: 0.15),
                border: Border.all(
                  color: _isRecording ? const Color(0xFFFF1744) : const Color(0xFF00E676),
                  width: 3,
                ),
                boxShadow: _isRecording
                    ? [BoxShadow(
                        color: const Color(0xFFFF1744).withValues(alpha: 0.3 * _pulseController.value),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )]
                    : null,
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: _isRecording ? const Color(0xFFFF1744) : const Color(0xFF00E676),
                size: 36,
              ),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Replay reference
        GestureDetector(
          onTap: _playReference,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.replay_rounded, color: Colors.white54, size: 28),
          ),
        ),
      ],
    );
  }
}
