import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/progress_service.dart';
import 'package:speechmate/core/app_strings.dart';

// ============================================================================
// KID-FRIENDLY VIRTUAL PET COMPANION (Tamagotchi-Inspired)
// Extracted from student_dash.dart for maintainability
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

  /// Passive stat decay every 30s (Tamagotchi lifecycle)
  void _startLifecycleLoop() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      setState(() {
        _hunger = (_hunger - 2).clamp(0, 100);
        _energy = (_energy - 1).clamp(0, 100);
        if (_hunger < 30) _happiness = (_happiness - 3).clamp(0, 100);
        _updateMood();
        _pickAutoBehavior();
      });
      return mounted;
    });
  }

  void _updateMood() {
    if (_hunger < 20) {
      _mood = PetMood.hungry;
    } else if (_energy < 20) {
      _mood = PetMood.sleepy;
    } else if (_happiness < 25) {
      _mood = PetMood.sick;
    } else if (_happiness > 85) {
      _mood = PetMood.excited;
    } else if (_happiness > 55) {
      _mood = PetMood.happy;
    } else {
      _mood = PetMood.neutral;
    }
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
  void _feedPet() {
    _ttsService.speakEnglish('Yummy!', pitch: 1.6);
    setState(() {
      _hunger = (_hunger + 25).clamp(0, 100);
      _happiness = (_happiness + 10).clamp(0, 100);
      _currentBehavior = 'eating';
      _speechText = '😋 Yummy!';
      _showSpeech = true;
      _updateMood();
    });
    _hideSpeechAfterDelay();
  }

  /// Pet/play interaction (tap)
  void _petInteraction() {
    _tapCount++;
    if (widget.onPetHappy != null) widget.onPetHappy!();

    // Gain XP from interaction
    _petXP += 5;
    final newStage = _calculateStage(_petXP);
    final evolved = newStage != _stage;

    setState(() {
      _happiness = (_happiness + 15).clamp(0, 100);
      _energy = (_energy - 3).clamp(0, 100);
      _stage = newStage;
      _petIndex = (_petIndex + 1) % _stageAnimals[_stage.index].length;
      _updateMood();

      if (evolved) {
        _speechText = '🎉 I EVOLVED!';
        _ttsService.speakEnglish('I evolved! Look at me!', pitch: 1.6);
      } else {
        final lines = _moodSpeechLines;
        _speechText = lines[_rng.nextInt(lines.length)];
        _ttsService.speakEnglish(_speechText, pitch: 1.6);
      }
      _showSpeech = true;
      _showHearts = true;
      _currentBehavior = _tapCount % 5 == 0 ? 'zoomies' : 'playing';
    });

    // Trigger heart animation
    _heartController.forward(from: 0);

    // Bounce faster during interaction
    _bounceController.duration = const Duration(milliseconds: 250);
    _bounceController.repeat(reverse: true);

    _hideSpeechAfterDelay();
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
            height: 140,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // ── Speech Bubble ──
                if (_showSpeech)
                  Positioned(
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Text(_speechText,
                          style: TextStyle(color: stageColor, fontWeight: FontWeight.bold, fontSize: 11),
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
