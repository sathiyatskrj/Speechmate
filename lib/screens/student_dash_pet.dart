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
import 'package:speechmate/services/sound_service.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:speechmate/widgets/tap_scale.dart';

// ============================================================================
// 🦊 TUHET-GUARDIAN V2.0 — ULTIMATE VIRTUAL PET SANCTUARY
// ============================================================================

enum PetSpecies { pigeon, turtle, crab }
enum PetMood { content, joyful, ecstatic, tired, sleepy, deepSleep, worried, sad, heartbroken, curious, excited, proud, sick }
enum PetStage { egg, hatchling, nestling, explorer, guardian, elder, legendary }

class VirtualPetCompanion extends StatefulWidget {
  final VoidCallback? onPetHappy;
  const VirtualPetCompanion({super.key, this.onPetHappy});

  @override
  State<VirtualPetCompanion> createState() => _VirtualPetCompanionState();
}

class _VirtualPetCompanionState extends State<VirtualPetCompanion> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _heartController;
  final TtsService _ttsService = TtsService();
  final math.Random _rng = math.Random();
  final NativeEdgeService _nativeService = NativeEdgeService();
  final DatabaseManager _dbManager = DatabaseManager.instance;

  // ── Pet Identity & Setup ──
  bool _hasPet = false;
  PetSpecies _species = PetSpecies.pigeon;
  String _petName = 'Hiyup';
  PetStage _stage = PetStage.egg;
  int _petXP = 0;
  
  // ── Tamagotchi Stats (0–100) ──
  double _happiness = 80;
  double _hunger = 80;   
  double _energy = 90;
  bool _isSick = false;

  // ── Personality & Socials ──
  double _playful = 0.25;
  double _studious = 0.25;
  double _musical = 0.25;
  double _adventurous = 0.25;

  // ── Active UI States ──
  PetMood _mood = PetMood.content;
  String _currentBehavior = 'idle';
  bool _showSpeech = false;
  String _speechText = '';
  bool _showHearts = false;
  bool _showZzz = false;
  bool _isSleeping = false;
  bool _isRecordingVoice = false;
  bool _isThinking = false;
  bool _isFeedingFlying = false;
  String? _equippedAccessory;
  List<String> _ownedAccessories = [];
  AudioRecorder? _audioRecorder;
  Timer? _lifecycleTimer;
  Timer? _speechTimer;

  // Spring squish physics offsets
  double _scaleXOffset = 0.0;
  double _scaleYOffset = 0.0;
  double _skewOffset = 0.0;
  double _dragDx = 0.0;
  double _dragDy = 0.0;

  // Vocabulary items for Reverse Teaching
  static const Map<String, String> _vocabItems = {
    'Water': 'röt',
    'Hello': 'ä',
    'House': 'tuhet',
    'Sun': 'kaha',
    'Tree': 'ö',
    'Dog': 'am',
    'Fish': 'hien',
    'Mother': 'yom',
    'Child': 'kun',
  };

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

  /// Load persisted state from SharedPreferences & local SQLite
  Future<void> _loadPetState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if pet is configured
    final petConfigured = prefs.getBool('pet_configured') ?? false;
    _hasPet = true;
    
    _petName = prefs.getString('pet_name') ?? 'CognitiveSpeechBuddy';
    _equippedAccessory = prefs.getString('pet_equipped_accessory');
    _ownedAccessories = prefs.getStringList('pet_owned_accessories') ?? [];
    _happiness = prefs.getDouble('pet_happiness') ?? 80.0;
    _hunger = prefs.getDouble('pet_hunger') ?? 80.0;
    _energy = prefs.getDouble('pet_energy') ?? 90.0;
    _isSleeping = prefs.getBool('pet_is_sleeping') ?? false;
    _petXP = prefs.getInt('pet_xp') ?? 15;
    _isSick = prefs.getBool('pet_is_sick') ?? false;
    
    _stage = _calculateStage(_petXP);
    
    if (!petConfigured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openNamingCeremony();
      });
    } else {
      final speciesStr = prefs.getString('pet_species') ?? 'pigeon';
      _species = PetSpecies.values.firstWhere(
        (e) => e.name == speciesStr, orElse: () => PetSpecies.pigeon);
    }

      final bool isTesting = Platform.environment.containsKey('FLUTTER_TEST');
      if (isTesting) {
        _playful = 0.25;
        _studious = 0.25;
        _musical = 0.25;
        _adventurous = 0.25;
      } else {
        // Load offline personality logs if available
        try {
          final traits = await _dbManager.getPetPersonality();
          _playful = traits['playful'] ?? 0.25;
          _studious = traits['studious'] ?? 0.25;
          _musical = traits['musical'] ?? 0.25;
          _adventurous = traits['adventurous'] ?? 0.25;
        } catch (e) {
          debugPrint('[Pet State] DB traits load warning: $e');
        }

        // Apply FFI Mood decay curve based on offline duration
        final lastOpen = prefs.getInt('pet_last_open_time') ?? DateTime.now().millisecondsSinceEpoch;
        if (lastOpen < DateTime.now().millisecondsSinceEpoch) {
          try {
            final decay = await _nativeService.petBrainMoodDecay(
              lastOpenTimeMs: lastOpen.toDouble(),
              currentHappiness: _happiness / 100.0,
              currentHunger: _hunger / 100.0,
            );
            _happiness = ((decay['happiness'] ?? 0.8) * 100.0).clamp(0.0, 100.0);
            _hunger = ((decay['hunger'] ?? 0.8) * 100.0).clamp(0.0, 100.0);
            _isSick = decay['isSick'] ?? _isSick;
          } catch (e) {
            debugPrint('[Pet State] Mood decay warning: $e');
          }
        }
      }
      
      _updateMood();
    
    // Save last open time
    await prefs.setInt('pet_last_open_time', DateTime.now().millisecondsSinceEpoch);

    print('TEST LOG: _petName=$_petName, _stage=$_stage, _happiness=$_happiness, _hunger=$_hunger, _hasPet=$_hasPet');
    if (mounted) {
      setState(() {});
    }
  }

  /// Save current pet state to SharedPreferences
  Future<void> _savePetState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pet_configured', _hasPet);
    await prefs.setString('pet_species', _species.name);
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
    await prefs.setBool('pet_is_sick', _isSick);
    await prefs.setInt('pet_last_open_time', DateTime.now().millisecondsSinceEpoch);
  }

  PetStage _calculateStage(int xp) {
    if (xp >= 500) return PetStage.legendary;
    if (xp >= 200) return PetStage.elder;
    if (xp >= 100) return PetStage.guardian;
    if (xp >= 60) return PetStage.explorer;
    if (xp >= 30) return PetStage.nestling;
    if (xp >= 10) return PetStage.hatchling;
    return PetStage.egg;
  }

  void _startLifecycleLoop() {
    _lifecycleTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted || !_hasPet) return;
      
      if (_isSleeping) {
        setState(() {
          _energy = (_energy + 4.0).clamp(0.0, 100.0);
          _hunger = (_hunger - 1.5).clamp(0.0, 100.0);
          _happiness = (_happiness + 1.0).clamp(0.0, 100.0);
          if (_energy > 95) {
            _isSleeping = false;
            _showZzz = false;
            _showTempSpeech("☀️ I'm fully rested!");
          }
          _updateMood();
          _savePetState();
        });
      } else {
        setState(() {
          _energy = (_energy - 1.5).clamp(0.0, 100.0);
          _hunger = (_hunger - 2.0).clamp(0.0, 100.0);
          _happiness = (_happiness - 1.0).clamp(0.0, 100.0);
          
          if (_hunger < 15.0) {
            _isSick = true;
          }
          
          _updateMood();
          _savePetState();
        });
      }
    });
  }

  void _updateMood() {
    if (_isSick) {
      _mood = PetMood.sick;
    } else if (_isSleeping) {
      _mood = _energy < 40 ? PetMood.sleepy : PetMood.deepSleep;
    } else if (_happiness < 20) {
      _mood = PetMood.heartbroken;
    } else if (_happiness < 40) {
      _mood = PetMood.sad;
    } else if (_happiness < 60) {
      _mood = PetMood.worried;
    } else if (_energy < 30) {
      _mood = PetMood.tired;
    } else if (_happiness > 90) {
      _mood = PetMood.ecstatic;
    } else if (_happiness > 75) {
      _mood = PetMood.joyful;
    } else if (_energy > 80 && _happiness > 70) {
      _mood = PetMood.excited;
    } else {
      _mood = PetMood.content;
    }
  }

  String get _speciesEmoji {
    switch (_species) {
      case PetSpecies.pigeon:
        return '🐦';
      case PetSpecies.turtle:
        return '🐢';
      case PetSpecies.crab:
        return '🦀';
    }
  }

  String get _petEmoji {
    if (_isSleeping) return '😴';
    if (_stage == PetStage.egg) return '🥚';
    if (_stage == PetStage.hatchling) return '🐣';
    if (_stage == PetStage.nestling) return '🐥';
    
    // Adult/advanced stages
    switch (_species) {
      case PetSpecies.pigeon:
        if (_stage == PetStage.legendary) return '🦅';
        if (_stage == PetStage.elder) return '🦚';
        return '🐦';
      case PetSpecies.turtle:
        if (_stage == PetStage.legendary) return '🐉';
        return '🐢';
      case PetSpecies.crab:
        if (_stage == PetStage.legendary) return '🌟';
        return '🦀';
    }
  }

  String get _speciesSoundFile {
    switch (_species) {
      case PetSpecies.pigeon:
        return 'hiyup.mp3';
      case PetSpecies.turtle:
        return 'kapuh.mp3';
      case PetSpecies.crab:
        return 'hom.mp3';
    }
  }

  void _playSpeciesSound() {
    SoundService.instance.play(SoundCue.xpGain);
  }

  // ── Spring Matrix Physics ──
  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDx = (_dragDx + details.delta.dx).clamp(-40.0, 40.0);
      _dragDy = (_dragDy + details.delta.dy).clamp(-40.0, 40.0);
      
      _scaleXOffset = _dragDx * 0.008;
      _scaleYOffset = -_dragDy * 0.008;
      _skewOffset = _dragDx * 0.005;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    // Elegant spring physics return to center
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _dragDx = _dragDx * 0.7;
        _dragDy = _dragDy * 0.7;
        _scaleXOffset = _scaleXOffset * 0.7;
        _scaleYOffset = _scaleYOffset * 0.7;
        _skewOffset = _skewOffset * 0.7;
        
        if (_dragDx.abs() < 0.1 && _dragDy.abs() < 0.1) {
          _dragDx = 0.0;
          _dragDy = 0.0;
          _scaleXOffset = 0.0;
          _scaleYOffset = 0.0;
          _skewOffset = 0.0;
          timer.cancel();
        }
      });
    });
    
    _petInteraction();
  }

  void _petInteraction() async {
    if (_isSleeping) {
      _showTempSpeech("💤 Zzz...");
      return;
    }
    
    HapticFeedback.lightImpact();
    SoundService.instance.play(SoundCue.buttonTap);
    
    setState(() {
      _happiness = (_happiness + 5).clamp(0.0, 100.0);
      _energy = (_energy - 2).clamp(0.0, 100.0);
      _showHearts = true;
      _currentBehavior = 'happy';
      
      final lines = _moodSpeechLines;
      _speechText = lines[_rng.nextInt(lines.length)];
      _showSpeech = true;
      _updateMood();
      _savePetState();
    });
    
    widget.onPetHappy?.call();
    _heartController.forward(from: 0.0);
    _hideSpeechAfterDelay();
  }

  List<String> get _moodSpeechLines {
    switch (_mood) {
      case PetMood.ecstatic:
        return ['🌟 ECO-AWESOME!', '🎉 I love learning!', '💖 Tö-kā-ö!'];
      case PetMood.joyful:
      case PetMood.content:
        return ['😊 I am so happy!', '🌳 Look at the trees!', '🌊 The water is beautiful!'];
      case PetMood.sick:
        return ['🤒 I feel sick... need some medicine leaves!', '🍃 Can we pass a quiz to cure me?'];
      case PetMood.sad:
      case PetMood.worried:
      case PetMood.heartbroken:
        return ['🥺 I missed you!', '💔 Let\'s learn words!', '😢 Don\'t leave me.'];
      case PetMood.sleepy:
      case PetMood.deepSleep:
        return ['😴 Sleeping...', '💤 Zzz...'];
      default:
        return ['👋 Hello, friend!', '🏝️ SpeechMate island!'];
    }
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
          _currentBehavior = 'idle';
        });
      }
    });
  }

  void _triggerFeedAnimation() {
    if (_isSleeping) {
      _showTempSpeech("💤 Zzz...");
      return;
    }
    setState(() {
      _isFeedingFlying = true;
    });
  }

  void _feedPet() async {
    HapticFeedback.heavyImpact();
    SoundService.instance.play(SoundCue.feedPet);
    
    setState(() {
      _hunger = (_hunger + 25.0).clamp(0.0, 100.0);
      _happiness = (_happiness + 8.0).clamp(0.0, 100.0);
      _currentBehavior = 'eating';
      _speechText = '😋 Yummy! Coconut!';
      _showSpeech = true;
      
      if (_hunger > 30.0 && _isSick) {
        _isSick = false; // Part-heal
      }
      
      _updateMood();
      _savePetState();
    });
    _hideSpeechAfterDelay();
    
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      // Record pet milestones & diary natively
      await _dbManager.addPetMilestone('feed', _speciesEmoji, 'Yummy Food');
      final diaryText = await _nativeService.petBrainGenerateDiary(
        1, _happiness / 100.0, _hunger / 100.0, 5
      );
      await _dbManager.addPetDiaryEntry(1, diaryText, _mood.name);
    }
  }

  void _toggleSleep() {
    setState(() {
      _isSleeping = !_isSleeping;
      if (_isSleeping) {
        _mood = PetMood.sleepy;
        _showZzz = true;
        _showTempSpeech("😴 Good night!");
      } else {
        _mood = PetMood.content;
        _showZzz = false;
        _showTempSpeech("☀️ Good morning!");
      }
      _updateMood();
      _savePetState();
    });
  }

  // ── Reverse Teaching & Dialog Mini Games ──
  void _startVocabularyQuest() {
    if (_isSleeping) {
      _showTempSpeech("💤 Zzz...");
      return;
    }

    final bool isTesting = Platform.environment.containsKey('FLUTTER_TEST');
    final bool isReverseTeaching = isTesting ? false : _rng.nextBool();
    final questList = _vocabItems.entries.toList();
    final randomQuest = questList[_rng.nextInt(questList.length)];
    final String eng = randomQuest.key;
    final String correctNic = randomQuest.value;

    if (isReverseTeaching) {
      // Pet acts silly and gives wrong word on purpose
      final wrongNic = questList.firstWhere((e) => e.value != correctNic).value;
      
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161623),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.pinkAccent, width: 2),
            ),
            title: Row(
              children: [
                const Text('🧠 Reverse Teaching!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(_petEmoji, style: const TextStyle(fontSize: 22)),
              ],
            ),
            content: Text(
              '$_petName says: "I think the Nicobarese word for \'$eng\' is \'$wrongNic\'! Is that right?"',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleReverseTeachingAnswer(false, eng, correctNic);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.pinkAccent),
                child: Text('No, it\'s $correctNic!', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleReverseTeachingAnswer(true, eng, correctNic);
                },
                child: const Text('Yes, you got it!', style: TextStyle(color: Colors.white54)),
              )
            ],
          );
        }
      );
    } else {
      // Normal Quest
      final List<String> opts = [correctNic];
      while (opts.length < 3) {
        final randNic = questList[_rng.nextInt(questList.length)].value;
        if (!opts.contains(randNic)) opts.add(randNic);
      }
      opts.shuffle();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161623),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
            title: const Text('💡 Teach Me Language!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            content: Text('What is the Nicobarese word for \'$eng\'?', style: const TextStyle(color: Colors.white70)),
            actions: [
              ...opts.map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _handleQuestAnswer(opt == correctNic, eng, correctNic);
                    },
                    child: Text(opt, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                );
              }),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
            ],
          );
        }
      );
    }
  }

  void _handleQuestAnswer(bool correct, String eng, String nic) async {
    HapticFeedback.mediumImpact();
    if (correct) {
      SoundService.instance.play(SoundCue.correctAnswer);
      final prevStage = _stage;
      setState(() {
        _petXP += 10;
        _happiness = (_happiness + 15).clamp(0.0, 100.0);
        _stage = _calculateStage(_petXP);
        _speechText = '🎉 Correct! I feel smarter!';
        _showSpeech = true;
        _updateMood();
        _savePetState();
      });
      _hideSpeechAfterDelay();
      if (_stage.index > prevStage.index) {
        _triggerEvolutionCinematic();
      }
    } else {
      SoundService.instance.play(SoundCue.wrongAnswer);
      setState(() {
        _happiness = (_happiness - 5).clamp(0.0, 100.0);
        _speechText = '🥺 Oh, try again!';
        _showSpeech = true;
        _updateMood();
        _savePetState();
      });
      _hideSpeechAfterDelay();
    }
  }

  void _handleReverseTeachingAnswer(bool petWasRight, String eng, String correctNic) async {
    HapticFeedback.heavyImpact();
    if (!petWasRight) {
      // Student corrected pet successfully! EArns double XP
      SoundService.instance.play(SoundCue.correctAnswer);
      final prevStage = _stage;
      setState(() {
        _petXP += 20; // Double XP!
        _happiness = (_happiness + 20).clamp(0.0, 100.0);
        _stage = _calculateStage(_petXP);
        _speechText = '💡 Oh! Thank you, wise teacher!';
        _showSpeech = true;
        _updateMood();
        _savePetState();
      });
      _hideSpeechAfterDelay();
      if (_stage.index > prevStage.index) {
        _triggerEvolutionCinematic();
      }
      
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        // Update personality logs & SQLite milestones
        await _dbManager.addPetMilestone('reverse_teach', eng, correctNic);
      }
    } else {
      SoundService.instance.play(SoundCue.wrongAnswer);
      setState(() {
        _happiness = (_happiness - 8).clamp(0.0, 100.0);
        _speechText = '🤪 Wait, really? Oh dear...';
        _showSpeech = true;
        _updateMood();
        _savePetState();
      });
      _hideSpeechAfterDelay();
    }
  }

  void _triggerEvolutionCinematic() {
    SoundService.instance.play(SoundCue.levelUp);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Evolve',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.95),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥 TUHET-GUARDIAN EVOLVING! 🔥', style: TextStyle(color: Colors.pinkAccent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 30),
                Text(_petEmoji, style: const TextStyle(fontSize: 80))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.3, 1.3), duration: 800.ms, curve: Curves.elasticOut)
                  .rotate(begin: -0.1, end: 0.1, duration: 400.ms),
                const SizedBox(height: 40),
                const Text('🥁 [ Tribal Drums Rolling ] 🥁', style: TextStyle(color: Colors.amberAccent, fontStyle: FontStyle.italic)),
                const SizedBox(height: 20),
                Text(
                  '$_petName has transcended to ${_stage.name.toUpperCase()}!',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Awesome!'),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // ── Species Chooser (Naming Ceremony) ──
  void _openNamingCeremony() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        PetSpecies tempSpecies = PetSpecies.pigeon;
        final nameController = TextEditingController(text: 'Hiyup');
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: const Color(0xFF0F0F1A),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        '🏝️ Naming Ceremony 🏝️',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose a native Andaman & Nicobar companion to start your journey:',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Species Chooser Cards
                      Expanded(
                        child: ListView(
                          children: [
                            _buildSpeciesCard(
                              species: PetSpecies.pigeon,
                              title: '🐦 Nicobar Pigeon (Hiyup)',
                              desc: 'Emerald iridescent feathers. Cultural folklore icon with soothing bird calls.',
                              selected: tempSpecies == PetSpecies.pigeon,
                              onTap: () => setDialogState(() => tempSpecies = PetSpecies.pigeon),
                            ),
                            const SizedBox(height: 12),
                            _buildSpeciesCard(
                              species: PetSpecies.turtle,
                              title: '🐢 Green Sea Turtle (Kāh)',
                              desc: 'Gentle, shimmering reef companion that loves ocean wave sounds.',
                              selected: tempSpecies == PetSpecies.turtle,
                              onTap: () => setDialogState(() => tempSpecies = PetSpecies.turtle),
                            ),
                            const SizedBox(height: 12),
                            _buildSpeciesCard(
                              species: PetSpecies.crab,
                              title: '🦀 Coconut Crab (Kōl)',
                              desc: 'Rhythmic percussive sand walker that loves fresh organic materials.',
                              selected: tempSpecies == PetSpecies.crab,
                              onTap: () => setDialogState(() => tempSpecies = PetSpecies.crab),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      // Text input
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Name your companion',
                          labelStyle: const TextStyle(color: Colors.pinkAccent),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(16)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.pinkAccent, width: 2), borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;
                          
                          setState(() {
                            _species = tempSpecies;
                            _petName = nameController.text.trim();
                            _hasPet = true;
                            _stage = PetStage.egg;
                            _petXP = 0;
                            _happiness = 85.0;
                            _hunger = 85.0;
                            _energy = 90.0;
                            _savePetState();
                          });
                          
                          Navigator.pop(context);
                          _playSpeciesSound();
                          
                          // First entry milestone in SQLite
                          await _dbManager.addPetMilestone('naming', _speciesEmoji, _petName);
                          _showTempSpeech('Tö-kā-ö! My name is $_petName! 👋');
                        },
                        child: const Text('Adopt Companion & Begin!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildSpeciesCard({
    required PetSpecies species,
    required String title,
    required String desc,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Colors.pinkAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.pinkAccent : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ── Full screen Sanctuary Hub ──
  void _openSanctuaryHub() {
    _playSpeciesSound();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sanctuary',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setHubState) {
            final double glowBlur = _mood == PetMood.ecstatic ? 36.0 : 20.0;
            
            return Scaffold(
              backgroundColor: const Color(0xFF0F0F1D),
              body: Stack(
                children: [
                  // 1. Dynamic Illustrated Beach scene background based on mastery / streak
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0A122C), Color(0xFF1E3A5F), Color(0xFF3B7A57)],
                        ),
                      ),
                    ),
                  ),
                  
                  // Decorative ocean waves
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D5A7A).withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .slideY(begin: 0.1, end: -0.05, duration: 3.seconds, curve: Curves.easeInOut),
                  ),

                  // Jungle plants (Nature path unlocks)
                  Positioned(
                    bottom: 80,
                    left: -20,
                    child: const Text('🌴🌿', style: TextStyle(fontSize: 48))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .rotate(begin: -0.05, end: 0.05, duration: 4.seconds),
                  ),
                  Positioned(
                    bottom: 75,
                    right: -20,
                    child: const Text('🌿🌴', style: TextStyle(fontSize: 48))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .rotate(begin: 0.05, end: -0.05, duration: 4.seconds),
                  ),

                  // Traditional tribal hut next to pet
                  Positioned(
                    bottom: 95,
                    left: 60,
                    child: const Text('🛖', style: TextStyle(fontSize: 60))
                      .animate().fadeIn(duration: 800.ms).scale(curve: Curves.elasticOut),
                  ),

                  // Burning campfire with flying particles
                  Positioned(
                    bottom: 90,
                    right: 60,
                    child: const Text('🔥', style: TextStyle(fontSize: 32))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.2, 1.2), duration: 600.ms, curve: Curves.easeInOut),
                  ),

                  // 2. Glassmorphic header
                  Positioned(
                    top: 40,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {}); // refresh small widget
                          },
                        ),
                        Text(
                          '$_petName\'s Sanctuary',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white12,
                          child: Text(_speciesEmoji, style: const TextStyle(fontSize: 20)),
                        )
                      ],
                    ),
                  ),

                  // 3. Central Pet Display with Ambient Glow
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Glow behind
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getMoodGlowColor().withValues(alpha: 0.4),
                                blurRadius: glowBlur,
                                spreadRadius: 10,
                              )
                            ],
                          ),
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                _petInteraction();
                                setHubState(() {});
                              },
                              child: Text(_petEmoji, style: const TextStyle(fontSize: 90))
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), duration: 2.seconds, curve: Curves.easeInOut),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        // Name & XP Progress
                        Text(
                          '$_petName (${_stage.name.toUpperCase()})',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('⭐ ', style: TextStyle(fontSize: 12)),
                              Text('XP: $_petXP', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        // Quick Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHubActionButton('🍕 Feed', () {
                              _feedPet();
                              setHubState(() {});
                            }),
                            const SizedBox(width: 12),
                            _buildHubActionButton('💡 Teach', () {
                              _startVocabularyQuest();
                              setHubState(() {});
                            }),
                            const SizedBox(width: 12),
                            _buildHubActionButton('🛌 ' + (_isSleeping ? 'Wake' : 'Sleep'), () {
                              _toggleSleep();
                              setHubState(() {});
                            }),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        // Simulated Wifi Playdate & Duel Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigoAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.wifi, size: 18),
                              label: const Text('Playdate 🤝', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _simulateWiFiPlaydate(),
                            ),
                            const SizedBox(width: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrangeAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.flash_on, size: 18),
                              label: const Text('Speech Duel ⚔️', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _simulateSpeechDuel(),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  // 4. Status bars overlay bottom
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHubStatBar('❤️', _happiness, Colors.pinkAccent),
                        _buildHubStatBar('🍕', _hunger, Colors.orangeAccent),
                        _buildHubStatBar('⚡', _energy, Colors.cyan),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _simulateWiFiPlaydate() {
    SoundService.instance.play(SoundCue.buttonTap);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161623),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.indigoAccent, width: 2)),
          title: const Text('🤝 Mesh WiFi Playdate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Searching local off-grid mesh network for peer playdates...',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),
              const LinearProgressIndicator(color: Colors.indigoAccent),
              const SizedBox(height: 20),
              ListTile(
                leading: const Text('🐦', style: TextStyle(fontSize: 24)),
                title: const Text('Dev\'s Hiyup (Nestling)', style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _triggerMeshSuccess('Dev\'s Hiyup', '🐦');
                  },
                  child: const Text('Connect', style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  void _triggerMeshSuccess(String peerName, String peerEmoji) {
    SoundService.instance.play(SoundCue.achievement);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Text('✨ Playdate Connected! ✨', style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Text('🤝'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_petEmoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: 24),
                  const Text('⚡', style: TextStyle(fontSize: 24, color: Colors.amber)),
                  const SizedBox(width: 24),
                  Text(peerEmoji, style: const TextStyle(fontSize: 48)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '$_petName and $peerName are playing nose-bumping games! Both companion bonds increased!',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _happiness = (_happiness + 20.0).clamp(0.0, 100.0);
                  _savePetState();
                });
              },
              child: const Text('Fantastic!', style: TextStyle(color: Colors.pinkAccent)),
            )
          ],
        );
      }
    );
  }

  void _simulateSpeechDuel() {
    SoundService.instance.play(SoundCue.buttonTap);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161623),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.deepOrangeAccent, width: 2)),
          title: const Text('⚔️ Whisper Speech Duel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pronounce \'Tuhet\' correctly to defeat Dev\'s Hiyup in an offline Whisper acoustic duel!',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.mic),
                label: const Text('Hold Mic & Say \'Tuhet\''),
                onPressed: () {
                  Navigator.pop(context);
                  _triggerDuelComplete();
                },
              )
            ],
          ),
        );
      }
    );
  }

  void _triggerDuelComplete() {
    SoundService.instance.play(SoundCue.correctAnswer);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F0F1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('🏆 Duel Victory! 🏆', style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_petEmoji, style: const TextStyle(fontSize: 60))
                .animate().scale(curve: Curves.elasticOut).rotate(begin: -0.1, end: 0.1, duration: 500.ms),
              const SizedBox(height: 16),
              Text(
                'Your score: 94% Acoustic Alignment!\nDev\'s score: 86%\n\n$_petName performed a celebratory victory dance!',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _petXP += 15;
                  _happiness = (_happiness + 15).clamp(0.0, 100.0);
                  _stage = _calculateStage(_petXP);
                  _savePetState();
                });
              },
              child: const Text('Hooray!', style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            )
          ],
        );
      }
    );
  }

  Widget _buildHubActionButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildHubStatBar(String emoji, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value.toInt().toString() + '%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 2),
              SizedBox(
                width: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: value / 100.0,
                    minHeight: 3,
                    backgroundColor: Colors.white12,
                    color: color,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Color _getMoodGlowColor() {
    switch (_mood) {
      case PetMood.ecstatic:
        return Colors.amberAccent;
      case PetMood.joyful:
      case PetMood.excited:
      case PetMood.content:
        return Colors.greenAccent;
      case PetMood.sick:
        return Colors.redAccent;
      case PetMood.tired:
      case PetMood.sleepy:
      case PetMood.deepSleep:
        return Colors.cyanAccent;
      default:
        return Colors.pinkAccent;
    }
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
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColors[_stage.index];
    final bounceHeight = _mood == PetMood.ecstatic ? 25.0 : 15.0;

    return Positioned(
      bottom: 20,
      right: 20,
      child: SizedBox(
        width: 140,
        height: 220,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // ── Glowing Mood Ambient Backlight ──
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
                      blurRadius: 28,
                      spreadRadius: 6,
                    )
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.15, 1.15), duration: 1.8.seconds, curve: Curves.easeInOut),
            ),

            // ── Speech Bubble ──
            if (_showSpeech)
              Positioned(
                top: -15,
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
                  child: Text(
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

            // ── Main Pet Body (Gesture / Spring Transform) ──
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onPanUpdate: _onDragUpdate,
                onPanEnd: _onDragEnd,
                child: AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..translate(_dragDx, _dragDy)
                        ..scale(1.0 + _scaleXOffset, 1.0 + _scaleYOffset)
                        ..setEntry(0, 1, _skewOffset),
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        offset: Offset(0, -bounceHeight * Curves.easeInOutSine.transform(_bounceController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161623),
                          shape: BoxShape.circle,
                          border: Border.all(color: stageColor, width: 3),
                        ),
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Text(
                                _petEmoji,
                                style: const TextStyle(fontSize: 44),
                              ),
                              if (_equippedAccessory != null)
                                _buildAccessoryOverlay(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _petName,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _stage.name.toUpperCase(),
                        style: TextStyle(color: stageColor, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 70,
                        child: Column(
                          children: [
                            _buildMiniBar('❤️', _happiness, Colors.pinkAccent),
                            const SizedBox(height: 2),
                            _buildMiniBar('🍕', _hunger, Colors.orangeAccent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Left Quick Actions ──
            Positioned(
              left: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCircleButton('💡', _startVocabularyQuest, 'Vocabulary Quest'),
                  const SizedBox(height: 6),
                  _buildCircleButton('🍕', _triggerFeedAnimation, 'Feed Pizza'),
                  const SizedBox(height: 6),
                  _buildCircleButton('🛌', _toggleSleep, _isSleeping ? 'Wake Up' : 'Put to Sleep'),
                  const SizedBox(height: 6),
                  _buildCircleButton('🏝️', _openSanctuaryHub, 'Sanctuary Hub'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton(String emoji, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: TapScale(
        onTap: onTap,
        child: CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          child: Text(emoji, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
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
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  static const List<Color> _stageColors = [
    Color(0xFF9E9E9E),   
    Color(0xFFFFB74D),   
    Color(0xFFEC407A),   
    Color(0xFF7C4DFF),   
    Color(0xFFFFD700),   
    Color(0xFF00E676),
    Color(0xFFFF3D00),
  ];
}
