import 'package:flutter/material.dart';
import '../widgets/background.dart';
import '../widgets/common_word_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/translation_card.dart';
import '../services/dictionary_service.dart';

class StudentDash extends StatefulWidget {
  const StudentDash({super.key});

  @override
  State<StudentDash> createState() => _StudentDashState();
}

class _StudentDashState extends State<StudentDash> {
  final TextEditingController searchController = TextEditingController();
  final DictionaryService dictionaryService = DictionaryService();
  final List<Map<String, dynamic>> commonWords = [
    {
      "word": "Tree",
      "emoji": "🌳",
      "colors": [Color(0xFFFF7E79), Color(0xFFFFB677)],
    },
    {
      "word": "Water",
      "emoji": "💧",
      "colors": [Color(0xFFFFA834), Color(0xFFFFD56F)],
    },
    {
      "word": "Sea",
      "emoji": "🌊",
      "colors": [Color(0xFF66CCFF), Color(0xFF0099FF)],
    },
    {
      "word": "Island",
      "emoji": "🏝️",
      "colors": [Color(0xFFB084FF), Color(0xFF7AA6FF)],
    },
    {
      "word": "Cold",
      "emoji": "❄️",
      "colors": [Color(0xFFFFA9A3), Color(0xFFFFD6A5)],
    },
    {
      "word": "Sun",
      "emoji": "☀️",
      "colors": [Color(0xFF5ED87D), Color(0xFF92FF70)],
    },
  ];


  Map<String, dynamic>? result;

  @override
  void initState() {
    super.initState();
    dictionaryService.load();
  }

  void performSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      result = dictionaryService.search(searchController.text);
    });
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: [Color(0xFF94FFF8),Color(0xFF38BDF8)],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "English → Nicobarese",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 30),

            Search(
              controller: searchController,
              onSearch: performSearch,
              onClear: clearSearch,
            ),

            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Some common words",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 15),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: commonWords.map((w) {
                return CommonWordCard(
                  word: w["word"],
                  emoji: w["emoji"],
                  gradient: List<Color>.from(w["colors"]),
                  onWordSelected: (selectedWord) {
                    FocusScope.of(context).unfocus(); // hide keyboard
                    setState(() {
                      searchController.text = selectedWord;
                      result = dictionaryService.search(selectedWord);
                    });
                  },
                );
              }).toList(),
            ),


            const SizedBox(height: 30),

            if (searchController.text.isNotEmpty)
              TranslationCard(
                nicobarese: result != null ? result!['nicobarese'] : "Word not found",
                english: result != null ? result!['english'] : "",
                isError: result == null,
              ),
          ],
        ),
      ),
    );
  }
}