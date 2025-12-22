import 'package:flutter/material.dart';

class Search extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final VoidCallback? onVoiceSearch;

  const Search({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClear,
    this.onVoiceSearch,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
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
              decoration: InputDecoration(
                hintText: "Search words",
                hintStyle: TextStyle(
                  color: Colors.black45,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              onChanged: (_) {},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearch,
            iconSize: isSmallScreen ? 20 : 24,
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClear,
              iconSize: isSmallScreen ? 20 : 24,
            ),
        ],
      ),
    );
  }
}

