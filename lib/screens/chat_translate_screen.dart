import 'package:flutter/material.dart';
import 'dart:math';
import '../services/dictionary_service.dart';

class ChatTranslateScreen extends StatefulWidget {
  const ChatTranslateScreen({super.key});

  @override
  State<ChatTranslateScreen> createState() => _ChatTranslateScreenState();
}

class _ChatTranslateScreenState extends State<ChatTranslateScreen> with TickerProviderStateMixin {
  final DictionaryService dictionaryService = DictionaryService();
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  final List<Map<String, dynamic>> messages = [];
  bool isTyping = false;
  int messageCount = 0;
  
  // Magic Easter egg
  bool showConfetti = false;
  late AnimationController confettiController;
  
  @override
  void initState() {
    super.initState();
    dictionaryService.loadDictionary(DictionaryType.words);
    
    confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
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
    });

    _scrollToBottom();

    // Easter egg: Every 10th message triggers confetti
    if (messageCount % 10 == 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => showConfetti = true);
          confettiController.forward(from: 0);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => showConfetti = false);
          });
        }
      });
    }

    // Simulate typing delay
    await Future.delayed(const Duration(milliseconds: 800));

    final result = await dictionaryService.searchWord(input);

    String responseText;
    String emoji = "💬";

    if (result != null) {
      final isNicobarese = result['nicobarese'].toString().toLowerCase() == input.toLowerCase();
      
      if (isNicobarese) {
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
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width < 400;
    
    final messageFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
    final messageMaxWidth = screenSize.width * 0.75;
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
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.teal.shade50,
                  Colors.white,
                ],
              ),
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
                                            ? [Colors.teal.shade600, Colors.teal.shade700]
                                            : [Colors.white, Colors.grey.shade50],
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                                        bottomRight: Radius.circular(isUser ? 4 : 16),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      msg['text']!,
                                      style: TextStyle(
                                        color: isUser ? Colors.white : Colors.black87,
                                        fontSize: messageFontSize,
                                        height: 1.4,
                                      ),
                                      softWrap: true,
                                    ),
                                  ),
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
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
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
                                        icon: const Icon(Icons.clear, size: 20),
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
                                color: Colors.teal.withOpacity(0.3),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Confetti Animation (Easter Egg)
          if (showConfetti)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(confettiController.value),
                    size: Size.infinite,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
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
              color: Colors.teal.shade400,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// Confetti Painter for Easter Egg
class ConfettiPainter extends CustomPainter {
  final double progress;
  final Random random = Random(42);

  ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final startY = -20.0;
      final endY = size.height;
      final y = startY + (endY - startY) * progress;
      
      final colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
        Colors.pink,
      ];
      
      paint.color = colors[i % colors.length].withOpacity(0.8);
      
      final rotation = (progress * 360 * (i % 3)) * pi / 180;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-5, -5, 10, 10),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
