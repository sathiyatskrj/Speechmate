import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/whisper_service.dart';
import 'package:speechmate/widgets/voice_reactive_aurora.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceTranslatorScreen extends StatefulWidget {
  const VoiceTranslatorScreen({super.key});

  @override
  State<VoiceTranslatorScreen> createState() => _VoiceTranslatorScreenState();
}

class _VoiceTranslatorScreenState extends State<VoiceTranslatorScreen> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final WhisperService _whisperService = WhisperService();
  final NeuralEngineService _neuralEngine = NeuralEngineService();
  final TtsService _ttsService = TtsService();

  bool _isRecording = false;
  bool _isProcessing = false;
  String _englishText = "Hold the glowing orb to speak...";
  String _nicobareseText = "Translation will appear here";
  String _audioPath = '';
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initServices();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initServices() async {
    await _whisperService.initialize();
    _neuralEngine.init();
    _ttsService.init();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isProcessing) return; 
    
    try {
      await _ttsService.stop();
      if (await _audioRecorder.hasPermission()) {
        final Directory tempDir = await getTemporaryDirectory();
        _audioPath = '${tempDir.path}/translation_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: _audioPath,
        );

        if (mounted) {
          setState(() {
            _isRecording = true;
            _englishText = "Listening...";
            _nicobareseText = "Translation will appear here";
          });
          _pulseController.duration = const Duration(milliseconds: 500); // Faster pulse while recording
          _pulseController.repeat(reverse: true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
      }
    } catch (e) {
      debugPrint('[VoiceTranslator] Start recording error: $e');
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecordingAndTranslate() async {
    if (!_isRecording) return; 
    
    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (e) {
      debugPrint('[VoiceTranslator] Stop recording error: $e');
    }
    
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _englishText = "Processing neural networks...";
      });
      _pulseController.duration = const Duration(seconds: 2); // Return to slow pulse
      _pulseController.repeat(reverse: true);
    }

    if (path != null && File(path).existsSync()) {
      try {
        final String transcription = await _whisperService.transcribe(path).timeout(const Duration(seconds: 15));
        
        if (transcription.trim().isEmpty) {
          if (mounted) {
            setState(() {
              _englishText = "Could not understand audio. Try again.";
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _englishText = transcription;
            _nicobareseText = "Translating context...";
          });
        }

        final result = await _neuralEngine.predict(transcription).timeout(const Duration(seconds: 10));
        
        if (mounted) {
          setState(() {
            _nicobareseText = result.text;
          });
        }

        _ttsService.speakNicobarese(result.text, englishWord: transcription);

      } catch (e) {
        debugPrint('[VoiceTranslator] Processing error: $e');
        if (mounted) {
          setState(() {
            _englishText = "Error processing audio. Try again.";
            _nicobareseText = "Translation will appear here";
          });
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    } else {
      if (mounted) {
        setState(() {
          _englishText = "Hold the glowing orb to speak...";
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate Dark
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Voice Translator', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: VoiceReactiveAurora(
        isDark: true, // Use deep oceanic colors
        child: SafeArea(
          child: Column(
            children: [
              // Top Panel - English Input (Glassmorphism)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2), width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "English Transcription",
                              style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
                            ),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _englishText,
                                key: ValueKey<String>(_englishText),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: _isRecording ? 22 : 26,
                                  color: _isRecording ? Colors.white.withValues(alpha: 0.8) : Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Middle - Siri-Style Orb Record Button
              Container(
                height: 160,
                alignment: Alignment.center,
                child: TapScale(
                  onTap: () {}, // Handled by gesture detector below for hold
                  scaleFactor: 0.85,
                  child: GestureDetector(
                    onTapDown: (_) => _startRecording(),
                    onTapUp: (_) => _stopRecordingAndTranslate(),
                    onTapCancel: () => _stopRecordingAndTranslate(),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: _isRecording ? 120 : 100,
                          height: _isRecording ? 120 : 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _isRecording 
                                ? [Colors.redAccent, Colors.deepOrangeAccent] 
                                : [Colors.cyanAccent, Colors.blueAccent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.4 + (_pulseController.value * 0.4)),
                                blurRadius: _isRecording ? 50 : 30 + (_pulseController.value * 20),
                                spreadRadius: _isRecording ? 20 : 10 + (_pulseController.value * 10),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: _isRecording ? 50 : 40,
                          ).animate(target: _isRecording ? 1 : 0).shimmer(duration: 1200.ms, color: Colors.white),
                        );
                      }
                    ),
                  ),
                ),
              ),

              // Bottom Panel - Translation Output
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Nicobarese Translation",
                              style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
                            ),
                            const SizedBox(height: 20),
                            if (_isProcessing)
                              const CircularProgressIndicator(color: Colors.tealAccent)
                            else
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _nicobareseText,
                                  key: ValueKey<String>(_nicobareseText),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            if (!_isProcessing && _nicobareseText != "Translation will appear here")
                              TapScale(
                                onTap: () {
                                  _ttsService.speakNicobarese(_nicobareseText, englishWord: _englishText);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5)),
                                  ),
                                  child: const Icon(Icons.volume_up_rounded, color: Colors.tealAccent, size: 28),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
