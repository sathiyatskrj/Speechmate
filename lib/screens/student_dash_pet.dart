import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/native_edge_service.dart';
import 'package:speechmate/services/progress_service.dart';
import 'package:speechmate/core/app_strings.dart';

// ============================================================================
// KID-FRIENDLY VIRTUAL PET COMPANION (Tamagotchi-Inspired)
// Extracted from student_dash.dart for maintainability
// Upgraded with native cognitive FFI brain, haptics, vocal stage-pitch morphing,
// and vocabulary training quests.
// ============================================================================

/// Pet mood determined by stats
enum PetMood { happy, neutral, hungry, sleepy, excited, sick }

/// Evolution stage driven by XP
enum PetStage { egg, baby, teen, adult, legendary }

/// An interactive virtual pet with mood states, hunger/energy stats,
/// XP-driven evolution, dynamic behaviors, and speech bubbles.
/// Inspired by Study Buddy, Catode32, Codachi, and Tamagotchi.
class VirtualPetCompanion extends StatefulWidget {
  final VoidCallback? onPetHappy;
  const VirtualPetCompanion({super.key, this.onPetHappy});

  @override
  State<VirtualPetCompanion> createState() => _VirtualPetCompanionState();
}

class _VirtualPetCompanionState extends State<VirtualPetCompanion>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _heartController;
  final TtsService _ttsService = TtsService();
  final math.Random _rng = math.Random();
  final NativeEdgeService _nativeService = NativeEdgeService();

  // ── Tamagotchi Stats (0–100) ──
  double _happiness = 70;
  double _hunger = 60;   // 100 = full, 0 = starving
  double _energy = 80;

  // ── Evolution ──
  int _petXP = 0;
  PetStage _stage = PetStage.baby;

  // ── Mood & Behavior ──
  PetMood _mood = PetMood.neutral;
  String _currentBehavior = 'idle';
  bool _showSpeech = false;
  String _speechText = '';
  bool _showHearts = false;
  bool _showZzz = false;
  int _tapCount = 0;

  // ── Pet identity ──
  int _petIndex = 0;

  // Vocabulary Quest Data
  static const Map<String, String> _vocabQuests = {
    'Water': 'röt',
    'Hello': 'ä',
    'House': 'tuhet',
    'Sun': 'kaha',
    'Tree': 'ö',
    'Dog': 'am',
  };

  // Evolution stages: each stage has its own set of animals
  static const List<List<String>> _stageAnimals = [
    ['🥚'],                                        // egg
    ['🐣', '🐥', '🐤'],                             // baby
    ['🦊', '🐶', '🐱', '🐰', '🐹'],                 // teen
    ['🐯', '🦁', '🐼', '🐨', '🦝', '🐺'],           // adult
    ['🦄', '🐉', '🦅', '🐬', '🦩', '🦋', '🌟'],     // legendary
  ];

  static const List<Color> _stageColors = [
    Color(0xFF9E9E9E),   // egg - gray
    Color(0xFFFFB74D),   // baby - warm orange
    Color(0xFFEC407A),   // teen - pink
    Color(0xFF7C4DFF),   // adult - purple
    Color(0xFFFFD700),   // legendary - gold
  ];

  // ── Speech lines per mood ──
  List<String> get _moodSpeechLines {
    switch (_mood) {
      case PetMood.happy:
        return [AppStrings.get('petHappySpeech'), '🎉 Woohoo!', '💖 Love you!', '✨ Amazing!'];
      case PetMood.hungry:
        return ['🍕 Feed me!', '😋 Hungry...', '🍎 Snack time?'];
      case PetMood.sleepy:
        return ['😴 So tired...', '💤 Zzz...', '🌙 Nap time?'];
      case PetMood.excited:
        return ['🚀 Let\'s GO!', '⚡ ZOOMIES!', '🎮 Play time!'];
      case PetMood.sick:
        return ['🤒 Not great...', '💊 Need rest...'];
      case PetMood.neutral:
        return [AppStrings.get('petHappySpeech'), '👋 Hi there!', '🌈 Nice day!'];
    }
  }

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _nativeService.petBrainInit('CognitiveSpeechBuddy');
    _bounceController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _heartController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _loadPetState();
    _startLifecycleLoop();
  }

  /// Load XP from ProgressService to determine evolution stage
  Future<void> _loadPetState() async {
    final stats = await ProgressService().getProgressStats();
    final totalXP = (stats['wordsLearned'] ?? 0) * 10;
    if (mounted) {
      setState(() {
        _petXP = totalXP;
        _stage = _calculateStage(totalXP);
        _updateMood();
      });
    }
  }

  PetStage _calculateStage(int xp) {
    if (xp >= 500) return PetStage.legendary;
    if (xp >= 200) return PetStage.adult;
    if (xp >= 50) return PetStage.teen;
    if (xp >= 10) return PetStage.baby;
    return PetStage.egg;
  }

  /// Passive stat decay every 30s connected to native petBrain JNI/FFI layer
  void _startLifecycleLoop() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;

      final decayStats = await _nativeService.petBrainTickDecay(_hunger, _happiness, _energy, 0.0083);
      final computedMood = await _nativeService.petBrainCalculateMood(
        decayStats['hunger'] ?? _hunger,
        decayStats['happiness'] ?? _happiness,
        decayStats['energy'] ?? _energy,
      );

      setState(() {
        _hunger = decayStats['hunger'] ?? _hunger;
        _happiness = decayStats['happiness'] ?? _happiness;
        _energy = decayStats['energy'] ?? _energy;

        if (computedMood == 'hungry') _mood = PetMood.hungry;
        else if (computedMood == 'sleepy') _mood = PetMood.sleepy;
        else if (computedMood == 'sick') _mood = PetMood.sick;
        else if (computedMood == 'happy') _mood = PetMood.happy;
        else _mood = PetMood.neutral;

        _pickAutoBehavior();
      });
      return mounted;
    });
  }

  void _updateMood() async {
    final computedMood = await _nativeService.petBrainCalculateMood(_hunger, _happiness, _energy);
    setState(() {
      if (computedMood == 'hungry') _mood = PetMood.hungry;
      else if (computedMood == 'sleepy') _mood = PetMood.sleepy;
      else if (computedMood == 'sick') _mood = PetMood.sick;
      else if (computedMood == 'happy') _mood = PetMood.happy;
      else _mood = PetMood.neutral;
    });
  }

  /// Auto-behaviors inspired by Catode32
  void _pickAutoBehavior() {
    if (_energy < 15) {
      _currentBehavior = 'sleeping';
      _showZzz = true;
    } else if (_hunger < 20) {
      _currentBehavior = 'begging';
    } else if (_happiness > 90 && _rng.nextDouble() > 0.7) {
      _currentBehavior = 'zoomies';
    } else {
      _currentBehavior = 'idle';
      _showZzz = false;
    }
  }

  /// Feed the pet (long press)
  void _feedPet() async {
    HapticFeedback.heavyImpact(); // Feeding haptic vibration pattern

    final fedStats = await _nativeService.petBrainFeedFood(_hunger, 'pizza');
    final computedMood = await _nativeService.petBrainCalculateMood(
      fedStats['hunger'] ?? _hunger,
      _happiness,
      _energy,
    );

    // Dynamic voice morphing: higher pitch for younger stages
    final double pitch = _stage == PetStage.baby ? 1.6 : _stage == PetStage.teen ? 1.3 : 1.0;
    _ttsService.speakEnglish('Yummy!', pitch: pitch);

    setState(() {
      _hunger = fedStats['hunger'] ?? _hunger;
      _happiness = (_happiness + 10).clamp(0.0, 100.0);
      _currentBehavior = 'eating';
      _speechText = '😋 Yummy!';
      _showSpeech = true;
      if (computedMood == 'hungry') _mood = PetMood.hungry;
      else if (computedMood == 'sleepy') _mood = PetMood.sleepy;
      else if (computedMood == 'sick') _mood = PetMood.sick;
      else if (computedMood == 'happy') _mood = PetMood.happy;
      else _mood = PetMood.neutral;
    });
    _hideSpeechAfterDelay();
  }

  /// Pet/play interaction (tap)
  void _petInteraction() async {
    _tapCount++;
    HapticFeedback.mediumImpact(); // Petting haptic vibration pattern
    if (widget.onPetHappy != null) widget.onPetHappy!();

    final playStats = await _nativeService.petBrainApplyInteraction(_happiness, _energy, 'pet');
    _petXP += 5;

    final evolveCheck = await _nativeService.petBrainEvolveCheck(_petXP, _stage.index);
    final bool evolved = evolveCheck['evolved'] ?? false;
    final int newStageIndex = evolveCheck['newStageIndex'] ?? _stage.index;
    final newStage = PetStage.values[newStageIndex];

    final computedMood = await _nativeService.petBrainCalculateMood(
      _hunger,
      playStats['happiness'] ?? _happiness,
      playStats['energy'] ?? _energy,
    );

    final double pitch = _stage == PetStage.baby ? 1.6 : _stage == PetStage.teen ? 1.3 : 1.0;

    setState(() {
      _happiness = playStats['happiness'] ?? _happiness;
      _energy = playStats['energy'] ?? _energy;
      _stage = newStage;
      _petIndex = (_petIndex + 1) % _stageAnimals[_stage.index].length;

      if (computedMood == 'hungry') _mood = PetMood.hungry;
      else if (computedMood == 'sleepy') _mood = PetMood.sleepy;
      else if (computedMood == 'sick') _mood = PetMood.sick;
      else if (computedMood == 'happy') _mood = PetMood.happy;
      else _mood = PetMood.neutral;

      if (evolved) {
        _speechText = '🎉 I EVOLVED!';
        _ttsService.speakEnglish('I evolved! Look at me!', pitch: 1.8);
      } else {
        final lines = _moodSpeechLines;
        _speechText = lines[_rng.nextInt(lines.length)];
        _ttsService.speakEnglish(_speechText, pitch: pitch);
      }
      _showSpeech = true;
      _showHearts = true;
      _currentBehavior = _tapCount % 5 == 0 ? 'zoomies' : 'playing';
    });

    _heartController.forward(from: 0);
    _bounceController.duration = const Duration(milliseconds: 250);
    _bounceController.repeat(reverse: true);
    _hideSpeechAfterDelay();
  }

  /// Launches the interactive vocabulary teach quest mini-game
  void _startVocabularyQuest() {
    HapticFeedback.lightImpact();
    final questEntries = _vocabQuests.entries.toList();
    final randomQuest = questEntries[_rng.nextInt(questEntries.length)];
    final String englishWord = randomQuest.key;
    final String correctNicobarese = randomQuest.value;

    // Build unique option choices
    final List<String> options = [correctNicobarese];
    final allNicobarese = _vocabQuests.values.toList();
    while (options.length < 3) {
      final randomWord = allNicobarese[_rng.nextInt(allNicobarese.length)];
      if (!options.contains(randomWord)) {
        options.add(randomWord);
      }
    }
    options.shuffle();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final Color stageColor = _stageColors[_stage.index];
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: stageColor, width: 2)),
          title: Row(
            children: [
              const Text('💡 Teach Me Language!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(_stageAnimals[_stage.index][_petIndex % _stageAnimals[_stage.index].length], style: const TextStyle(fontSize: 24)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Help me learn! What is the Nicobarese word for '$englishWord'?",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ...options.map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final bool isCorrect = opt == correctNicobarese;
                      HapticFeedback.mediumImpact();

                      if (isCorrect) {
                        final double multiplier = await _nativeService.petBrainGetVocabularyMultiplier(_petXP);
                        final int xpGained = (15 * multiplier).toInt();
                        _petXP += xpGained;

                        final evolveCheck = await _nativeService.petBrainEvolveCheck(_petXP, _stage.index);
                        final bool evolved = evolveCheck['evolved'] ?? false;
                        final newStage = PetStage.values[evolveCheck['newStageIndex'] ?? _stage.index];

                        setState(() {
                          _happiness = (_happiness + 20).clamp(0.0, 100.0);
                          _stage = newStage;
                          _speechText = '🎉 Correct! +$xpGained XP';
                          _showSpeech = true;
                          _showHearts = true;
                        });
                        final double pitch = _stage == PetStage.baby ? 1.6 : _stage == PetStage.teen ? 1.3 : 1.0;
                        _ttsService.speakEnglish(evolved ? 'I evolved! You taught me so well!' : 'Correct! Thank you!', pitch: pitch);
                      } else {
                        setState(() {
                          _happiness = (_happiness - 5).clamp(0.0, 100.0);
                          _speechText = '😢 Oh, close! Teach me again!';
                          _showSpeech = true;
                        });
                        final double pitch = _stage == PetStage.baby ? 1.6 : _stage == PetStage.teen ? 1.3 : 1.0;
                        _ttsService.speakEnglish('Oops, close! Let\'s try again!', pitch: pitch);
                      }
                      _heartController.forward(from: 0);
                      _bounceController.duration = const Duration(milliseconds: 250);
                      _bounceController.repeat(reverse: true);
                      _hideSpeechAfterDelay();
                    },
                    child: Text(opt, style: TextStyle(color: stageColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ],
          ),
        );
      }
    );
  }

  void _hideSpeechAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSpeech = false;
          _showHearts = false;
          _showZzz = false;
          _currentBehavior = 'idle';
        });
        _bounceController.duration = const Duration(seconds: 2);
        _bounceController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _heartController.dispose();
    _ttsService.dispose();
    _nativeService.petBrainDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColors[_stage.index];
    final animals = _stageAnimals[_stage.index];
    final currentAnimal = animals[_petIndex % animals.length];
    final bounceHeight = _currentBehavior == 'zoomies' ? 25.0 : 15.0;

    return Positioned(
      bottom: 20,
      right: 20,
      child: GestureDetector(
        onTap: _petInteraction,
        onLongPress: _feedPet,
        child: AnimatedBuilder(
          animation: _bounceController,
          builder: (context, child) {
            final dx = _currentBehavior == 'zoomies'
                ? math.sin(_bounceController.value * math.pi * 4) * 8
                : 0.0;
            return Transform.translate(
              offset: Offset(dx,
                  -bounceHeight * Curves.easeInOutSine.transform(_bounceController.value)),
              child: child,
            );
          },
          child: SizedBox(
            width: 120,
            height: 155,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // ── Speech Bubble ──
                if (_showSpeech)
                  Positioned(
                    top: -15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Text(_speechText,
                          style: TextStyle(color: stageColor, fontWeight: FontWeight.bold, fontSize: 10),
                          textAlign: TextAlign.center),
                    ).animate().scale(curve: Curves.elasticOut),
                  ),

                // ── Floating Hearts ──
                if (_showHearts)
                  ...List.generate(3, (i) => Positioned(
                    bottom: 60 + i * 15.0,
                    right: 10 + i * 12.0,
                    child: AnimatedBuilder(
                      animation: _heartController,
                      builder: (_, __) => Opacity(
                        opacity: (1 - _heartController.value).clamp(0, 1),
                        child: Transform.translate(
                          offset: Offset(0, -30 * _heartController.value),
                          child: const Text('❤️', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  )),

                // ── Zzz for sleeping ──
                if (_showZzz)
                  Positioned(
                    top: 15,
                    right: 5,
                    child: const Text('💤', style: TextStyle(fontSize: 20))
                        .animate(onPlay: (c) => c.repeat())
                        .fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms),
                  ),

                // ── Teach Word dynamic light bulb button ──
                Positioned(
                  top: 15,
                  left: -5,
                  child: Tooltip(
                    message: 'Teach Me Vocabulary',
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: IconButton(
                        icon: const Icon(Icons.lightbulb_outline, size: 14, color: Colors.amberAccent),
                        onPressed: _startVocabularyQuest,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

                // ── Pet Body ──
                Positioned(
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pet avatar
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: stageColor.withValues(alpha: 0.5),
                              blurRadius: _currentBehavior == 'zoomies' ? 30 : 20,
                              spreadRadius: _currentBehavior == 'zoomies' ? 5 : 0,
                              offset: const Offset(0, 8),
                            )
                          ],
                          border: Border.all(color: stageColor, width: 3),
                        ),
                        child: Center(
                          child: Text(currentAnimal,
                              style: const TextStyle(fontSize: 44)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // ── Mini stat bars ──
                      SizedBox(
                        width: 70,
                        child: Column(
                          children: [
                            _buildMiniBar('❤️', _happiness, Colors.pinkAccent),
                            const SizedBox(height: 2),
                            _buildMiniBar('🍕', _hunger, Colors.orangeAccent),
                            const SizedBox(height: 2),
                            _buildMiniBar('⚡', _energy, Colors.cyan),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Stage badge ──
                Positioned(
                  bottom: 70,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: stageColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _stage.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBar(String emoji, double value, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 8)),
        const SizedBox(width: 2),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                value < 25 ? Colors.redAccent : color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
