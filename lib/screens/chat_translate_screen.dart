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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Text Translator"),
      ),
      body: Column(
        children: [
          /// CHAT AREA
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['type'] == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 280),
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
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// INPUT BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
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
                    decoration: const InputDecoration(
                      hintText: "Type text to translate...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.teal,
                  onPressed: translateText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
