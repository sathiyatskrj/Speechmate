import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:speechmate/services/dictionary_service.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/widgets/nicobarese_keyboard.dart';
import 'package:speechmate/widgets/anim/confetti_overlay.dart';

// ────── DUOLINGO-STYLE VIBRANT LIGHT PALETTE ──────
class _DuoColors {
  static const bg = Color(0xFFF7F7F7);
  static const white = Color(0xFFFFFFFF);
  static const green = Color(0xFF58CC02);
  static const blue = Color(0xFF1CB0F6);
  static const orange = Color(0xFFFF9600);
  static const yellow = Color(0xFFFFC800);
  static const teal = Color(0xFF00CD9C);
  static const textDark = Color(0xFF3C3C3C);
  static const textMuted = Color(0xFF777777);
  static const border = Color(0xFFE5E5E5);
  static const cardShadow = Color(0x0A000000);
}

class ChatTranslateScreen extends StatefulWidget {
  const ChatTranslateScreen({super.key});

  @override
  State<ChatTranslateScreen> createState() => _ChatTranslateScreenState();
}

class _ChatTranslateScreenState extends State<ChatTranslateScreen> with TickerProviderStateMixin {
  final DictionaryService dictionaryService = DictionaryService();
  final NeuralEngineService neuralEngine = NeuralEngineService();
  final TtsService _ttsService = TtsService();
  
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  final List<Map<String, dynamic>> messages = [];
  bool isTyping = false;
  int messageCount = 0;
  bool showConfetti = false;
  bool _showCustomKeyboard = false;
  
