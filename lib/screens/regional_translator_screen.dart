import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../services/regional_translation_service.dart';
import '../services/dictionary_service.dart';
import '../services/neural_engine_service.dart';
import '../services/tts_service.dart';
import '../services/whisper_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';

class RegionalLanguageConfig {
  final String name;
  final TranslateLanguage? mlKitLanguage;
  final String fallbackLanguageCode;
  final String localeId;
  final String sampleWord;

  RegionalLanguageConfig(this.name, this.mlKitLanguage, this.fallbackLanguageCode, this.localeId, this.sampleWord);
}

class RegionalTranslatorScreen extends StatefulWidget {
  final RegionalLanguageConfig config;

  const RegionalTranslatorScreen({super.key, required this.config});

  @override
  State<RegionalTranslatorScreen> createState() => _RegionalTranslatorScreenState();
}

class _RegionalTranslatorScreenState extends State<RegionalTranslatorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final RegionalTranslationService _regionalTranslation = RegionalTranslationService();
  final DictionaryService _dictionaryService = DictionaryService();
  final NeuralEngineService _neuralEngine = NeuralEngineService();
  final TtsService _ttsService = TtsService();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  final List<Map<String, dynamic>> _messages = [];
  bool _isInitializing = true;
  bool _isTyping = false;
  bool _isListening = false;
  bool _isNicobareseMode = false; // Bidirectional toggle
  AudioRecorder? _audioRecorder;
  final WhisperService _whisperService = WhisperService();
  String? _lastAudioPath;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _dictionaryService.loadDictionary(DictionaryType.words);
    _ttsService.init();
    _whisperService.initialize();
    _initTranslation();
  }

  Future<void> _initTranslation() async {
    setState(() { _isInitializing = true; _errorMsg = ''; });
    final success = await _regionalTranslation.initialize(widget.config.mlKitLanguage);
    if (mounted) {
      setState(() {
        _isInitializing = false;
        if (!success) {
          _errorMsg = "Failed to download offline models. Please check connection.";
        } else {
          _messages.add({
            "text": "👋 Namaste! You can now speak or type in ${widget.config.name}. I will translate it directly to Nicobarese for you. Try typing '${widget.config.sampleWord}'!",
            "type": "bot",
            "emoji": "✨"
          });
        }
      });
    }
  }

  Future<void> _processTranslation(String inputText, {bool isAlreadyEnglish = false}) async {
    if (inputText.isEmpty) return;

    setState(() {
      _messages.add({"text": inputText, "type": "user"});
      _isTyping = true;
    });
    _scrollToBottom();
    _textController.clear();

    String responseText;

    if (_isNicobareseMode) {
      // 1. Nicobarese -> English
      String englishTranslation = inputText;
      if (!isAlreadyEnglish) {
        var dictResult = await _dictionaryService.searchWord(inputText);
        if (dictResult != null && dictResult['english'] != null) {
          englishTranslation = dictResult['english'].toString();
        } else {
          final neuralResult = await _neuralEngine.predict(inputText);
          if (neuralResult.text.isNotEmpty) englishTranslation = neuralResult.text;
        }
      }

      // 2. English -> Regional
      final regionalTranslation = await _regionalTranslation.translateFromEnglish(
          englishTranslation, fallbackLangCode: widget.config.fallbackLanguageCode);

      responseText = "✨ $regionalTranslation\n\n(English: $englishTranslation)";

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({"text": responseText, "type": "bot", "emoji": "🗣️"});
        });
        _ttsService.speakRegional(regionalTranslation, widget.config.localeId);
      }
    } else {
      // 1. Regional -> English
      final englishTranslation = await _regionalTranslation.translateToEnglish(
          inputText, fallbackLangCode: widget.config.fallbackLanguageCode);

      // 2. English -> Nicobarese
      var dictResult = await _dictionaryService.searchWord(englishTranslation);
      String nicobareseText = "";

      if (dictResult != null) {
         nicobareseText = dictResult['nicobarese'].toString();
         responseText = "✨ $nicobareseText\n\n(English: ${dictResult['english']})";
      } else {
         final neuralResult = await _neuralEngine.predict(englishTranslation);
         if (neuralResult.text.isNotEmpty && neuralResult.text != englishTranslation) {
             nicobareseText = neuralResult.text;
             responseText = "✨ $nicobareseText\n\n🤖 AI Translation (English: $englishTranslation)";
         } else {
             responseText = "🤔 I translated it to English as '$englishTranslation', but I don't know the Nicobarese word for it yet.";
         }
      }

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({"text": responseText, "type": "bot", "emoji": nicobareseText.isNotEmpty ? "🌴" : "❓"});
        });
        if (nicobareseText.isNotEmpty) {
          _ttsService.speakNicobarese(nicobareseText, englishWord: englishTranslation);
        }
      }
    }
    _scrollToBottom();
  }

  void _listen() {
    if (_isNicobareseMode) {
      _listenNicobarese();
    } else {
      _listenRegional();
    }
  }

  void _listenNicobarese() async {
    if (!_isListening) {
      await _ttsService.stop();
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();
      if (!await _audioRecorder!.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mic permission required')));
        return;
      }
      final Directory tempDir = await getTemporaryDirectory();
      _lastAudioPath = '${tempDir.path}/rt_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      final config = const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1);
      await _audioRecorder!.start(config, path: _lastAudioPath!);
      setState(() => _isListening = true);
    } else {
      setState(() => _isListening = false);
      final path = await _audioRecorder!.stop();
      if (path != null) {
        setState(() {
          _messages.add({"text": "🎤 Transcribing...", "type": "user"});
          _isTyping = true;
        });
        _scrollToBottom();
        final result = await _whisperService.transcribe(path);
        if (mounted) {
          if (result.isNotEmpty) {
            // Remove the temporary "Transcribing" message
            _messages.removeLast();
            _processTranslation(result, isAlreadyEnglish: true);
          } else {
            setState(() {
              _isTyping = false;
              _messages.removeLast();
              _messages.add({"text": "Couldn't hear you clearly. Please try again.", "type": "bot", "emoji": "⚠️"});
            });
          }
        }
      }
    }
  }

  void _listenRegional() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        await _ttsService.stop();
        _speechToText.listen(
          onResult: (val) {
            if (val.hasConfidenceRating && val.confidence > 0) {
              if (val.finalResult) {
                 _textController.text = val.recognizedWords;
                 _processTranslation(val.recognizedWords);
                 setState(() => _isListening = false);
              } else {
                 _textController.text = val.recognizedWords;
              }
            }
          },
          localeId: widget.config.localeId,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
    _regionalTranslation.dispose();
    _ttsService.dispose();
    _audioRecorder?.dispose();
    _cleanupTempFile();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("${widget.config.name} Translator"),
        backgroundColor: const Color(0xFF1E1E2C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Row(
            children: [
              Text("Teacher", style: TextStyle(color: _isNicobareseMode ? Colors.white54 : Colors.cyanAccent, fontSize: 12)),
              Switch(
                value: _isNicobareseMode,
                activeColor: Colors.amberAccent,
                inactiveThumbColor: Colors.cyanAccent,
                inactiveTrackColor: Colors.cyan.withValues(alpha: 0.3),
                onChanged: (val) {
                  setState(() {
                    _isNicobareseMode = val;
                  });
                },
              ),
              Text("Student", style: TextStyle(color: _isNicobareseMode ? Colors.amberAccent : Colors.white54, fontSize: 12)),
              const SizedBox(width: 10),
            ],
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isInitializing)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.cyanAccent),
                      const SizedBox(height: 16),
                      Text("Downloading ${widget.config.name} Offline Model...", 
                        style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              )
            else if (_errorMsg.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(_errorMsg, style: const TextStyle(color: Colors.redAccent)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    final msg = _messages[index];
                    final isUser = msg['type'] == 'user';
                    final emoji = msg['emoji'] ?? (isUser ? '👤' : '🤖');

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isUser) ...[Text(emoji, style: const TextStyle(fontSize: 20)), const SizedBox(width: 8)],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isUser
                                        ? [Colors.cyan.shade600, Colors.blue.shade700]
                                        : [const Color(0xFF1E1E2C), const Color(0xFF2A2A3D)],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  msg['text']!,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                                ),
                              ),
                            ),
                            if (isUser) ...[const SizedBox(width: 8), Text(emoji, style: const TextStyle(fontSize: 20))],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _listen,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.redAccent : Colors.grey.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _isNicobareseMode ? "Type in Nicobarese..." : "Type in ${widget.config.name}...",
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onSubmitted: _processTranslation,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.teal.shade600, Colors.teal.shade700]),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, size: 22),
                      color: Colors.white,
                      onPressed: () => _processTranslation(_textController.text.trim()),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF2A2A3D), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0), const SizedBox(width: 4), _buildDot(1), const SizedBox(width: 4), _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final offset = sin((value + index * 0.3) * pi * 2) * 3;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle)),
        );
      },
    );
  }
}
