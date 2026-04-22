import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/whisper_service.dart';

class VoiceTranslatorScreen extends StatefulWidget {
  const VoiceTranslatorScreen({super.key});

  @override
  State<VoiceTranslatorScreen> createState() => _VoiceTranslatorScreenState();
}

class _VoiceTranslatorScreenState extends State<VoiceTranslatorScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final WhisperService _whisperService = WhisperService();
  final NeuralEngineService _neuralEngine = NeuralEngineService();
  final TtsService _ttsService = TtsService();

  bool _isRecording = false;
  bool _isProcessing = false;
  String _englishText = "Hold the microphone to speak...";
  String _nicobareseText = "Translation will appear here";
  String _audioPath = '';

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _whisperService.initialize();
    _neuralEngine.init();
    _ttsService.init();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isProcessing) return; // Block re-entry while processing
    
    try {
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
    if (!_isRecording) return; // Guard against double-tap
    
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
        _englishText = "Processing audio...";
      });
    }

    if (path != null && File(path).existsSync()) {
      try {
        // 1. Transcribe with Whisper (Offline)
        final String transcription = await _whisperService.transcribe(path);
        
        if (transcription.trim().isEmpty) {
          if (mounted) {
            setState(() {
              _englishText = "Could not understand audio. Try again.";
              _isProcessing = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _englishText = transcription;
            _nicobareseText = "Translating...";
          });
        }

        // 2. Translate with Neural Engine (Offline)
        final result = await _neuralEngine.predict(transcription);
        
        if (mounted) {
          setState(() {
            _nicobareseText = result.text;
            _isProcessing = false;
          });
        }

        // 3. Auto-play translation
        _ttsService.speakNicobarese(result.text, englishWord: transcription);

      } catch (e) {
        debugPrint('[VoiceTranslator] Processing error: $e');
        if (mounted) {
          setState(() {
            _englishText = "Error processing audio. Try again.";
            _nicobareseText = "Translation will appear here";
            _isProcessing = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _englishText = "Hold the microphone to speak...";
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Voice Translator', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Panel - English Input
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "English",
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _englishText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _isRecording ? 24 : 28,
                        color: _isRecording ? Colors.white70 : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Middle - Record Button
            Container(
              height: 120,
              alignment: Alignment.center,
              child: GestureDetector(
                onTapDown: (_) => _startRecording(),
                onTapUp: (_) => _stopRecordingAndTranslate(),
                onTapCancel: () => _stopRecordingAndTranslate(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isRecording ? 90 : 80,
                  height: _isRecording ? 90 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.redAccent : Colors.cyanAccent,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.redAccent : Colors.cyanAccent).withOpacity(0.4),
                        blurRadius: _isRecording ? 30 : 15,
                        spreadRadius: _isRecording ? 10 : 5,
                      )
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: _isRecording ? Colors.white : Colors.black87,
                    size: 40,
                  ),
                ),
              ),
            ),

            // Bottom Panel - Translation Output
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Nicobarese",
                      style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 20),
                    if (_isProcessing)
                      const CircularProgressIndicator(color: Colors.tealAccent)
                    else
                      Text(
                        _nicobareseText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (!_isProcessing && _nicobareseText != "Translation will appear here")
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.tealAccent, size: 32),
                        onPressed: () {
                          _ttsService.speakNicobarese(_nicobareseText, englishWord: _englishText);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
