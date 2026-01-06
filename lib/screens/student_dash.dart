import 'package:flutter/material.dart';
import 'package:speechmate/services/dictionary_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/widgets/translation_card.dart';
import 'package:speechmate/widgets/gamification_header.dart';
import 'package:speechmate/widgets/smart_dashboard_header.dart'; // [NEW] Shared Component
import 'package:speechmate/widgets/voice_reactive_aurora.dart'; // [NEW] Wow Factor
import 'package:speechmate/core/app_theme.dart'; // [NEW] Theme


// Screen Imports
import 'package:speechmate/screens/number_page.dart';
import 'package:speechmate/screens/nature_page.dart';
import 'package:speechmate/screens/feelings_page.dart';
import 'package:speechmate/screens/mybody_part.dart'; // BodyPartsScreen
import 'package:speechmate/screens/games/games_hub_screen.dart';
import 'package:speechmate/screens/animals_page.dart';
import 'package:speechmate/screens/magic_words_page.dart';
import 'package:speechmate/screens/family_page.dart';
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/screens/student_progress_screen.dart';
import 'package:speechmate/screens/colors_page.dart';
import 'package:speechmate/screens/things_page.dart';
import 'package:speechmate/screens/culture_screen.dart'; // [NEW] Link
import 'package:speechmate/screens/voice_vault_screen.dart'; // [NEW] Link
import 'package:speechmate/screens/feedback_screen.dart'; // [NEW]
import 'package:speechmate/widgets/exit_feedback_dialog.dart'; // [NEW]
import 'package:speechmate/services/neural_engine_service.dart'; // [NEW]
import 'package:speechmate/screens/lessons/lesson_screen.dart'; // [NEW] Interactive Lessons
import 'package:speechmate/models/lesson_models.dart'; // [NEW] Lesson Models

class StudentDash extends StatefulWidget {
  const StudentDash({super.key});

  @override
  State<StudentDash> createState() => _StudentDashState();
}

class _StudentDashState extends State<StudentDash> with WidgetsBindingObserver {
  final TextEditingController searchController = TextEditingController();
  final DictionaryService dictionaryService = DictionaryService();
  final TtsService ttsService = TtsService();
  final NeuralEngineService _neuralEngine = NeuralEngineService(); // [NEW]
  // removed: AudioRecorder, WhisperLogic (handled by Header)

