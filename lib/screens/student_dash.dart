import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/widgets/translation_card.dart';
import 'package:speechmate/widgets/gamification_header.dart';
import 'package:speechmate/widgets/smart_dashboard_header.dart';
import 'package:speechmate/widgets/voice_reactive_aurora.dart';
import 'package:speechmate/core/app_theme.dart';
import 'package:speechmate/mixins/searchable_dashboard_mixin.dart';

import 'package:speechmate/screens/games/games_hub_screen.dart';
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/screens/voice_vault_screen.dart';
import 'package:speechmate/screens/dynamic_category_screen.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/screens/feedback_screen.dart';
import 'package:speechmate/screens/lessons/lesson_screen.dart';
import 'package:speechmate/models/lesson_models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/screens/beta_chat_screen.dart';
import 'package:speechmate/screens/srs_review_screen.dart';
import 'package:speechmate/screens/great_andamanese_screen.dart';
import 'package:speechmate/screens/flora_fauna_screen.dart';
import 'package:speechmate/screens/story_radio_screen.dart';
import 'package:speechmate/screens/kinship_mapper_screen.dart';
import 'package:speechmate/screens/dialect_heatmap_screen.dart';
import 'package:speechmate/screens/memory_palace_screen.dart';
import 'package:speechmate/screens/camera_translation_screen.dart';
import 'package:speechmate/screens/voice_translator_screen.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:speechmate/core/app_colors.dart';

class StudentDash extends StatefulWidget {
  const StudentDash({super.key});

  @override
  State<StudentDash> createState() => _StudentDashState();
}

