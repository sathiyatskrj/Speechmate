import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConversationModeScreen extends StatefulWidget {
  const ConversationModeScreen({super.key});

  @override
  State<ConversationModeScreen> createState() => _ConversationModeScreenState();
}

class _ConversationModeScreenState extends State<ConversationModeScreen> with TickerProviderStateMixin {
  // Services
  AudioRecorder? _audioRecorder;
  final WhisperService _whisperService = WhisperService();
  final NeuralEngineService _neuralEngine = NeuralEngineService();
  final TtsService _ttsService = TtsService();

  // Active sides: 0 = None, 1 = Side A (Hindi/English), 2 = Side B (Nicobarese)
  int _recordingSide = 0; 
  bool _isProcessing = false;
  bool _isEngineReady = false;

  // Split-screen rotation toggle for Side A (so face-to-face user can read it)
  bool _rotateSideA = true;

  // Language settings for Side A: 'English' or 'Hindi'
  String _sideALanguage = 'English';

  // Active texts
  String _sideATranscript = '';
  String _sideBTranscript = '';

  // Conversation logs
  final List<Map<String, dynamic>> _conversationHistory = [];

  // Animation controller for mic pulse
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      _ttsService.init();
      await _neuralEngine.init();
      final ok = await _whisperService.initialize();
      setState(() {
        _isEngineReady = ok;
      });
    } catch (e) {
      debugPrint('[ConversationMode] Init failed: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioRecorder?.dispose();
    super.dispose();
  }

  Future<void> _startRecording(int side) async {
    if (_isProcessing || _recordingSide != 0) return;
    if (!_isEngineReady) {
      _showSnack('Speech engine is not initialized yet.');
      return;
    }

    try {
      await _ttsService.stop();
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();

      if (!await _audioRecorder!.hasPermission()) {
        _showSnack('Microphone permission is required.');
        return;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/conv_${side}_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      HapticFeedback.mediumImpact();
      setState(() {
        _recordingSide = side;
        if (side == 1) {
          _sideATranscript = 'Listening...';
        } else {
          _sideBTranscript = 'Listening...';
        }
      });
      _pulseController.repeat(reverse: true);
    } catch (e) {
      debugPrint('[ConversationMode] Record start error: $e');
      _showSnack('Failed to start recording');
    }
  }

  Future<void> _stopAndProcess(int side) async {
    if (_recordingSide != side) return;

    String? path;
    try {
      path = await _audioRecorder!.stop();
    } catch (e) {
      debugPrint('[ConversationMode] Record stop error: $e');
    }

    HapticFeedback.lightImpact();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _recordingSide = 0;
      _isProcessing = true;
    });

    if (path == null || !File(path).existsSync()) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    try {
      // Step 1: Transcribe WAV audio
      final transcription = await _whisperService.transcribe(path);
      if (transcription.trim().isEmpty) {
        setState(() {
          _isProcessing = false;
          if (side == 1) _sideATranscript = 'Could not understand, try again.';
          if (side == 2) _sideBTranscript = 'Could not understand, try again.';
        });
        return;
      }

      if (side == 1) {
        // Person A spoke (English/Hindi) -> Translate to Nicobarese
        setState(() {
          _sideATranscript = transcription;
        });

        // Translate using Neural Engine or offline fallback
        final prediction = await _neuralEngine.predict(transcription);
        final translatedText = prediction.text;

        setState(() {
          _sideBTranscript = translatedText;
          _conversationHistory.insert(0, {
            'side': 1,
            'original': transcription,
            'translated': translatedText,
            'lang': _sideALanguage,
          });
        });

        // Automatically speak translated Nicobarese text
        await _ttsService.speakNicobarese(translatedText, englishWord: transcription);
      } else {
        // Person B spoke (Nicobarese) -> Translate to English/Hindi
        setState(() {
          _sideBTranscript = transcription;
        });

        // Lookup in Nicobarese database
        final match = await DatabaseManager.instance.searchByNicobarese(transcription);
        final translatedText = match != null 
            ? (match['english'] ?? 'No translation found')
            : 'Word not found in dictionary';

        String speakingText = translatedText;
        if (_sideALanguage == 'Hindi' && match != null) {
          // If A wants Hindi, try neural regional or display English
          speakingText = match['hindi'] ?? translatedText;
        }

        setState(() {
          _sideATranscript = speakingText;
          _conversationHistory.insert(0, {
            'side': 2,
            'original': transcription,
            'translated': speakingText,
            'lang': 'Nicobarese',
          });
        });

        // Automatically speak translation
        if (_sideALanguage == 'English') {
          await _ttsService.speakEnglish(speakingText);
        } else {
          await _ttsService.speakRegional(speakingText, 'hi-IN');
        }
      }
    } catch (e) {
      debugPrint('[ConversationMode] Processing failed: $e');
      _whisperService.reset();
      _showSnack('Speech recognition failed. Please try again.');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // SIDE A: ENGLISH/HINDI PANEL (Top Half)
            // ==========================================
            Expanded(
              child: RotatedBox(
                quarterTurns: _rotateSideA ? 2 : 0,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C1338), Color(0xFF1B0B2E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: _recordingSide == 1 
                            ? Colors.redAccent.withValues(alpha: 0.5) 
                            : Colors.white.withValues(alpha: 0.1),
                        width: _recordingSide == 1 ? 2.0 : 1.0,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Language Selection Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _sideALanguage,
                                dropdownColor: const Color(0xFF1B0B2E),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.purpleAccent),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                items: ['English', 'Hindi'].map((String lang) {
                                  return DropdownMenuItem<String>(
                                    value: lang,
                                    child: Text(lang.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _sideALanguage = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),

                          const Text(
                            'TOURIST / TEACHER',
                            style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          ),

                          // Rotation Toggle
                          IconButton(
                            icon: Icon(
                              Icons.screen_rotation_rounded,
                              color: _rotateSideA ? Colors.purpleAccent : Colors.white30,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _rotateSideA = !_rotateSideA;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Text Display
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Text(
                              _sideATranscript.isEmpty 
                                  ? (_sideALanguage == 'English' ? 'Tap mic and speak English' : 'माइक दबाएं और हिंदी बोलें')
                                  : _sideATranscript,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _sideATranscript.isEmpty ? Colors.white24 : Colors.white,
                                fontSize: _sideATranscript.length > 50 ? 18 : 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Speak/Mic Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_sideATranscript.isNotEmpty && _recordingSide == 0 && !_isProcessing)
                            IconButton(
                              icon: const Icon(Icons.volume_up, color: Colors.purpleAccent, size: 28),
                              onPressed: () {
                                if (_sideALanguage == 'English') {
                                  _ttsService.speakEnglish(_sideATranscript);
                                } else {
                                  _ttsService.speakRegional(_sideATranscript, 'hi-IN');
                                }
                              },
                            ).animate().scale(),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              if (_recordingSide == 1) {
                                _stopAndProcess(1);
                              } else {
                                _startRecording(1);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _recordingSide == 1 ? Colors.redAccent : Colors.purpleAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_recordingSide == 1 ? Colors.redAccent : Colors.purpleAccent).withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _recordingSide == 1 ? (1.0 + _pulseController.value * 0.15) : 1.0,
                                    child: Icon(
                                      _recordingSide == 1 ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_sideATranscript.isNotEmpty && _recordingSide == 0 && !_isProcessing)
                            const SizedBox(width: 28), // balance volume button
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================================
            // LOG & RECENT HISTORY BAR (Middle spacer)
            // ==========================================
            Container(
              height: 50,
              color: const Color(0xFF0F0C1B),
              alignment: Alignment.center,
              child: _isProcessing 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'TRANSLATING...',
                          style: TextStyle(color: Colors.tealAccent.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                        )
                      ],
                    )
                  : Text(
                      'CONVERSATION MODE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
            ),

            // ==========================================
            // SIDE B: NICOBARESE PANEL (Bottom Half)
            // ==========================================
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E1A2B), Color(0xFF060D17)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    top: BorderSide(
                      color: _recordingSide == 2 
                          ? Colors.redAccent.withValues(alpha: 0.5) 
                          : Colors.white.withValues(alpha: 0.1),
                      width: _recordingSide == 2 ? 2.0 : 1.0,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Header info
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🗣️ NICOBARESE',
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'LOCAL NATIVE',
                          style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                        SizedBox(width: 32), // empty spacing
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Text Display
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            _sideBTranscript.isEmpty 
                                ? 'Kā ha-un (Tap mic to speak)'
                                : _sideBTranscript,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _sideBTranscript.isEmpty ? Colors.white24 : Colors.white,
                              fontSize: _sideBTranscript.length > 50 ? 18 : 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Speak/Mic Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_sideBTranscript.isNotEmpty && _recordingSide == 0 && !_isProcessing)
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Colors.tealAccent, size: 28),
                            onPressed: () {
                              _ttsService.speakNicobarese(_sideBTranscript, englishWord: _sideATranscript);
                            },
                          ).animate().scale(),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            if (_recordingSide == 2) {
                              _stopAndProcess(2);
                            } else {
                              _startRecording(2);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _recordingSide == 2 ? Colors.redAccent : Colors.tealAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_recordingSide == 2 ? Colors.redAccent : Colors.tealAccent).withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _recordingSide == 2 ? (1.0 + _pulseController.value * 0.15) : 1.0,
                                  child: Icon(
                                    _recordingSide == 2 ? Icons.stop : Icons.mic,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_sideBTranscript.isNotEmpty && _recordingSide == 0 && !_isProcessing)
                          const SizedBox(width: 28), // balance volume button
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Back button overlays
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton.small(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              elevation: 0,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }
}
