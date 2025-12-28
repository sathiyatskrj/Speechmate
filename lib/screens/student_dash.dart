import 'package:flutter/material.dart';
import 'package:speechmate/screens/feelings_page.dart';
import 'package:speechmate/screens/mybody_part.dart';
import 'package:speechmate/screens/nature_page.dart';
import 'package:speechmate/features/gamification/gamification_service.dart';
import 'package:speechmate/features/preservation/voice_archive.dart';
import 'number_page.dart';
// Updated Imports
import 'games/games_hub_screen.dart';
import 'animals_page.dart';
import 'magic_words_page.dart';
import 'community_screen.dart';
import 'family_page.dart';
import '../services/tts_service.dart';

import '../widgets/background.dart';
import '../widgets/learning_tiles.dart';
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
  final TtsService ttsService = TtsService();

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
    {
      "word": "Games",
      "colors": [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Purple for Games
      "navigateTo": const GamesHubScreen(),
    },
    // New Sections
    {
      "word": "Animals",
      "colors": [Color(0xFF11998e), Color(0xFF38ef7d)], // Green Gradient for Animals
      "navigateTo": const AnimalsPage(),
    },
    {
      "word": "Magic Words",
      "colors": [Color(0xFFfc00ff), Color(0xFF00dbde)], // Pink/Cyan for Magic
      "navigateTo": const MagicWordsPage(),
    },
    {
      "word": "Family",
      "colors": [Color(0xFFff9a9e), Color(0xFFfecfef)], // Pink/Peach for Family
      "navigateTo": const FamilyPage(),
    },
    {
      "word": "Community",
      "colors": [Color(0xFF4FACFE), Color(0xFF00F2FE)], // Blue/Cyan for Community
      "navigateTo": const CommunityScreen(),
      "isSecret": true,
    },
  ];

  Map<String, dynamic>? result;
  bool isLoading = false;
  bool searchedNicobarese = false;
  
  // Hidden Feature Counter
  int _secretTapCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ttsService.init(); // Initialize TTS
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

  Future<void> performSearch() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    final searchResult = await dictionaryService.searchEverywhere(
      searchController.text,
    );

    setState(() {
      result = searchResult;

      if (searchResult != null) {
        // Safe check for search direction
        if (searchResult.containsKey('_searchedNicobarese')) {
            searchedNicobarese = searchResult['_searchedNicobarese'];
        } else {
            final query = searchController.text.trim().toLowerCase();
            searchedNicobarese =
                searchResult['nicobarese'].toString().toLowerCase() == query;
        }
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
        // Enhanced visuals with a gradient
        colors: const [Color(0xFFE0C3FC), Color(0xFF8EC5FC)], 
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hidden Feature: Tap Title 5 times
            GestureDetector(
                onTap: () {
                    setState(() {
                        _secretTapCount++;
                        if (_secretTapCount >= 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("🎉 Secret Party Mode Activated! 🎉"),
                                    backgroundColor: Colors.purpleAccent,
                                )
                            );
                            _secretTapCount = 0;
                            // You can add more fun effects here later!
                        }
                    });
                },
                child: Text(
                  searchedNicobarese
                      ? "Nicobarese → English"
                      : "English → Nicobarese",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black26, offset: Offset(1,1), blurRadius: 2)]
                  ),
                ),
            ),
            const SizedBox(height: 30),
            Search(
              controller: searchController,
              onSearch: performSearch,
              onClear: clearSearch,
            ),
            const SizedBox(height: 30),
            if (isLoading)
              const CircularProgressIndicator()
            else if (searchController.text.isNotEmpty)
              TranslationCard(
                nicobarese:
                    result != null ? result!['nicobarese'] : "Word not found",
                english: result != null ? (result!['english'] ?? result!['text'] ?? "") : "",
                isError: result == null,
                searchedNicobarese: searchedNicobarese,
                showSpeaker: result != null, // Show speaker if found
                onSpeakerTap: () {
                    if (result == null) return;
                    // Fix TTS
                    if (searchedNicobarese) {
                        ttsService.speakEnglish(result!['english'] ?? result!['text'] ?? "");
                    } else {
                        ttsService.speakNicobarese(result!['nicobarese']);
                    }
                },
              )
            else
           Column(
          children: [
            // GAMIFICATION HEADER
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.purple.shade800]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.amber,
                    child: Text("${GamificationService.currentLevel}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(GamificationService.getLevelTitle(GamificationService.currentLevel), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: GamificationService.xp / GamificationService.nextLevelXp,
                          backgroundColor: Colors.white24,
                          color: Colors.greenAccent,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 5),
                        Text("${GamificationService.xp} / ${GamificationService.nextLevelXp} XP", style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                      Text("${GamificationService.currentStreak} Day", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            
            // GRID TILES
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: learningTiles.length + 1, // +1 for Voice Archive
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  // Voice Archive Tile (Special Highlighting)
                  if (index == learningTiles.length) { 
                     return GestureDetector(
                       onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceArchiveScreen())),
                       child: Container(
                         decoration: BoxDecoration(
                           gradient: const LinearGradient(colors: [Color(0xFF1E1E2C), Color(0xFF232526)]),
                           borderRadius: BorderRadius.circular(24),
                           border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1),
                           boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
                         ),
                         child: const Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(Icons.record_voice_over, size: 40, color: Colors.cyanAccent),
                             SizedBox(height: 10),
                             Text("Voice Archive", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                             Text("Be Infinite", style: TextStyle(color: Colors.white54, fontSize: 10)),
                           ],
                         ),
                       ),
                     );
                  }

                  final tile = learningTiles[index];
                        return LearningTiles(
                          word: tile["word"],
                          gradient: List<Color>.from(tile["colors"]),
                          navigateTo: tile["navigateTo"],
                          onTap: tile.containsKey('isSecret') && tile['isSecret'] == true
                              ? () => _showSecretAccessDialog(context, tile['navigateTo'])
                              : null,
                        );
                      }).toList(),
                 ),
               ),
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

  void _showSecretAccessDialog(BuildContext context, Widget targetScreen) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Senior Student Access 🔒"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Solve this to enter:\n\n12 + 15 = ?"),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Enter answer"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_controller.text == "27") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Incorrect. Access Denied 🚫")),
                );
              }
            },
            child: const Text("Enter"),
          ),
        ],
      ),
    );
  }
}
