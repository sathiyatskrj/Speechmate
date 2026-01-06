import 'package:flutter/material.dart';

class Search extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const Search({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClear,
    this.onMicTap, // New Callback
  });

  final VoidCallback? onMicTap;

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
              style: const TextStyle(color: Colors.black87), // Force dark text on white bg
              onSubmitted: (_) => onSearch(), // Enable Enter key search
              textInputAction: TextInputAction.search,
            ),
          ),
          if (onMicTap != null)
            IconButton(
              icon: const Icon(Icons.mic, color: Colors.blueAccent),
              onPressed: onMicTap,
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
