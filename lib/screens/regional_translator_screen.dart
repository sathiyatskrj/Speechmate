import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../services/regional_translation_service.dart';
import '../services/dictionary_service.dart';
import '../services/neural_engine_service.dart';
import '../services/tts_service.dart';
import 'dart:math';

class RegionalLanguageConfig {
  final String name;
  final TranslateLanguage mlKitLanguage;
  final String localeId;
  final String sampleWord;

  RegionalLanguageConfig(this.name, this.mlKitLanguage, this.localeId, this.sampleWord);
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
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _dictionaryService.loadDictionary(DictionaryType.words);
    _ttsService.init();
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

  Future<void> _processTranslation(String regionalText) async {
    if (regionalText.isEmpty) return;

    setState(() {
      _messages.add({"text": regionalText, "type": "user"});
      _isTyping = true;
    });
    _scrollToBottom();
    _textController.clear();

    // 1. Regional -> English (Offline ML Kit)
    final englishTranslation = await _regionalTranslation.translateToEnglish(regionalText);

    // 2. English -> Nicobarese (Offline Dictionary / Neural Engine)
    var dictResult = await _dictionaryService.searchWord(englishTranslation);
    
    String responseText;
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
        _messages.add({
          "text": responseText,
          "type": "bot",
          "emoji": nicobareseText.isNotEmpty ? "🌴" : "❓"
        });
      });
      if (nicobareseText.isNotEmpty) {
        _ttsService.speakNicobarese(nicobareseText, englishWord: englishTranslation);
      }
    }
    _scrollToBottom();
  }

  void _listen() async {
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

  @override
  void dispose() {
    _regionalTranslation.dispose();
    _ttsService.dispose();
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
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _listen,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.redAccent : Colors.grey.withOpacity(0.2),
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
                          hintText: "Type in ${widget.config.name}...",
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
