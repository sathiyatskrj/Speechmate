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

class _StudentDashState extends State<StudentDash> with WidgetsBindingObserver {
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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDictionary();
  }

  // Monitor app lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Free memory when app goes to background or is paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      dictionaryService.unloadAll();
    }

    // Reload when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadDictionary();
    }
  }

  // Load only the words dictionary for this screen
  Future<void> _loadDictionary() async {
    setState(() {
      isLoading = true;
    });

    await dictionaryService.loadDictionary(DictionaryType.words);

    setState(() {
      isLoading = false;
    });
  }

  // Perform search asynchronously
  Future<void> performSearch() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    final searchResult = await dictionaryService.searchWord(searchController.text);

    setState(() {
      result = searchResult;
      isLoading = false;
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
        colors: [Color(0xFF94FFF8), Color(0xFF38BDF8)],
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
                  onWordSelected: (selectedWord) async {
                    FocusScope.of(context).unfocus();

                    setState(() {
                      searchController.text = selectedWord;
                      isLoading = true;
                    });

                    final searchResult = await dictionaryService.searchWord(selectedWord);

                    setState(() {
                      result = searchResult;
                      isLoading = false;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // Show loading indicator while searching
            if (isLoading)
              const CircularProgressIndicator()
            else if (searchController.text.isNotEmpty)
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

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Dispose controller
    searchController.dispose();

    // Free memory when leaving this screen
    dictionaryService.unload(DictionaryType.words);

    super.dispose();
  }
}