import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceTranslatorScreen extends StatefulWidget {
  const VoiceTranslatorScreen({super.key});

  @override
  State<VoiceTranslatorScreen> createState() => _VoiceTranslatorScreenState();
}

class _VoiceTranslatorScreenState extends State<VoiceTranslatorScreen>
    with TickerProviderStateMixin {
  // Services — singletons
  AudioRecorder? _audioRecorder;
  final WhisperService _whisperService = WhisperService();
  final NeuralEngineService _neuralEngine = NeuralEngineService();
  final TtsService _ttsService = TtsService();

  // State
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isModelReady = false;
  bool _isInitializing = true;
  String? _modelError;
  String _inputText = '';
  String _outputText = '';
  double _confidence = 0.0;
  String? _lastAudioPath;

  // Animation controllers
  late AnimationController _orbPulse;
  late AnimationController _bgWave;
  late AnimationController _recordingRipple;

  @override
  void initState() {
    super.initState();

    _orbPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bgWave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _recordingRipple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _initServicesAsync();
  }

  Future<void> _initServicesAsync() async {
    try {
      // Init TTS first (instant)
      _ttsService.init();
      // Init neural engine (DB read)
      await _neuralEngine.init();
      // Init whisper last (heavy — model extraction)
      final ok = await _whisperService.initialize();

      if (mounted) {
        setState(() {
          _isModelReady = ok;
          _isInitializing = false;
          _modelError = ok
              ? null
              : 'Whisper model not found.\nEnsure ggml-base.bin is in assets/models/';
        });
      }
    } catch (e) {
      debugPrint('[VoiceTranslator] Init error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isModelReady = false;
          _modelError = 'Engine init failed: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _orbPulse.dispose();
    _bgWave.dispose();
    _recordingRipple.dispose();
    _audioRecorder?.dispose();
    _ttsService.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  void _cleanupTempFile() {
    if (_lastAudioPath != null) {
      try {
        final f = File(_lastAudioPath!);
        if (f.existsSync()) f.deleteSync();
      } catch (e) { debugPrint('Silent error caught: $e'); }
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Recording Logic — TAP to toggle (not hold)
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _toggleRecording() async {
    if (_isProcessing) return;
    if (!_isModelReady) {
      _showSnack('Speech engine not ready yet');
      return;
    }

    if (_isRecording) {
      await _stopAndTranslate();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      // Stop any playing audio
      await _ttsService.stop();

      // Create a fresh recorder every time
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();

      if (!await _audioRecorder!.hasPermission()) {
        _showSnack('Microphone permission is required');
        return;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/vt_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      HapticFeedback.mediumImpact();

      if (mounted) {
        setState(() {
          _isRecording = true;
          _inputText = '';
          _outputText = '';
          _confidence = 0.0;
        });
        _recordingRipple.repeat();
      }
    } catch (e) {
      debugPrint('[VoiceTranslator] Start error: $e');
      _showSnack('Could not start recording');
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _stopAndTranslate() async {
    if (!_isRecording) return;

    String? path;
    try {
      path = await _audioRecorder!.stop();
    } catch (e) {
      debugPrint('[VoiceTranslator] Stop error: $e');
    }

    HapticFeedback.lightImpact();
    _recordingRipple.stop();
    _recordingRipple.reset();

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _inputText = '';
        _outputText = '';
      });
    }

    if (path == null || !File(path).existsSync()) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    _cleanupTempFile();
    _lastAudioPath = path;

    try {
      // Step 1: Transcribe — WhisperService has its own 30s timeout,
      // no extra timeout here to avoid premature abort race conditions.
      final transcription = await _whisperService.transcribe(path);

      if (transcription.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _inputText = 'Could not understand. Try speaking clearly.';
            _isProcessing = false;
          });
        }
        return;
      }

      if (mounted) setState(() => _inputText = transcription.trim());

      // Step 2: Translate
      final result = await _neuralEngine
          .predict(transcription)
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _outputText = result.text;
          _confidence = result.confidence;
        });
      }

      // Step 3: Speak
      _ttsService.speakNicobarese(result.text, englishWord: transcription);
    } catch (e) {
      debugPrint('[VoiceTranslator] Process error: $e');
      // Proactively reset the whisper engine so next attempt works
      _whisperService.reset();
      if (mounted) {
        setState(() {
          _inputText = _inputText.isEmpty ? 'Processing failed' : _inputText;
          _outputText = 'Error — try again';
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Voice Translator',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Animated background ──
          _buildAnimatedBackground(),

          // ── Main content ──
          SafeArea(
            child: _isInitializing
                ? _buildLoadingState()
                : _modelError != null
                    ? _buildErrorState()
                    : _buildMainUI(),
          ),
        ],
      ),
    );
  }

  // ── Animated Gradient Background ──────────────────────────────────────────
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgWave,
      builder: (context, _) {
        final t = _bgWave.value * 2 * pi;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(sin(t) * 0.5, -1),
              end: Alignment(cos(t) * 0.5, 1),
              colors: _isRecording
                  ? const [Color(0xFF1A0000), Color(0xFF2D0A0A), Color(0xFF0A0A20)]
                  : const [Color(0xFF080E1E), Color(0xFF0A1628), Color(0xFF0D0B2D)],
            ),
          ),
        );
      },
    );
  }

  // ── Loading State ─────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.cyanAccent.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Preparing Speech Engine',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text('Loading multilingual Whisper model...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
          const SizedBox(height: 8),
          Text('This only takes a moment on first launch',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ── Error State ───────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.mic_off_rounded, color: Colors.redAccent, size: 48),
            ),
            const SizedBox(height: 28),
            const Text('Speech Engine Unavailable',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(_modelError ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, height: 1.5)),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _modelError = null;
                  _isInitializing = true;
                });
                _initServicesAsync();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
                side: const BorderSide(color: Colors.cyanAccent),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  // ── Main UI ───────────────────────────────────────────────────────────────
  Widget _buildMainUI() {
    return Column(
      children: [
        const SizedBox(height: 8),

        // ── Input panel (English) ──
        Expanded(
          flex: 3,
          child: _buildGlassPanel(
            label: 'ENGLISH',
            labelColor: Colors.cyanAccent,
            icon: Icons.language_rounded,
            text: _isRecording
                ? null // Show waveform
                : _isProcessing && _inputText.isEmpty
                    ? null // Show processing
                    : _inputText.isEmpty
                        ? 'Tap the orb to start speaking'
                        : _inputText,
            isListening: _isRecording,
            isProcessing: _isProcessing && _inputText.isEmpty,
          ),
        ),

        // ── Center orb ──
        _buildOrb(),

        // ── Output panel (Nicobarese) ──
        Expanded(
          flex: 3,
          child: _buildGlassPanel(
            label: 'NICOBARESE',
            labelColor: Colors.tealAccent,
            icon: Icons.translate_rounded,
            text: _isProcessing && _inputText.isNotEmpty && _outputText.isEmpty
                ? null
                : _outputText.isEmpty
                    ? 'Translation appears here'
                    : _outputText,
            isProcessing: _isProcessing && _inputText.isNotEmpty && _outputText.isEmpty,
            confidence: _confidence,
            showSpeaker: _outputText.isNotEmpty && !_isProcessing,
            onSpeakerTap: () => _ttsService.speakNicobarese(_outputText, englishWord: _inputText),
          ),
        ),

        const SizedBox(height: 16),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  // ── Glass Panel ───────────────────────────────────────────────────────────
  Widget _buildGlassPanel({
    required String label,
    required Color labelColor,
    required IconData icon,
    String? text,
    bool isListening = false,
    bool isProcessing = false,
    double confidence = 0.0,
    bool showSpeaker = false,
    VoidCallback? onSpeakerTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isListening
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : labelColor.withValues(alpha: 0.15),
                width: isListening ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: labelColor.withValues(alpha: 0.7), size: 16),
                    const SizedBox(width: 8),
                    Text(label,
                        style: TextStyle(
                          color: labelColor.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        )),
                    if (confidence > 0 && !isProcessing) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _confidenceColor(confidence).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${(confidence * 100).toInt()}%',
                            style: TextStyle(
                              color: _confidenceColor(confidence),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: Center(
                    child: isListening
                        ? _buildWaveform()
                        : isProcessing
                            ? _buildProcessingDots(labelColor)
                            : Text(
                                text ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: text == 'Tap the orb to start speaking' ||
                                          text == 'Translation appears here'
                                      ? 16
                                      : 24,
                                  color: text == 'Tap the orb to start speaking' ||
                                          text == 'Translation appears here'
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.white,
                                  fontWeight: text == 'Tap the orb to start speaking' ||
                                          text == 'Translation appears here'
                                      ? FontWeight.w300
                                      : FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                  ),
                ),

                // Speaker button
                if (showSpeaker)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: onSpeakerTap,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: labelColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: labelColor.withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.volume_up_rounded, color: labelColor, size: 22),
                      ),
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Waveform ──────────────────────────────────────────────────────────────
  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _recordingRipple,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(12, (i) {
            final offset = _recordingRipple.value * 2 * pi + i * 0.5;
            final height = 8.0 + sin(offset) * 24.0;
            return Container(
              width: 4,
              height: height.abs() + 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.6 + sin(offset) * 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Processing Dots ───────────────────────────────────────────────────────
  Widget _buildProcessingDots(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(delay: (i * 200).ms)
            .then()
            .fadeOut(delay: 400.ms)
            .then()
            .fadeIn(delay: 200.ms),
      ),
    );
  }

  // ── The Orb ───────────────────────────────────────────────────────────────
  Widget _buildOrb() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: _orbPulse,
        builder: (context, _) {
          final pulse = _orbPulse.value;
          final isActive = _isRecording;
          final baseSize = isActive ? 110.0 : 90.0;
          final glowSize = isActive ? 50.0 : 20.0 + pulse * 15.0;
          final glowOpacity = isActive ? 0.6 : 0.25 + pulse * 0.15;

          return Container(
            height: 160,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ripple (recording)
                if (isActive)
                  AnimatedBuilder(
                    animation: _recordingRipple,
                    builder: (context, _) {
                      return Container(
                        width: baseSize + 60 + _recordingRipple.value * 40,
                        height: baseSize + 60 + _recordingRipple.value * 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.redAccent
                                .withValues(alpha: 0.5 - _recordingRipple.value * 0.5),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),

                // Glow
                Container(
                  width: baseSize + glowSize,
                  height: baseSize + glowSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isActive ? Colors.redAccent : Colors.cyanAccent)
                            .withValues(alpha: glowOpacity),
                        blurRadius: isActive ? 60 : 40,
                        spreadRadius: isActive ? 15 : 5,
                      ),
                    ],
                  ),
                ),

                // Orb body
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: baseSize,
                  height: baseSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isActive
                          ? [const Color(0xFFFF4444), const Color(0xFFCC1111)]
                          : _isProcessing
                              ? [Colors.amber, Colors.orange]
                              : [const Color(0xFF00E5FF), const Color(0xFF2979FF)],
                      focal: const Alignment(-0.2, -0.3),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: _isProcessing
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          isActive ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: isActive ? 44 : 36,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _confidenceColor(double c) {
    if (c >= 0.8) return Colors.greenAccent;
    if (c >= 0.5) return Colors.amberAccent;
    return Colors.redAccent;
  }
}
