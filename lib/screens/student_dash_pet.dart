import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/native_edge_service.dart';
import 'package:speechmate/services/progress_service.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:speechmate/widgets/tap_scale.dart';

// ============================================================================
// KID-FRIENDLY VIRTUAL PET COMPANION (Tamagotchi-Inspired)
// Upgraded with:
// - SharedPreferences Persistence (Stats & Custom Name)
// - Voice / Speech-to-Text FFI Brain Integration
// - Manual Sleep/Wake Cycles & Active Energy FFI Updates
// - Gamified Accessories Wardrobe & Shop using student Stars
// - Flying Food Animation & Pulsating Mic Animation
// - Mood Ambient Glow & Thinking Dots Indicators
// ============================================================================

enum PetMood { happy, neutral, hungry, sleepy, excited, sick }
enum PetStage { egg, baby, teen, adult, legendary }

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

  // ── Evolution & Identity ──
  int _petXP = 0;
  PetStage _stage = PetStage.baby;
  String _petName = 'CognitiveSpeechBuddy';
  int _petIndex = 0;

  // ── Mood & Behavior ──
  PetMood _mood = PetMood.neutral;
  String _currentBehavior = 'idle';
  bool _showSpeech = false;
  String _speechText = '';
  bool _showHearts = false;
  bool _showZzz = false;
  int _tapCount = 0;

  // ── Active Upgrades State ──
  bool _isSleeping = false;
  bool _isRecordingVoice = false;
  bool _isThinking = false;
  bool _isFeedingFlying = false;
  String? _equippedAccessory;
  List<String> _ownedAccessories = [];
  AudioRecorder? _audioRecorder;
  Timer? _lifecycleTimer;
  Timer? _speechTimer;

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

  // Speech lines per mood
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

  /// Load persisted state from SharedPreferences
  Future<void> _loadPetState() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await ProgressService().getProgressStats();

    if (mounted) {
      setState(() {
        _petName = prefs.getString('pet_name') ?? 'CognitiveSpeechBuddy';
        _equippedAccessory = prefs.getString('pet_equipped_accessory');
        _ownedAccessories = prefs.getStringList('pet_owned_accessories') ?? [];
        _happiness = prefs.getDouble('pet_happiness') ?? 70.0;
        _hunger = prefs.getDouble('pet_hunger') ?? 60.0;
        _energy = prefs.getDouble('pet_energy') ?? 80.0;
        _isSleeping = prefs.getBool('pet_is_sleeping') ?? false;

        final fallbackXP = (stats['wordsLearned'] ?? 0) * 10;
        _petXP = prefs.getInt('pet_xp') ?? fallbackXP;
        _stage = _calculateStage(_petXP);

        if (_isSleeping) {
          _currentBehavior = 'sleeping';
          _showZzz = true;
          _mood = PetMood.sleepy;
        } else {
          _currentBehavior = 'idle';
          _showZzz = false;
          _updateMood();
        }
      });
      await _nativeService.petBrainInit(_petName);
    }
  }

  /// Save current pet state to SharedPreferences
  Future<void> _savePetState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pet_name', _petName);
    if (_equippedAccessory != null) {
      await prefs.setString('pet_equipped_accessory', _equippedAccessory!);
    } else {
      await prefs.remove('pet_equipped_accessory');
    }
    await prefs.setStringList('pet_owned_accessories', _ownedAccessories);
    await prefs.setDouble('pet_happiness', _happiness);
    await prefs.setDouble('pet_hunger', _hunger);
    await prefs.setDouble('pet_energy', _energy);
    await prefs.setBool('pet_is_sleeping', _isSleeping);
    await prefs.setInt('pet_xp', _petXP);
  }

  PetStage _calculateStage(int xp) {
    if (xp >= 500) return PetStage.legendary;
    if (xp >= 200) return PetStage.adult;
    if (xp >= 50) return PetStage.teen;
    if (xp >= 10) return PetStage.baby;
    return PetStage.egg;
  }

  /// Passive stat decay JNI/FFI tick loop
  void _startLifecycleLoop() {
    _lifecycleTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // If sleeping, energy slowly recovers, hunger slowly increases
      if (_isSleeping) {
        final sleepStats = await _nativeService.petBrainUpdateSleep(_energy, _happiness, true);
        if (!mounted) return;
        setState(() {
          _energy = sleepStats['energy'] ?? (_energy + 5.0).clamp(0.0, 100.0);
          _happiness = sleepStats['happiness'] ?? (_happiness + 1.0).clamp(0.0, 100.0);
          _hunger = (_hunger + 2.0).clamp(0.0, 100.0);
          _savePetState();
        });
      } else {
        // Normal decay cycle
        final decayStats = await _nativeService.petBrainTickDecay(_hunger, _happiness, _energy, 0.0083);
        final computedMood = await _nativeService.petBrainCalculateMood(
          decayStats['hunger'] ?? _hunger,
          decayStats['happiness'] ?? _happiness,
          decayStats['energy'] ?? _energy,
        );

        if (!mounted) return;
        setState(() {
          _hunger = decayStats['hunger'] ?? _hunger;
          _happiness = decayStats['happiness'] ?? _happiness;
          _energy = decayStats['energy'] ?? _energy;

          _updateMoodFromState(computedMood);

          _pickAutoBehavior();
          _savePetState();
        });
      }
    });
  }

  void _updateMood() async {
    final computedMood = await _nativeService.petBrainCalculateMood(_hunger, _happiness, _energy);
    setState(() {
      _updateMoodFromState(computedMood);
    });
  }

  void _updateMoodFromState(String computedMood) {
    if (computedMood == 'hungry') {
      _mood = PetMood.hungry;
    } else if (computedMood == 'sleepy') {
      _mood = PetMood.sleepy;
    } else if (computedMood == 'sick') {
      _mood = PetMood.sick;
    } else if (computedMood == 'happy') {
      _mood = PetMood.happy;
    } else {
      _mood = PetMood.neutral;
    }
  }

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

  /// Triggers flying food emoji animation before actual feeding stats update
  void _triggerFeedAnimation() {
    if (_isSleeping) {
      _showTempSpeech("💤 Sshh... I'm sleeping!");
      return;
    }
    setState(() {
      _isFeedingFlying = true;
    });
  }

  /// Feed the pet FFI handler
  void _feedPet() async {
    HapticFeedback.heavyImpact();

    final fedStats = await _nativeService.petBrainFeedFood(_hunger, 'pizza');
    final computedMood = await _nativeService.petBrainCalculateMood(
      fedStats['hunger'] ?? _hunger,
      _happiness,
      _energy,
    );

    final double pitch = _stage == PetStage.baby ? 1.6 : _stage == PetStage.teen ? 1.3 : 1.0;
    _ttsService.speakEnglish('Yummy!', pitch: pitch);

    setState(() {
      _hunger = fedStats['hunger'] ?? _hunger;
      _happiness = (_happiness + 10).clamp(0.0, 100.0);
      _currentBehavior = 'eating';
      _speechText = '😋 Yummy!';
      _showSpeech = true;
      _updateMoodFromState(computedMood);
      _savePetState();
    });
    _hideSpeechAfterDelay();
  }

  /// Pet/play interaction (tap pet avatar)
  void _petInteraction() async {
    if (_isSleeping) {
      _showTempSpeech("💤 Sshh... I'm sleeping!");
      return;
    }
    _tapCount++;
    HapticFeedback.mediumImpact();
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

      _updateMoodFromState(computedMood);

      if (evolved) {
        _speechText = '🎉 I EVOLVED!';
        _ttsService.speakEnglish('I evolved! Look at me!', pitch: 1.8);
        if (widget.onPetHappy != null) widget.onPetHappy!(); // Double confetti blast
      } else {
        final lines = _moodSpeechLines;
        _speechText = lines[_rng.nextInt(lines.length)];
        _ttsService.speakEnglish(_speechText, pitch: pitch);
      }
      _showSpeech = true;
      _showHearts = true;
      _currentBehavior = _tapCount % 5 == 0 ? 'zoomies' : 'playing';
      _savePetState();
    });

    _heartController.forward(from: 0);
    _bounceController.duration = const Duration(milliseconds: 250);
    _bounceController.repeat(reverse: true);
    _hideSpeechAfterDelay();
  }

  /// Toggle manual sleep mode FFI update
  void _toggleSleep() async {
    HapticFeedback.mediumImpact();
    final bool newSleepState = !_isSleeping;

    final sleepStats = await _nativeService.petBrainUpdateSleep(_energy, _happiness, newSleepState);

    setState(() {
      _isSleeping = newSleepState;
      if (_isSleeping) {
        _currentBehavior = 'sleeping';
        _showZzz = true;
        _speechText = "😴 Good night!";
        _showSpeech = true;
        _energy = sleepStats['energy'] ?? (_energy + 25.0).clamp(0.0, 100.0);
        _happiness = sleepStats['happiness'] ?? (_happiness + 5.0).clamp(0.0, 100.0);
        _mood = PetMood.sleepy;
      } else {
        _currentBehavior = 'idle';
        _showZzz = false;
        _speechText = "☀️ Good morning!";
        _showSpeech = true;
        _mood = PetMood.neutral;
      }
      _savePetState();
    });

    final double pitch = _stage == PetStage.baby ? 1.6 : _stage == PetStage.teen ? 1.3 : 1.0;
    _ttsService.speakEnglish(_speechText, pitch: pitch);
    _hideSpeechAfterDelay();
  }

  /// Toggle microphone recording and process through Whisper & Pet FFI speech model
  Future<void> _toggleVoiceRecording() async {
    if (_isSleeping) {
      _showTempSpeech("💤 Sshh... I'm sleeping!");
      return;
    }

    if (_isRecordingVoice) {
      // Stop recording voice
      setState(() {
        _isRecordingVoice = false;
        _isThinking = true;
        _showSpeech = true;
      });

      try {
        final path = await _audioRecorder?.stop();
        if (path != null) {
          final whisperService = WhisperService();
          if (!whisperService.isAvailable) {
            await whisperService.initialize();
          }

          final text = await whisperService.transcribe(path);
          if (text.isNotEmpty) {
            final responseText = await _nativeService.petBrainProcessSpeech(text);
            setState(() {
              _speechText = responseText;
              _isThinking = false;
            });

            final double pitch = _stage == PetStage.baby ? 1.6 : _stage == PetStage.teen ? 1.3 : 1.0;
            _ttsService.speakEnglish(responseText, pitch: pitch);
            _hideSpeechAfterDelay();
          } else {
            setState(() {
              _speechText = "🤔 Didn't catch that...";
              _isThinking = false;
            });
            _hideSpeechAfterDelay();
          }
        }
      } catch (e) {
        debugPrint('[Pet Voice] Transcribe error: $e');
        setState(() {
          _speechText = "⚠️ Speech error";
          _isThinking = false;
        });
        _hideSpeechAfterDelay();
      }
    } else {
      // Start recording voice
      try {
        _audioRecorder?.dispose();
        _audioRecorder = AudioRecorder();
        if (await _audioRecorder!.hasPermission()) {
          final Directory appDocDir = await getTemporaryDirectory();
          final String filePath = '${appDocDir.path}/temp_pet_speech.wav';

          await _audioRecorder!.start(
            const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
            path: filePath,
          );

          setState(() {
            _isRecordingVoice = true;
            _speechText = "🎤 Listening...";
            _showSpeech = true;
          });
        } else {
          _showTempSpeech("❌ Mic permission denied");
        }
      } catch (e) {
        debugPrint('[Pet Voice] Start recording error: $e');
      }
    }
  }

  /// Launch Rename Pet input dialog
  void _renamePetDialog() {
    if (_isSleeping) {
      _showTempSpeech("💤 Sshh... I'm sleeping!");
      return;
    }

    final textController = TextEditingController(text: _petName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _stageColors[_stage.index], width: 1.5),
          ),
          title: const Text('✏️ Name Your Pet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter name...',
              hintStyle: const TextStyle(color: Colors.white30),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _stageColors[_stage.index])),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _stageColors[_stage.index], width: 2)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _stageColors[_stage.index],
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    _petName = newName;
                    _savePetState();
                  });
                  final navigator = Navigator.of(context);
                  await _nativeService.petBrainInit(newName);
                  navigator.pop();
                  _showTempSpeech('Hello, I am $_petName! 👋');
                }
              },
              child: const Text('Save'),
            )
          ],
        );
      }
    );
  }

  /// Open wardrobe/shop for purchasing accessories using stars
  void _openAccessoryShop() async {
    HapticFeedback.lightImpact();
    if (_isSleeping) {
      _showTempSpeech("💤 Sshh... I'm sleeping!");
      return;
    }

    final stats = await ProgressService().getProgressStats();
    final int currentStars = stats['studentStars'] ?? 0;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🛍️ Pet Shop & Wardrobe',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Text('⭐ ', style: TextStyle(fontSize: 14)),
                            Text(
                              '$currentStars Stars',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DRESS UP YOUR PET WITH STARS:',
                    style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildShopItem(
                    name: 'Sunglasses',
                    emoji: '😎',
                    cost: 10,
                    currentStars: currentStars,
                    setSheetState: setSheetState,
                  ),
                  _buildShopItem(
                    name: 'Crown',
                    emoji: '👑',
                    cost: 30,
                    currentStars: currentStars,
                    setSheetState: setSheetState,
                  ),
                  _buildShopItem(
                    name: 'Wizard Hat',
                    emoji: '🧙',
                    cost: 50,
                    currentStars: currentStars,
                    setSheetState: setSheetState,
                  ),
                  _buildShopItem(
                    name: 'Bowtie',
                    emoji: '🎀',
                    cost: 5,
                    currentStars: currentStars,
                    setSheetState: setSheetState,
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildShopItem({
    required String name,
    required String emoji,
    required int cost,
    required int currentStars,
    required StateSetter setSheetState,
  }) {
    final bool isOwned = _ownedAccessories.contains(name);
    final bool isEquipped = _equippedAccessory == name;
    final bool canAfford = currentStars >= cost;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Card(
        color: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOwned ? 'Owned' : '$cost Stars',
                      style: TextStyle(
                        color: isOwned ? Colors.greenAccent : Colors.amberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEquipped
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : (isOwned ? Colors.green : (canAfford ? Colors.amber : Colors.white10)),
                  foregroundColor: isEquipped ? Colors.redAccent : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isEquipped ? const BorderSide(color: Colors.redAccent) : BorderSide.none,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  if (isEquipped) {
                    setState(() {
                      _equippedAccessory = null;
                      _savePetState();
                    });
                    setSheetState(() {});
                  } else if (isOwned) {
                    setState(() {
                      _equippedAccessory = name;
                      _savePetState();
                    });
                    setSheetState(() {});
                  } else if (canAfford) {
                    final navigator = Navigator.of(context);
                    await ProgressService().addStudentStars(-cost);
                    if (!mounted) return;
                    setState(() {
                      _ownedAccessories.add(name);
                      _equippedAccessory = name;
                      _savePetState();
                    });
                    navigator.pop();
                    _showTempSpeech('🛍️ Equipped $name!');
                    if (widget.onPetHappy != null) widget.onPetHappy!();
                    _ttsService.speakEnglish('Thank you for the $name! I love it!', pitch: 1.4);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Not enough Stars! Learn more words to earn Stars.")),
                    );
                  }
                },
                child: Text(
                  isEquipped ? 'Remove' : (isOwned ? 'Equip' : 'Buy'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog mini-game quest
  void _startVocabularyQuest() {
    HapticFeedback.lightImpact();
    if (_isSleeping) {
      _showTempSpeech("💤 Sshh... I'm sleeping!");
      return;
    }

    final questEntries = _vocabQuests.entries.toList();
    final randomQuest = questEntries[_rng.nextInt(questEntries.length)];
    final String englishWord = randomQuest.key;
    final String correctNicobarese = randomQuest.value;

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
                          _savePetState();
                        });
                        final double pitch = _stage == PetStage.baby ? 1.6 : _stage == PetStage.teen ? 1.3 : 1.0;
                        _ttsService.speakEnglish(evolved ? 'I evolved! You taught me so well!' : 'Correct! Thank you!', pitch: pitch);
                        if (widget.onPetHappy != null) widget.onPetHappy!(); // Confetti trigger
                      } else {
                        setState(() {
                          _happiness = (_happiness - 5).clamp(0.0, 100.0);
                          _speechText = '😢 Oh, close! Teach me again!';
                          _showSpeech = true;
                          _savePetState();
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
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showTempSpeech(String text) {
    setState(() {
      _speechText = text;
      _showSpeech = true;
    });
    _hideSpeechAfterDelay();
  }

  void _hideSpeechAfterDelay() {
    _speechTimer?.cancel();
    _speechTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSpeech = false;
          _showHearts = false;
          _showZzz = false;
          _currentBehavior = _isSleeping ? 'sleeping' : 'idle';
          if (_isSleeping) _showZzz = true;
        });
        _bounceController.duration = const Duration(seconds: 2);
        _bounceController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _lifecycleTimer?.cancel();
    _speechTimer?.cancel();
    _bounceController.dispose();
    _heartController.dispose();
    _ttsService.dispose();
    try {
      _audioRecorder?.dispose();
    } catch (e) {
      debugPrint('Error disposing audio recorder: $e');
    }
    _nativeService.petBrainDispose();
    super.dispose();
  }

  Color _getMoodGlowColor() {
    switch (_mood) {
      case PetMood.happy:
        return Colors.pinkAccent;
      case PetMood.excited:
        return Colors.yellowAccent;
      case PetMood.sleepy:
        return Colors.blueAccent;
      case PetMood.sick:
        return Colors.redAccent;
      case PetMood.hungry:
        return Colors.orangeAccent;
      case PetMood.neutral:
        return _stageColors[_stage.index];
    }
  }

  Widget _buildAccessoryOverlay() {
    switch (_equippedAccessory) {
      case 'Sunglasses':
        return const Positioned(
          top: 24,
          child: Text('🕶️', style: TextStyle(fontSize: 22)),
        );
      case 'Crown':
        return const Positioned(
          top: 0,
          child: Text('👑', style: TextStyle(fontSize: 22)),
        );
      case 'Wizard Hat':
        return const Positioned(
          top: -2,
          child: Text('🧙', style: TextStyle(fontSize: 22)),
        );
      case 'Bowtie':
        return const Positioned(
          bottom: 4,
          child: Text('🎀', style: TextStyle(fontSize: 18)),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCircleButton({
    required String emoji,
    required VoidCallback onTap,
    required String tooltip,
    Color? bgColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: TapScale(
        onTap: _isSleeping && emoji != '🛌' ? () => _showTempSpeech("💤 Sshh... I'm sleeping!") : onTap,
        child: CircleAvatar(
          radius: 14,
          backgroundColor: bgColor ?? Colors.white.withValues(alpha: 0.12),
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.amberAccent,
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => c.repeat())
         .slideY(
           begin: 0,
           end: -0.8,
           duration: 300.ms,
           delay: (index * 150).ms,
           curve: Curves.easeInOut,
         )
         .then(delay: 150.ms)
         .slideY(begin: -0.8, end: 0, duration: 300.ms, curve: Curves.easeInOut);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColors[_stage.index];
    final animals = _stageAnimals[_stage.index];
    final currentAnimal = _isSleeping ? '😴' : animals[_petIndex % animals.length];
    final bounceHeight = _currentBehavior == 'zoomies' ? 25.0 : 15.0;

    return Positioned(
      bottom: 20,
      right: 20,
      child: SizedBox(
        width: 130,
        height: 210,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // ── Mood Back-Glow Ambient Animation ──
            Positioned(
              bottom: 30,
              right: 0,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getMoodGlowColor().withValues(alpha: 0.35),
                      blurRadius: _currentBehavior == 'zoomies' ? 32 : 24,
                      spreadRadius: _currentBehavior == 'zoomies' ? 6 : 4,
                    )
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), duration: 1.5.seconds, curve: Curves.easeInOut),
            ),

            // ── Speech Bubble ──
            if (_showSpeech)
              Positioned(
                top: -20,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                    ],
                  ),
                  child: _isThinking
                      ? _buildThinkingIndicator()
                      : Text(
                          _speechText,
                          style: TextStyle(
                            color: stageColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ).animate().scale(curve: Curves.elasticOut),
              ),

            // ── Floating Hearts ──
            if (_showHearts)
              ...List.generate(3, (i) => Positioned(
                bottom: 80 + i * 15.0,
                right: 15 + i * 12.0,
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
                top: 45,
                right: 5,
                child: const Text('💤', style: TextStyle(fontSize: 20))
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms),
              ),

            // ── Flying Food Animation Overlay ──
            if (_isFeedingFlying)
              Positioned(
                left: 10,
                bottom: 102,
                child: const Text('🍕', style: TextStyle(fontSize: 18))
                    .animate(onComplete: (controller) {
                      setState(() {
                        _isFeedingFlying = false;
                      });
                      _feedPet();
                    })
                    .slide(
                      begin: Offset.zero,
                      end: const Offset(3.5, -2.5),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    )
                    .scale(begin: const Offset(1, 1), end: const Offset(1.4, 1.4), duration: 300.ms)
                    .then()
                    .scale(begin: const Offset(1.4, 1.4), end: const Offset(0.2, 0.2), duration: 300.ms)
                    .fadeOut(duration: 300.ms),
              ),

            // ── Pet Body & Stats ──
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _petInteraction,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pet Avatar container with border & FFI custom accessory overlay
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: stageColor, width: 3),
                        ),
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Text(
                                currentAnimal,
                                style: const TextStyle(fontSize: 44),
                              ),
                              if (_equippedAccessory != null)
                                _buildAccessoryOverlay(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Customizable Pet Name
                      GestureDetector(
                        onTap: _renamePetDialog,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _petName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.edit,
                              color: Colors.white30,
                              size: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Mini stat bars
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
              ),
            ),

            // ── Left Sidebar Controls ──
            Positioned(
              left: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCircleButton(emoji: '💡', onTap: _startVocabularyQuest, tooltip: 'Vocabulary Quest'),
                  const SizedBox(height: 6),
                  _buildCircleButton(emoji: '🍕', onTap: _triggerFeedAnimation, tooltip: 'Feed Pizza'),
                  const SizedBox(height: 6),
                  // Mic button with custom glowing pulse animation when recording
                  Tooltip(
                    message: 'Talk to Pet',
                    child: TapScale(
                      onTap: _toggleVoiceRecording,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecordingVoice ? Colors.redAccent : Colors.white.withValues(alpha: 0.12),
                          boxShadow: [
                            if (_isRecordingVoice)
                              const BoxShadow(color: Colors.redAccent, blurRadius: 10, spreadRadius: 3)
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isRecordingVoice ? '🎙️' : '🎤',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                       .scale(
                         begin: const Offset(0.95, 0.95),
                         end: const Offset(1.05, 1.05),
                         duration: 800.ms,
                       ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildCircleButton(
                    emoji: _isSleeping ? '🛌' : '🛌',
                    onTap: _toggleSleep,
                    tooltip: _isSleeping ? 'Wake Up' : 'Put to Sleep',
                    bgColor: _isSleeping ? Colors.amber.withValues(alpha: 0.3) : null,
                  ),
                  const SizedBox(height: 6),
                  _buildCircleButton(emoji: '🛍️', onTap: _openAccessoryShop, tooltip: 'Pet Shop & Wardrobe'),
                ],
              ),
            ),

            // ── Stage badge ──
            Positioned(
              bottom: 74,
              right: 50,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: stageColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _stage.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
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