  Map<String, dynamic>? result;
  bool searchedNicobarese = false;
  bool isLoading = false;
 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Preload dictionaries
    dictionaryService.loadDictionary(DictionaryType.words);
    dictionaryService.loadDictionary(DictionaryType.phrases);
    ttsService.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    dictionaryService.unload(DictionaryType.words);
    super.dispose();
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      result = null;
      searchedNicobarese = false;
    });
  }



  Future<void> performSearch(String query) async {
    FocusScope.of(context).unfocus();
    if (query.isEmpty) return;

    setState(() => isLoading = true);

    // 1. Direct Search (Exact/Fuzzy from Dictionary)
    var searchResult = await dictionaryService.searchEverywhere(query);
    
    // 2. Neural Engine Fallback (Context-aware Translation)
    if (searchResult == null) {
        final neuralResult = await _neuralEngine.predict(query);
        
        // Only show if we have some confidence (not just returning original text entirely)
        if (neuralResult.text.isNotEmpty) {
             searchResult = {
                'english': query,
                'nicobarese': neuralResult.text,
                '_isGenerated': true,
                '_confidence': neuralResult.confidence
             };
        }
    }

    if (mounted) {
      setState(() {
        result = searchResult;
        
        if (searchResult != null) {
          if (searchResult!.containsKey('_searchedNicobarese')) {
              searchedNicobarese = searchResult!['_searchedNicobarese'];
          } else if (searchResult!.containsKey('_isGenerated')) {
             searchedNicobarese = false; // We assume input was English for Neural Engine
          } else {
              final q = query.trim().toLowerCase();
              searchedNicobarese =
                  searchResult!['nicobarese'].toString().toLowerCase() == q;
          }
        } else {
          searchedNicobarese = false;
        }
        isLoading = false;
      });
    }
  }
  // Removed: _getModelPath, _startRecording, _stopRecording, _onMicTap (Moving to Header)


  final List<Map<String, dynamic>> learningTiles = [
    // [NEW] Interactive Lessons (Child-Friendly)
    {"word": "Jungle Adventure", "emoji": "🦁", "colors": [Color(0xFFFF9966), Color(0xFFFF5E62)], "navigateTo": LessonScreen(lesson: interactiveLessons[0]), "icon": Icons.terrain_rounded},
    {"word": "Island Colors", "emoji": "🏝️", "colors": [Color(0xFF00B4DB), Color(0xFF0083B0)], "navigateTo": LessonScreen(lesson: interactiveLessons[1]), "icon": Icons.beach_access_rounded},

    {"word": "Numbers", "emoji": "123", "colors": [Color(0xFF6A11CB), Color(0xFF2575FC)], "navigateTo": NumberPage(), "icon": Icons.format_list_numbered_rounded},
    {"word": "Nature", "emoji": "🌱", "colors": [Color(0xFF11998E), Color(0xFF38EF7D)], "navigateTo": NaturePage(), "icon": Icons.eco_rounded},
    {"word": "Feelings", "emoji": "🎭", "colors": [Color(0xFFFF512F), Color(0xFFDD2476)], "navigateTo": FeelingsPage(), "icon": Icons.emoji_emotions_rounded},
    {"word": "Colors", "emoji": "🎨", "colors": [Color(0xFFff9a9e), Color(0xFFfad0c4)], "navigateTo": const ColorsPage(), "icon": Icons.palette_rounded},
    {"word": "Things", "emoji": "🏡", "colors": [Color(0xFFa18cd1), Color(0xFFfbc2eb)], "navigateTo": const ThingsPage(), "icon": Icons.chair_rounded},
    {"word": "Body Parts", "emoji": "🦴", "colors": [Color(0xFF8E2DE2), Color(0xFF4A00E0)], "navigateTo": BodyPartsScreen(), "icon": Icons.accessibility_new_rounded},
    {"word": "Games", "emoji": "🎲", "colors": [Color(0xFFF09819), Color(0xFFEDDE5D)], "navigateTo": const GamesHubScreen(), "icon": Icons.sports_esports_rounded},
    {"word": "Animals", "emoji": "🐶", "colors": [Color(0xFFFF8008), Color(0xFFFFC837)], "navigateTo": const AnimalsPage(), "icon": Icons.pets_rounded},
    {"word": "Magic Words", "emoji": "🔮", "colors": [Color(0xFFCC2B5E), Color(0xFF753A88)], "navigateTo": const MagicWordsPage(), "icon": Icons.auto_fix_high_rounded},
    {"word": "Family", "emoji": "👨‍👩‍👧", "colors": [Color(0xFF2193B0), Color(0xFF6DD5ED)], "navigateTo": const FamilyPage(), "icon": Icons.family_restroom_rounded},
 
    {"word": "Voice Vault", "emoji": "🎙️", "colors": [Color(0xFF4CA1AF), Color(0xFF2C3E50)], "navigateTo": const VoiceVaultScreen(), "icon": Icons.mic_external_on_rounded},
    {"word": "Beta Chat", "emoji": "💬", "colors": [Color(0xFFFF9A9E), Color(0xFFFECFEF)], "navigateTo": const BetaChatScreen(isStudent: true), "icon": Icons.chat_bubble_rounded},
    {"word": "Community", "emoji": "🌍", "colors": [Color(0xFF302B63), Color(0xFF24243E)], "navigateTo": const CommunityScreen(), "isSecret": true, "icon": Icons.public_rounded},
    
    // [NEW] Feedback Tile
    {"word": "Feedback", "emoji": "⭐", "colors": [Color(0xFFFF00CC), Color(0xFF333399)], "navigateTo": const FeedbackScreen(), "icon": Icons.feedback_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.studentTheme,
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
           if (didPop) return;
           final shouldExit = await showDialog(
             context: context,
             builder: (context) => const ExitFeedbackDialog()
           );
           // Dialog handles exit, but if they click outside, we do nothing (stay).
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          body: VoiceReactiveAurora(
          isDark: false, // Student Mode (Bright)
          child: SafeArea(
            child: Column(
              children: [
                 SmartDashboardHeader(
                   isTeacher: false,
                   searchController: searchController,
                   onSearch: performSearch,
                   onClear: clearSearch,
                 ),
                 const SizedBox(height: 10),
                 Expanded(
                   child: SingleChildScrollView(
                     physics: const BouncingScrollPhysics(),
                     child: Column(
                       children: [
                           if (isLoading)
                             const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
                           else if (searchController.text.isNotEmpty)
                             _buildSearchResults(),
                           
                           _buildDashboardContent(),
                       ],
                     ),
                   ),
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // _buildHeroHeader removed


  Widget _buildSearchResults() {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: TranslationCard(
          nicobarese: result != null ? (result!['nicobarese'] ?? "Translation not available") : "No match found",
          english: result != null ? (result!['english'] ?? result!['text'] ?? "No translation") : "",
          isError: result == null,
          searchedNicobarese: searchedNicobarese,
          showSpeaker: result != null, 
          onSpeak: () {
              if (result == null) return;
              final textToSpeak = searchedNicobarese 
                  ? (result!['english'] ?? result!['text'] ?? "")
                  : (result!['nicobarese'] ?? "");
              if (textToSpeak.isEmpty) return;
              if (searchedNicobarese) {
                  ttsService.speakEnglish(textToSpeak);
              } else {
                  ttsService.speakNicobarese(
                    textToSpeak, 
                    englishWord: result!['english'] ?? result!['text']
                  );
              }
          },
        ),
      );
  }

  Widget _buildDashboardContent() {
      return Padding(
         padding: const EdgeInsets.all(20),
         child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                 const Text("YOUR PROGRESS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                 const SizedBox(height: 10),
                 const GamificationHeader(),
                 const SizedBox(height: 30),
                 const Text("EXPLORE MODULES", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                 const SizedBox(height: 15),
                 GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: learningTiles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                        return _buildPremiumTile(learningTiles[index]);
                    },
                 ),
                 const SizedBox(height: 100),
             ],
         ),
      );
  }

  Widget _buildPremiumTile(Map<String, dynamic> tile) {
      return GestureDetector(
          onTap: () {
              if (tile['isSecret'] == true) {
                  _showSecretAccessDialog(context, tile['navigateTo']);
              } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => tile['navigateTo']));
              }
          },
          child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tile['colors'], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                      BoxShadow(color: (tile['colors'][0] as Color).withOpacity(0.4), blurRadius: 10, offset: const Offset(0,4))
                  ]
              ),
              child: Stack(
                  children: [
                      Positioned(right: -10, bottom: -10, child: Icon(tile['icon'], size: 80, color: Colors.white.withOpacity(0.2))),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                      child: Icon(tile['icon'], color: Colors.white, size: 20),
                                  ),
                                  Text(tile['word'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                          ),
                      )
                  ],
              ),
          ),
      );
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
              if (_controller.text.trim() == "27") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
              } else {
                Navigator.pop(context);
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
