import 'package:flutter/material.dart';
import 'package:speechmate/screens/feelings_page.dart';
import 'package:speechmate/screens/mybody_part.dart';
import 'package:speechmate/screens/nature_page.dart';
import '../widgets/background.dart';
import '../widgets/learning_tiles.dart';
import '../widgets/search_bar.dart';
import '../widgets/translation_card.dart';
import '../services/dictionary_service.dart';
import 'number_page.dart';

class StudentDash extends StatefulWidget {
  const StudentDash({super.key});

  @override
  State<StudentDash> createState() => _StudentDashState();
}

class _StudentDashState extends State<StudentDash> with WidgetsBindingObserver {
  final TextEditingController searchController = TextEditingController();
  final DictionaryService dictionaryService = DictionaryService();

  final List<Map<String, dynamic>> learningTiles = [
    {
      "word": "Numbers",
      "colors": [Color(0xFFFF7E79), Color(0xFFFFB677)],
      "navigateTo": NumberPage(),
    },
    {
      "word": "Nature",
      "colors": [Color(0xFF5ED87D), Color(0xFF92FF70)],
      "navigateTo": NaturePage(),
    },
    {
      "word": "Feelings",
      "colors": [Color(0xFF66CCFF), Color(0xFF0099FF)],
      "navigateTo": FeelingsPage(),
    },
    {
      "word": "Body Parts",
      "colors": [Color(0xFFB084FF), Color(0xFF7AA6FF)],
      "navigateTo": BodyPartsScreen(),
    },
  ];

  Map<String, dynamic>? result;
  bool isLoading = false;
  bool searchedNicobarese = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDictionary();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      dictionaryService.unloadAll();
    }

    if (state == AppLifecycleState.resumed) {
      _loadDictionary();
    }
  }

  Future<void> _loadDictionary() async {
    setState(() {
      isLoading = true;
    });

    await dictionaryService.loadDictionary(DictionaryType.words);

    setState(() {
      isLoading = false;
    });
  }

  /// Perform search
  Future<void> performSearch() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    final searchResult = await dictionaryService.searchWord(
      searchController.text,
    );

    setState(() {
      result = searchResult;

      if (searchResult != null) {
        final query = searchController.text.trim().toLowerCase();
        searchedNicobarese =
            searchResult['nicobarese'].toString().toLowerCase() == query;
      } else {
        searchedNicobarese = false;
      }

      isLoading = false;
    });
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      result = null;
      searchedNicobarese = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: const [Color(0xFF94FFF8), Color(0xFF38BDF8)],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              searchedNicobarese
                  ? "Nicobarese → English"
                  : "English → Nicobarese",
              style: const TextStyle(
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

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children:
                  learningTiles.map((item) {
                    return LearningTiles(
                      word: item["word"],
                      gradient: List<Color>.from(item["colors"]),
                      navigateTo: item["navigateTo"],
                    );
                  }).toList(),
            ),

            const SizedBox(height: 30),

            if (isLoading)
              const CircularProgressIndicator()
            else if (searchController.text.isNotEmpty)
              TranslationCard(
                nicobarese:
                    result != null ? result!['nicobarese'] : "Word not found",
                english: result != null ? result!['english'] : "",
                isError: result == null,
                searchedNicobarese: searchedNicobarese,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    dictionaryService.unload(DictionaryType.words);
    super.dispose();
  }
}
