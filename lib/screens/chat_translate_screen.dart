import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';

class ChatTranslateScreen extends StatefulWidget {
  const ChatTranslateScreen({super.key});

  @override
  State<ChatTranslateScreen> createState() => _ChatTranslateScreenState();
}

class _ChatTranslateScreenState extends State<ChatTranslateScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DictionaryService _dictionaryService = DictionaryService();
  
  List<Map<String, String>> messages = [
    {"role": "bot", "text": "Hello! Type a word in English or Nicobarese, and I will translate it for you."}
  ];

  @override
  void initState() {
    super.initState();
    _dictionaryService.loadAll();
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text.trim();
    
    setState(() {
      messages.add({"role": "user", "text": userText});
      _controller.clear();
    });
    
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 600));

    final result = await _dictionaryService.searchEverywhere(userText);
    String botReply = "Sorry, I don't know that word yet.";
    
    if (result != null) {
      if (result['_type'] == 'words') {
        bool searchedNicobarese = result['_searchedNicobarese'] == true;
        if (searchedNicobarese) {
          botReply = "English: ${result['english']}";
        } else {
          botReply = "Nicobarese: ${result['nicobarese']}";
        }
      } else {
        botReply = "Phrase: ${result['text']}\nTranslation found in list.";
      }
    }

    setState(() {
      messages.add({"role": "bot", "text": botReply});
    });
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Translator"),
        backgroundColor: const Color(0xFF38BDF8),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF38BDF8) : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a word...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFF38BDF8),
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
