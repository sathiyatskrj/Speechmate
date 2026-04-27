import 'package:flutter/material.dart';
import 'dart:math';
import '../services/dictionary_service.dart';
import '../services/neural_engine_service.dart';
import '../services/database_manager.dart';
import '../widgets/nicobarese_keyboard.dart';
import '../widgets/anim/confetti_overlay.dart';

class ChatTranslateScreen extends StatefulWidget {
  const ChatTranslateScreen({super.key});

  @override
  State<ChatTranslateScreen> createState() => _ChatTranslateScreenState();
}

class _ChatTranslateScreenState extends State<ChatTranslateScreen> with TickerProviderStateMixin {
  final DictionaryService dictionaryService = DictionaryService();
  final NeuralEngineService neuralEngine = NeuralEngineService(); // [NEW] Added Neural Engine
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  final List<Map<String, dynamic>> messages = [];
  bool isTyping = false;
  int messageCount = 0;
  
  // Magic Easter egg
  bool showConfetti = false;
  // Removed local confettiController to use ConfettiOverlay state management
  
  // Custom Keyboard
  bool _showCustomKeyboard = false;
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    dictionaryService.loadDictionary(DictionaryType.words);
    
    // Removed local confettiController initialization
    
    // Welcome message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          messages.add({
            "text": "👋 Hello! I'm your Nicobarese translator. Type any word to translate!",
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
      _showCustomKeyboard = false; // Hide keyboard on send
    });

    _scrollToBottom();

    // Easter egg: Every 10th message triggers confetti
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

    // Simulate typing delay
    await Future.delayed(const Duration(milliseconds: 800));

    // 1. Try Direct Lookup
    var result = await dictionaryService.searchWord(input);

    String responseText;
    String emoji = "💬";

    // 2. Fallback to Neural Engine (for sentences or fuzzy words)
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
          // Neural Engine Result
          responseText = "✨ ${result['nicobarese']}\n\n🤖 AI Translation";
          emoji = "🤖";
      } else if (isNicobarese) {
        responseText = "✨ ${result['english']}\n\n🔤 English translation";
        emoji = "🌴";
      } else {
        responseText = "✨ ${result['nicobarese']}\n\n🌴 Nicobarese translation";
        emoji = "📚";
      }
    } else {
      responseText = "🤔 Hmm, I couldn't find that word in my dictionary. Try another one!";
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
          "word_data": result, // Important for flashcards
        });
      });
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
        final messageMaxWidth = screenWidth * 0.75;
        final messagePadding = isSmallScreen ? 12.0 : 14.0;
        
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text("Chat Translator"),
              ],
            ),
            backgroundColor: const Color(0xFF1E1E2C),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Tip: Every 10th message has a surprise! 🎉',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('💡 Tip: Keep chatting for surprises!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ConfettiOverlay(
            isPlaying: showConfetti,
            child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                ),
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

                            return TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 300),
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, double value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isUser) ...[
                                        Text(emoji, style: const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 8),
                                      ],
                                      Container(
                                        constraints: BoxConstraints(maxWidth: messageMaxWidth),
                                        padding: EdgeInsets.all(messagePadding),
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
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          msg['text']!,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: messageFontSize,
                                            height: 1.4,
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                      if (!isUser && msg.containsKey('word_data') && msg['word_data'] != null && !msg['word_data'].containsKey('generated')) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          decoration: BoxDecoration(color: const Color(0xFF2A2A3D), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                          child: IconButton(
                                            icon: const Icon(Icons.bookmark_add_rounded, size: 20, color: Colors.orangeAccent),
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Save to Flashcards',
                                            onPressed: () async {
                                              final word = msg['word_data'];
                                              final english = word['english'] ?? word['text'];
                                              final nicobarese = word['nicobarese'];
                                              if (english != null && nicobarese != null) {
                                                  await DatabaseManager.instance.saveFlashcard(english.toString(), nicobarese.toString());
                                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to your Flashcards! 📚')));
                                              }
                                            },
                                          )
                                        )
                                      ],
                                      if (isUser) ...[
                                        const SizedBox(width: 8),
                                        Text(emoji, style: const TextStyle(fontSize: 20)),
                                      ],
                                    ],
                                  ),
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
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: TextField(
                                  controller: controller,
                                  focusNode: _focusNode,
                                  readOnly: _showCustomKeyboard,
                                  showCursor: true,
                                  decoration: InputDecoration(
                                    hintText: "Type a word...",
                                    hintStyle: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16 : 18,
                                      vertical: 12,
                                    ),
                                    suffixIcon: controller.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 20, color: Colors.white54),
                                            onPressed: () {
                                              setState(() => controller.clear());
                                            },
                                          )
                                        : null,
                                  ),
                                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                  onChanged: (value) {
                                    setState(() {}); // Rebuild for clear button
                                  },
                                  onSubmitted: (_) => translateText(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal.shade600, Colors.teal.shade700],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.send_rounded, size: isSmallScreen ? 20 : 22),
                                color: Colors.white,
                                onPressed: translateText,
                                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                              ),
                            ),
                            // [NEW] Toggle custom keyboard
                            IconButton(
                              icon: Icon(_showCustomKeyboard ? Icons.keyboard_hide : Icons.keyboard, color: Colors.cyanAccent),
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
          color: const Color(0xFF2A2A3D),
          borderRadius: BorderRadius.circular(16),
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
            decoration: BoxDecoration(
              color: Colors.cyanAccent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