class _StudentDashState extends State<StudentDash>
    with WidgetsBindingObserver, SearchableDashboardMixin {
  final TextEditingController searchController = TextEditingController();
  final TtsService ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ttsService.init();
    initSearch();
    _seedDynamicData();
  }

  Future<void> _seedDynamicData() async {
     await DatabaseManager.instance.seedCategoryFromJson('animals', 'assets/data/dictionary_animals.json');
     await DatabaseManager.instance.seedCategoryFromJson('family', 'assets/data/dictionary_family.json');
     await DatabaseManager.instance.seedCategoryFromJson('magic', 'assets/data/dictionary_magic.json');
     await DatabaseManager.instance.seedCategoryFromList('numbers', [
       {"name": "One", "nicobarese": "Heng", "emoji": "1️⃣"},
       {"name": "Two", "nicobarese": "Nēk", "emoji": "2️⃣"},
       {"name": "Three", "nicobarese": "Lūy", "emoji": "3️⃣"},
       {"name": "Four", "nicobarese": "Fōan", "emoji": "4️⃣"},
       {"name": "Five", "nicobarese": "Tanēy", "emoji": "5️⃣"},
     ]);
     await DatabaseManager.instance.seedCategoryFromList('nature', [
       {"name": "Sun", "nicobarese": "Tahaēng", "emoji": "☀️"},
       {"name": "Moon", "nicobarese": "Kahaēng", "emoji": "🌙"},
       {"name": "Star", "nicobarese": "Tökaēng", "emoji": "⭐"},
       {"name": "Rain", "nicobarese": "Kūm-yū", "emoji": "🌧️"},
       {"name": "Wind", "nicobarese": "Tahaē", "emoji": "🌬️"},
     ]);
     
     await DatabaseManager.instance.seedCategoryFromList('colors', [
       {"name": "Blue", "nicobarese": "tö lingū", "emoji": "🌊"},
       {"name": "Green", "nicobarese": "tö rōy chōn", "emoji": "🥥"},
       {"name": "Orange", "nicobarese": "Föl", "emoji": "🌅"},
       {"name": "Red", "nicobarese": "Chöī", "emoji": "🔴"},
       {"name": "Yellow", "nicobarese": "Rōy", "emoji": "🌻"},
       {"name": "White", "nicobarese": "Fūn", "emoji": "⬜"},
       {"name": "Black", "nicobarese": "Talen", "emoji": "⬛"},
       {"name": "Brown", "nicobarese": "Ūm Talen", "emoji": "🤎"},
       {"name": "Pink", "nicobarese": "Chöī Fūn", "emoji": "🩷"},
       {"name": "Purple", "nicobarese": "Tö lingū chöī", "emoji": "🟣"},
     ]);
     
     await DatabaseManager.instance.seedCategoryFromList('feelings', [
       {"name": "Happy", "nicobarese": "Vah", "emoji": "😁"},
       {"name": "Sad", "nicobarese": "Nö-öt", "emoji": "😢"},
       {"name": "Angry", "nicobarese": "Kaūn", "emoji": "😡"},
       {"name": "Scared", "nicobarese": "Takat", "emoji": "😨"},
       {"name": "Tired", "nicobarese": "Löhöt", "emoji": "😴"},
       {"name": "Hungry", "nicobarese": "Ön-yā", "emoji": "🤤"},
       {"name": "Thirsty", "nicobarese": "Ön-nūm", "emoji": "💧"},
       {"name": "Love", "nicobarese": "Maūn", "emoji": "❤️"},
       {"name": "Surprise", "nicobarese": "Takūn", "emoji": "😲"},
       {"name": "Shy", "nicobarese": "Mā-öt", "emoji": "🫣"},
     ]);
     
     await DatabaseManager.instance.seedCategoryFromList('things', [
       {"name": "House", "nicobarese": "Pati", "emoji": "🏠"},
       {"name": "Boat", "nicobarese": "Hōdi", "emoji": "🚣"},
       {"name": "Water", "nicobarese": "Dāk", "emoji": "💧"},
       {"name": "Fire", "nicobarese": "Yūh", "emoji": "🔥"},
       {"name": "Stone", "nicobarese": "Lūng", "emoji": "🪨"},
       {"name": "Tree", "nicobarese": "Dāng", "emoji": "🌳"},
       {"name": "Coconut", "nicobarese": "Tafūl", "emoji": "🥥"},
       {"name": "Fish", "nicobarese": "Hīchā", "emoji": "🐟"},
       {"name": "Clothes", "nicobarese": "Nāra", "emoji": "👕"},
       {"name": "Food", "nicobarese": "Kānā", "emoji": "🍚"},
     ]);
     
     await DatabaseManager.instance.seedCategoryFromList('body_parts', [
       {"name": "Eye", "nicobarese": "Mötö", "emoji": "👁️"},
       {"name": "Ear", "nicobarese": "Tananga", "emoji": "👂"},
       {"name": "Nose", "nicobarese": "Nöngūm", "emoji": "👃"},
       {"name": "Mouth", "nicobarese": "Chūm", "emoji": "👄"},
       {"name": "Hand", "nicobarese": "Kā-öt", "emoji": "✋"},
       {"name": "Foot", "nicobarese": "Hinyūh", "emoji": "🦶"},
       {"name": "Head", "nicobarese": "Chöm", "emoji": "🗣️"},
       {"name": "Teeth", "nicobarese": "Tī", "emoji": "🦷"},
       {"name": "Hair", "nicobarese": "Yök", "emoji": "💇"},
       {"name": "Heart", "nicobarese": "Yā", "emoji": "❤️"},
       {"name": "Stomach", "nicobarese": "Pāk", "emoji": "🫃"},
       {"name": "Back", "nicobarese": "Tö-kūng", "emoji": "🔙"},
     ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    disposeMixinSearch();
    super.dispose();
  }

  void _onSearch(String query) {
    FocusScope.of(context).unfocus();
    performMixinSearch(query);
  }

  void _onClear() => clearMixinSearch(searchController);

  List<Map<String, dynamic>> get learningTiles => [
    {"word": AppStrings.get('dailyReview'), "emoji": "🧠", "colors": [Color(0xFF00C9FF), Color(0xFF92FE9D)], "navigateTo": const SrsReviewScreen(), "icon": Icons.psychology_rounded},
    {"word": AppStrings.get('jungleAdventure'), "emoji": "🦁", "colors": [Color(0xFFFF9966), Color(0xFFFF5E62)], "navigateTo": LessonScreen(lesson: interactiveLessons[0]), "icon": Icons.terrain_rounded},
    {"word": AppStrings.get('islandColors'), "emoji": "🏝️", "colors": [Color(0xFF00B4DB), Color(0xFF0083B0)], "navigateTo": LessonScreen(lesson: interactiveLessons[1]), "icon": Icons.beach_access_rounded},
    {"word": AppStrings.get('numbers'), "emoji": "123", "colors": [Color(0xFF6A11CB), Color(0xFF2575FC)], "navigateTo": const DynamicCategoryScreen(categoryId: 'numbers', title: 'Numbers'), "icon": Icons.format_list_numbered_rounded},
    {"word": AppStrings.get('nature'), "emoji": "🌱", "colors": [Color(0xFF11998E), Color(0xFF38EF7D)], "navigateTo": const DynamicCategoryScreen(categoryId: 'nature', title: 'Nature'), "icon": Icons.eco_rounded},
    {"word": AppStrings.get('feelings'), "emoji": "🎭", "colors": [Color(0xFFFF512F), Color(0xFFDD2476)], "navigateTo": const DynamicCategoryScreen(categoryId: 'feelings', title: 'Feelings'), "icon": Icons.emoji_emotions_rounded},
    {"word": AppStrings.get('colors'), "emoji": "🎨", "colors": [Color(0xFFff9a9e), Color(0xFFfad0c4)], "navigateTo": const DynamicCategoryScreen(categoryId: 'colors', title: 'Colors'), "icon": Icons.palette_rounded},
    {"word": AppStrings.get('things'), "emoji": "🏡", "colors": [Color(0xFFa18cd1), Color(0xFFfbc2eb)], "navigateTo": const DynamicCategoryScreen(categoryId: 'things', title: 'Things'), "icon": Icons.chair_rounded},
    {"word": AppStrings.get('bodyParts'), "emoji": "🦴", "colors": [Color(0xFF8E2DE2), Color(0xFF4A00E0)], "navigateTo": const DynamicCategoryScreen(categoryId: 'body_parts', title: 'Body Parts'), "icon": Icons.accessibility_new_rounded},
    {"word": AppStrings.get('games'), "emoji": "🎲", "colors": [Color(0xFFF09819), Color(0xFFEDDE5D)], "navigateTo": const GamesHubScreen(), "icon": Icons.sports_esports_rounded},
    {"word": AppStrings.get('animals'), "emoji": "🐶", "colors": [Color(0xFFFF8008), Color(0xFFFFC837)], "navigateTo": const DynamicCategoryScreen(categoryId: 'animals', title: 'Animals'), "icon": Icons.pets_rounded},
    {"word": AppStrings.get('magicWords'), "emoji": "🔮", "colors": [Color(0xFFCC2B5E), Color(0xFF753A88)], "navigateTo": const DynamicCategoryScreen(categoryId: 'magic', title: 'Magic Words'), "icon": Icons.auto_fix_high_rounded},
    {"word": AppStrings.get('family'), "emoji": "👨‍👩‍👧", "colors": [Color(0xFF2193B0), Color(0xFF6DD5ED)], "navigateTo": const DynamicCategoryScreen(categoryId: 'family', title: 'Family'), "icon": Icons.family_restroom_rounded},
    {"word": AppStrings.get('voiceVault'), "emoji": "🎙️", "colors": [Color(0xFF4CA1AF), Color(0xFF2C3E50)], "navigateTo": const VoiceVaultScreen(), "icon": Icons.mic_external_on_rounded},
    {"word": AppStrings.get('chatTranslate'), "emoji": "💬", "colors": [Color(0xFFFF9A9E), Color(0xFFFECFEF)], "navigateTo": const BetaChatScreen(isStudent: true), "icon": Icons.chat_bubble_rounded},
    {"word": AppStrings.get('community'), "emoji": "🌍", "colors": [Color(0xFF302B63), Color(0xFF24243E)], "navigateTo": const CommunityScreen(), "isSecret": true, "icon": Icons.public_rounded},
    {"word": AppStrings.get('feedback'), "emoji": "⭐", "colors": [Color(0xFFFF00CC), Color(0xFF333399)], "navigateTo": const FeedbackScreen(), "icon": Icons.feedback_rounded},
    {"word": "Great Andamanese", "emoji": "🏝️", "colors": [Color(0xFF4A148C), Color(0xFF1A237E)], "navigateTo": const GreatAndamaneseScreen(), "icon": Icons.language_rounded},
    {"word": "Nature Hub", "emoji": "🌿", "colors": [Color(0xFF1B5E20), Color(0xFF004D40)], "navigateTo": const FloraFaunaScreen(), "icon": Icons.eco_rounded},
    {"word": "Oral History", "emoji": "📻", "colors": [Color(0xFF3E2723), Color(0xFF1B5E20)], "navigateTo": const StoryRadioScreen(), "icon": Icons.radio_rounded},
    {"word": "Tuhet (Kinship)", "emoji": "🌳", "colors": [Color(0xFF5D4037), Color(0xFF3E2723)], "navigateTo": const KinshipMapperScreen(), "icon": Icons.account_tree_rounded},
    {"word": "Island Explorer", "emoji": "🧭", "colors": [Color(0xFF0277BD), Color(0xFF01579B)], "navigateTo": const DialectHeatmapScreen(), "icon": Icons.explore_rounded},
    {"word": "Memory Palace", "emoji": "🏠", "colors": [Color(0xFF2E7D32), Color(0xFF1B5E20)], "navigateTo": const MemoryPalaceScreen(), "icon": Icons.map_rounded},
    {"word": "Book Scanner", "emoji": "📖", "colors": [Color(0xFF00B4DB), Color(0xFF0083B0)], "navigateTo": const CameraTranslationScreen(), "icon": Icons.document_scanner_rounded},
    {"word": "Voice Translate", "emoji": "🎙️", "colors": [Color(0xFFff0844), Color(0xFFffb199)], "navigateTo": const VoiceTranslatorScreen(), "icon": Icons.record_voice_over_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.studentTheme,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: VoiceReactiveAurora(
          isDark: false,
          child: SafeArea(
            child: Column(
              children: [
                SmartDashboardHeader(
                  isTeacher: false,
                  searchController: searchController,
                  onSearch: _onSearch,
                  onClear: _onClear,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        if (isSearchLoading)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(color: Colors.cyanAccent),
                            ),
                          )
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

  Widget _buildSearchResults() {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: TranslationCard(
          nicobarese: searchResult != null ? (searchResult!['nicobarese'] ?? "Translation not available") : "No match found",
          english: searchResult != null ? (searchResult!['english'] ?? searchResult!['text'] ?? "No translation") : "",
          isError: searchResult == null,
          searchedNicobarese: searchedNicobarese,
          showSpeaker: searchResult != null, 
          onSpeak: () {
              if (searchResult == null) return;
              final textToSpeak = searchedNicobarese 
                  ? (searchResult!['english'] ?? searchResult!['text'] ?? "")
                  : (searchResult!['nicobarese'] ?? "");
              if (textToSpeak.isEmpty) return;
              if (searchedNicobarese) {
                  ttsService.speakEnglish(textToSpeak);
              } else {
                  ttsService.speakNicobarese(
                    textToSpeak, 
                    englishWord: searchResult!['english'] ?? searchResult!['text']
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
                 Text(AppStrings.get('yourProgress').toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                 const SizedBox(height: 10),
                 const GamificationHeader(),
                 const SizedBox(height: 30),
                 Text(AppStrings.get('exploreModules') != 'exploreModules' ? AppStrings.get('exploreModules').toUpperCase() : "EXPLORE MODULES", style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                 const SizedBox(height: 15),
                 GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: learningTiles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 140,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.studentAccent,
                      AppColors.studentAccent.withOpacity(0.8),
                      Colors.black,
                    ],
                  ),
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
    final answerController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🔒", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text("Senior Student Access",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Solve this to enter:\n12 + 15 = ?",
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextField(
                  controller: answerController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "?",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: Colors.white54),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (answerController.text.trim() == "27") {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
                          } else {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Incorrect. Access Denied 🚫")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text("Enter", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