  @override
  void initState() {
    super.initState();
    dictionaryService.loadDictionary(DictionaryType.words);
    _ttsService.init();
    
    // Welcome message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          messages.add({
            "text": "👋 Hello! I'm your SpeechMate translation assistant. Type any word, phrase, or sentence to translate!",
            "type": "bot",
            "timestamp": DateTime.now(),
          });
        });
      }
    });
  }

  void translateText() async {
    final input = controller.text.trim();
    if (input.isEmpty) return;

    final userMessage = {
      "text": input,
      "type": "user",
      "timestamp": DateTime.now(),
    };

    setState(() {
      messages.add(userMessage);
      isTyping = true;
      messageCount++;
      controller.clear();
      _showCustomKeyboard = false; // Hide custom keyboard on send
    });

    _scrollToBottom();

    // Surprise confetti every 10th message
    if (messageCount % 10 == 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => showConfetti = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => showConfetti = false);
          });
        }
      });
    }

    await Future.delayed(const Duration(milliseconds: 800));

    // 1. Try Direct Lookup
    var result = await dictionaryService.searchWord(input);

    String responseText;
    String emoji = "💬";

    // 2. Fallback to Neural Engine for sentences/phrases
    if (result == null) {
      final neuralResult = await neuralEngine.predict(input);
      if (neuralResult.text.isNotEmpty) {
          result = {
            'english': input,
            'nicobarese': neuralResult.text,
            'generated': true
          };
      }
    }

    if (result != null) {
      final isNicobarese = result['nicobarese'].toString().toLowerCase() == input.toLowerCase();
      
      if (result.containsKey('generated')) {
          responseText = "✨ ${result['nicobarese']}\n\n🤖 AI Phrase Translation";
          emoji = "🤖";
      } else if (isNicobarese) {
        responseText = "✨ ${result['english']}\n\n🔤 English Translation";
        emoji = "🌴";
      } else {
        responseText = "✨ ${result['nicobarese']}\n\n🌴 Nicobarese Translation";
        emoji = "📚";
      }
    } else {
      responseText = "🤔 Hmm, I couldn't find a direct translation in the offline dictionary. Try phrasing it differently!";
      emoji = "❓";
    }

    if (mounted) {
      setState(() {
        isTyping = false;
        messages.add({
          "text": responseText,
          "type": "bot",
          "emoji": emoji,
          "timestamp": DateTime.now(),
          "word_data": result,
        });
      });

      // Auto TTS play for translation
      if (result != null) {
        final speechText = result['nicobarese'] ?? result['english'];
        _ttsService.speakNicobarese(speechText.toString(), englishWord: result['english']?.toString());
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ttsService.dispose();
    scrollController.dispose();
    controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;
        final isMediumScreen = screenWidth < 400;
        
        final messageFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
        final messageMaxWidth = screenWidth * 0.70;
        final messagePadding = isSmallScreen ? 12.0 : 14.0;
        
        return Scaffold(
          backgroundColor: _DuoColors.bg,
          appBar: AppBar(
            backgroundColor: _DuoColors.white,
            foregroundColor: _DuoColors.textDark,
            elevation: 0,
            shape: const Border(bottom: BorderSide(color: _DuoColors.border, width: 2)),
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: _DuoColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text("Chat Translator", style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: _DuoColors.textDark,
                )),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: _DuoColors.textMuted),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: _DuoColors.textDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: Text('💡 Tip: Try writing full sentences in English!', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ConfettiOverlay(
            isPlaying: showConfetti,
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      itemCount: messages.length + (isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length && isTyping) {
                          return _buildTypingIndicator();
                        }

                        final msg = messages[index];
                        final isUser = msg['type'] == 'user';
                        final emoji = msg['emoji'] ?? (isUser ? '👤' : '🤖');

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isUser) ...[
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: _DuoColors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: messageMaxWidth),
                                    padding: EdgeInsets.all(messagePadding),
                                    decoration: BoxDecoration(
                                      color: isUser ? _DuoColors.blue : _DuoColors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                                        bottomRight: Radius.circular(isUser ? 4 : 18),
                                      ),
                                      border: Border.all(
                                        color: isUser ? Colors.transparent : _DuoColors.border,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: _DuoColors.cardShadow,
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      msg['text']!,
                                      style: GoogleFonts.inter(
                                        color: isUser ? Colors.white : _DuoColors.textDark,
                                        fontSize: messageFontSize,
                                        fontWeight: isUser ? FontWeight.w700 : FontWeight.w600,
                                        height: 1.4,
                                      ),
                                      softWrap: true,
                                    ),
                                  ),
                                ),
                                if (!isUser && msg.containsKey('word_data') && msg['word_data'] != null) ...[
                                  const SizedBox(width: 6),
                                  // Speak Audio Button
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: _DuoColors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _DuoColors.border, width: 2),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.volume_up_rounded, size: 16, color: _DuoColors.blue),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        final word = msg['word_data'];
                                        final speechText = word['nicobarese'] ?? word['english'];
                                        _ttsService.speakNicobarese(speechText.toString(), englishWord: word['english']?.toString());
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Save to Flashcards Button
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: _DuoColors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _DuoColors.border, width: 2),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.bookmark_add_rounded, size: 16, color: _DuoColors.orange),
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        final word = msg['word_data'];
                                        final english = word['english'] ?? word['text'];
                                        final nicobarese = word['nicobarese'];
                                        if (english != null && nicobarese != null) {
                                            await DatabaseManager.instance.saveFlashcard(english.toString(), nicobarese.toString());
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Saved to your Flashcards! 📚'),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                                if (isUser) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: _DuoColors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Input Bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 8 : 10,
                    ),
                    decoration: const BoxDecoration(
                      color: _DuoColors.white,
                      border: Border(top: BorderSide(color: _DuoColors.border, width: 2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _DuoColors.bg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: _DuoColors.border, width: 2),
                            ),
                            child: TextField(
                              controller: controller,
                              focusNode: _focusNode,
                              readOnly: _showCustomKeyboard,
                              showCursor: true,
                              cursorColor: _DuoColors.blue,
                              decoration: InputDecoration(
                                hintText: "Type a word, phrase, or sentence...",
                                hintStyle: GoogleFonts.inter(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: _DuoColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 14 : 16,
                                  vertical: 10,
                                ),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18, color: _DuoColors.textMuted),
                                        onPressed: () {
                                          setState(() => controller.clear());
                                        },
                                      )
                                    : null,
                              ),
                              style: GoogleFonts.inter(
                                fontSize: isSmallScreen ? 14 : 15,
                                color: _DuoColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                              onChanged: (value) {
                                setState(() {}); // Rebuild for clear button
                              },
                              onSubmitted: (_) => translateText(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: const BoxDecoration(
                            color: _DuoColors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x2258CC02),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.send_rounded, size: isSmallScreen ? 18 : 20),
                            color: Colors.white,
                            onPressed: translateText,
                            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Keyboard toggle button
                        IconButton(
                          icon: Icon(
                            _showCustomKeyboard ? Icons.keyboard_hide : Icons.keyboard, 
                            color: _DuoColors.blue,
                          ),
                          onPressed: () {
                             setState(() {
                               _showCustomKeyboard = !_showCustomKeyboard;
                               if (_showCustomKeyboard) {
                                  _focusNode.unfocus(); // hide system keyboard
                               } else {
                                  _focusNode.requestFocus(); // show system keyboard
                               }
                             });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  if (_showCustomKeyboard)
                     NicobareseKeyboard(
                        controller: controller,
                        onSubmitted: translateText,
                        onClose: () => setState(() {
                            _showCustomKeyboard = false;
                            _focusNode.requestFocus();
                        })
                     ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _DuoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DuoColors.border, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
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
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _DuoColors.blue,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
