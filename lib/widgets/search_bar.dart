import 'package:flutter/material.dart';

class Search extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final VoidCallback? onVoiceSearch; // NEW

  const Search({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClear,
    this.onVoiceSearch, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Search words",
                hintStyle: TextStyle(color: Colors.black45),
                border: InputBorder.none,
              ),
              onChanged: (_) {},
            ),
          ),
          // Microphone button (NEW)
          if (onVoiceSearch != null)
            IconButton(
              icon: const Icon(Icons.mic, color: Colors.redAccent),
              onPressed: onVoiceSearch,
              tooltip: 'Voice Search',
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearch,
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}
