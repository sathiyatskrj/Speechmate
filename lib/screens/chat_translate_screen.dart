import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';

class ChatTranslateScreen extends StatefulWidget {
  const ChatTranslateScreen({super.key});

  @override
  State<ChatTranslateScreen> createState() => _ChatTranslateScreenState();
}

class _ChatTranslateScreenState extends State<ChatTranslateScreen> {
  final DictionaryService dictionaryService = DictionaryService();
  final TextEditingController controller = TextEditingController();

  final List<Map<String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    dictionaryService.load();
  }

  void translateText() {
    final input = controller.text.trim();
    if (input.isEmpty) return;

    final result = dictionaryService.search(input);

    setState(() {
      // user message
      messages.add({
        "text": input,
        "type": "user",
      });

      // translated message
      messages.add({
        "text": result != null
            ? "${result['english']} ↔ ${result['nicobarese']}"
            : "Translation not found",
        "type": "bot",
      });

      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width < 400;
    
    // Responsive values
    final messageFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
    final messageMaxWidth = screenSize.width * 0.75; // 75% of screen width
    final messagePadding = isSmallScreen ? 10.0 : 12.0;
    final chatPadding = isSmallScreen ? 8.0 : 12.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Text Translator"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            /// CHAT AREA
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(chatPadding),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isUser = msg['type'] == 'user';

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                      padding: EdgeInsets.all(messagePadding),
                      constraints: BoxConstraints(
                        maxWidth: messageMaxWidth,
                        minWidth: 60,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.teal.shade600
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: messageFontSize,
                          height: 1.3,
                        ),
                        softWrap: true,
                      ),
                    ),
                  );
                },
              ),
            ),

            /// INPUT BAR
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 6 : 8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Type text to translate...",
                        hintStyle: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: 8,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    color: Colors.teal,
                    onPressed: translateText,
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
