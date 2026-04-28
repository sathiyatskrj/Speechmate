import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../services/whisper_service.dart';
import '../services/dictionary_service.dart';
import '../services/neural_engine_service.dart';
import '../services/tts_service.dart';
import '../services/regional_translation_service.dart';
import 'regional_translator_screen.dart'; // for RegionalLanguageConfig

class OmniTranslatorScreen extends StatefulWidget {
  const OmniTranslatorScreen({super.key});

  @override
  State<OmniTranslatorScreen> createState() => _OmniTranslatorScreenState();
}

class _OmniTranslatorScreenState extends State<OmniTranslatorScreen> {
  bool _isListening = false;
  bool _isProcessing = false;
  AudioRecorder? _audioRecorder;
  String? _lastAudioPath;

  final WhisperService _whisperService = WhisperService();
  final DictionaryService _dictionaryService = DictionaryService();
  final NeuralEngineService _neuralEngine = NeuralEngineService();
  final TtsService _ttsService = TtsService();
  final RegionalTranslationService _regionalTranslation = RegionalTranslationService();

  String _nicobareseText = "";
  String _englishText = "";
  
  final List<RegionalLanguageConfig> _configs = [
    RegionalLanguageConfig('Hindi', TranslateLanguage.hindi, 'hi', 'hi-IN', ''),
    RegionalLanguageConfig('Tamil', TranslateLanguage.tamil, 'ta', 'ta-IN', ''),
    RegionalLanguageConfig('Bengali', TranslateLanguage.bengali, 'bn', 'bn-IN', ''),
    RegionalLanguageConfig('Telugu', TranslateLanguage.telugu, 'te', 'te-IN', ''),
    RegionalLanguageConfig('Malayalam', null, 'ml', 'ml-IN', ''),
  ];

  final Map<String, String> _translations = {};

  @override
  void initState() {
    super.initState();
    _whisperService.initialize();
    _ttsService.init();
    _dictionaryService.loadDictionary(DictionaryType.words);
    
    for (var config in _configs) {
      _translations[config.name] = "Waiting for input...";
    }
  }

  void _cleanupTempFile() {
    if (_lastAudioPath != null) {
      try {
        final f = File(_lastAudioPath!);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _audioRecorder?.dispose();
    _cleanupTempFile();
    _regionalTranslation.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (!_isListening) {
      await _ttsService.stop();
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();
      if (!await _audioRecorder!.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mic permission required')));
        return;
      }
      final Directory tempDir = await getTemporaryDirectory();
      _lastAudioPath = '${tempDir.path}/omni_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      final config = const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1);
      await _audioRecorder!.start(config, path: _lastAudioPath!);
      setState(() {
        _isListening = true;
        _nicobareseText = "Recording...";
        _englishText = "";
        for (var c in _configs) {
          _translations[c.name] = "Waiting...";
        }
      });
    } else {
      setState(() {
        _isListening = false;
        _isProcessing = true;
        _nicobareseText = "Transcribing Nicobarese...";
      });
      final path = await _audioRecorder!.stop();
      if (path != null) {
        await _processAudio(path);
      } else {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processAudio(String path) async {
    // 1. Nicobarese Audio -> English Text (Whisper)
    final transcribed = await _whisperService.transcribe(path);
    if (transcribed.isEmpty) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _nicobareseText = "Could not hear clearly.";
        });
      }
      return;
    }

    String englishTranslation = transcribed;
    String nicoWord = "";

    // Try mapping back to actual Nicobarese word to display it
    var dictResult = await _dictionaryService.searchWord(englishTranslation);
    if (dictResult != null && dictResult['english'] != null) {
      englishTranslation = dictResult['english'].toString();
      nicoWord = dictResult['nicobarese'].toString();
    } else {
      final neuralResult = await _neuralEngine.predict(englishTranslation);
      if (neuralResult.text.isNotEmpty && neuralResult.text != englishTranslation) {
        nicoWord = neuralResult.text;
      } else {
        nicoWord = englishTranslation; // Fallback
      }
    }

    if (mounted) {
      setState(() {
        _englishText = englishTranslation;
        _nicobareseText = nicoWord;
      });
    }

    // 2. English -> All Regional Languages
    for (var config in _configs) {
      setState(() {
        _translations[config.name] = "Translating...";
      });
      
      await _regionalTranslation.initialize(config.mlKitLanguage);
      final translation = await _regionalTranslation.translateFromEnglish(
          englishTranslation, fallbackLangCode: config.fallbackLanguageCode);
          
      if (mounted) {
        setState(() {
          _translations[config.name] = translation;
        });
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Omni Translator (Broadcast)"),
        backgroundColor: const Color(0xFF1E1E2C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section - Nicobarese Input
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E2C),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const Text("Nicobarese Input", style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 10),
                  Text(
                    _nicobareseText.isEmpty ? "Tap mic to speak Nicobarese" : _nicobareseText,
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (_englishText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text("(English: $_englishText)", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.redAccent : Colors.cyan.withValues(alpha: 0.2),
                        border: Border.all(color: _isListening ? Colors.red : Colors.cyanAccent, width: 3),
                        boxShadow: _isListening ? [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 20)] : [],
                      ),
                      child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isProcessing) const LinearProgressIndicator(color: Colors.cyanAccent),
                ],
              ),
            ),
            
            // Bottom Section - Regional Outputs
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _configs.length,
                itemBuilder: (context, index) {
                  final config = _configs[index];
                  final translation = _translations[config.name] ?? "Waiting...";
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      title: Text(config.name, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          translation,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Colors.cyanAccent),
                        onPressed: () {
                          if (translation != "Waiting..." && translation != "Translating...") {
                            _ttsService.speakRegional(translation, config.localeId);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
