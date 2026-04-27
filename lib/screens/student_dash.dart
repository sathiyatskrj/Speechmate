import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/widgets/translation_card.dart';
import 'package:speechmate/widgets/gamification_header.dart';
import 'package:speechmate/widgets/smart_dashboard_header.dart';
import 'package:speechmate/core/app_theme.dart';
import 'package:speechmate/mixins/searchable_dashboard_mixin.dart';
import 'package:speechmate/widgets/tap_scale.dart'; 
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Screens
import 'package:speechmate/screens/games/games_hub_screen.dart';
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/screens/voice_vault_screen.dart';
import 'package:speechmate/screens/dynamic_category_screen.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/screens/feedback_screen.dart';
import 'package:speechmate/screens/beta_chat_screen.dart';
import 'package:speechmate/screens/ga_hub_screen.dart';
import 'package:speechmate/screens/flora_fauna_screen.dart';
import 'package:speechmate/screens/story_radio_screen.dart';
import 'package:speechmate/screens/kinship_mapper_screen.dart';
import 'package:speechmate/screens/dialect_heatmap_screen.dart';
import 'package:speechmate/screens/memory_palace_screen.dart';
import 'package:speechmate/screens/camera_translation_screen.dart';
import 'package:speechmate/screens/voice_translator_screen.dart';
import 'package:speechmate/screens/ar_translator_screen.dart';
import 'package:speechmate/screens/body_parts_screen.dart';
import 'package:speechmate/screens/ai_setup_screen.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:speechmate/core/app_colors.dart';
import 'package:speechmate/screens/regional_translator_screen.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

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
    // --- Premium Interactive Features (Moved to Top) ---
    {"word": AppStrings.get('arTranslator'), "emoji": "📷", "colors": [Color(0xFF0F2027), Color(0xFF2C5364)], "navigateTo": const ARTranslatorScreen(), "icon": Icons.view_in_ar_rounded},
    {"word": AppStrings.get('voiceVault'), "emoji": "🎙️", "colors": [Color(0xFF4CA1AF), Color(0xFF2C3E50)], "navigateTo": const VoiceVaultScreen(), "icon": Icons.mic_external_on_rounded},
    {"word": AppStrings.get('bookScanner'), "emoji": "📖", "colors": [Color(0xFF00B4DB), Color(0xFF0083B0)], "navigateTo": const CameraTranslationScreen(), "icon": Icons.document_scanner_rounded},
    {"word": AppStrings.get('games'), "emoji": "🎲", "colors": [Color(0xFFF09819), Color(0xFFEDDE5D)], "navigateTo": const GamesHubScreen(), "icon": Icons.sports_esports_rounded},
    {"word": AppStrings.get('chatTranslate'), "emoji": "💬", "colors": [Color(0xFFFF9A9E), Color(0xFFFECFEF)], "navigateTo": const BetaChatScreen(isStudent: true), "icon": Icons.chat_bubble_rounded},
    {"word": AppStrings.get('voiceTranslate'), "emoji": "🎙️", "colors": [Color(0xFFff0844), Color(0xFFffb199)], "navigateTo": const VoiceTranslatorScreen(), "icon": Icons.record_voice_over_rounded},
    
    // --- Core Learning Categories ---
    {"word": AppStrings.get('numbers'), "emoji": "123", "colors": [Color(0xFF6A11CB), Color(0xFF2575FC)], "navigateTo": const DynamicCategoryScreen(categoryId: 'numbers', title: 'Numbers'), "icon": Icons.format_list_numbered_rounded},
    {"word": AppStrings.get('nature'), "emoji": "🌱", "colors": [Color(0xFF11998E), Color(0xFF38EF7D)], "navigateTo": const DynamicCategoryScreen(categoryId: 'nature', title: 'Nature'), "icon": Icons.eco_rounded},
    {"word": AppStrings.get('feelings'), "emoji": "🎭", "colors": [Color(0xFFFF512F), Color(0xFFDD2476)], "navigateTo": const DynamicCategoryScreen(categoryId: 'feelings', title: 'Feelings'), "icon": Icons.emoji_emotions_rounded},
    {"word": AppStrings.get('colors'), "emoji": "🎨", "colors": [Color(0xFFff9a9e), Color(0xFFfad0c4)], "navigateTo": const DynamicCategoryScreen(categoryId: 'colors', title: 'Colors'), "icon": Icons.palette_rounded},
    {"word": AppStrings.get('things'), "emoji": "🏡", "colors": [Color(0xFFa18cd1), Color(0xFFfbc2eb)], "navigateTo": const DynamicCategoryScreen(categoryId: 'things', title: 'Things'), "icon": Icons.chair_rounded},
    {"word": AppStrings.get('bodyParts'), "emoji": "🦴", "colors": [Color(0xFF8E2DE2), Color(0xFF4A00E0)], "navigateTo": const BodyPartsScreen(), "icon": Icons.accessibility_new_rounded},
    {"word": AppStrings.get('animals'), "emoji": "🐶", "colors": [Color(0xFFFF8008), Color(0xFFFFC837)], "navigateTo": const DynamicCategoryScreen(categoryId: 'animals', title: 'Animals'), "icon": Icons.pets_rounded},
    {"word": AppStrings.get('magicWords'), "emoji": "🔮", "colors": [Color(0xFFCC2B5E), Color(0xFF753A88)], "navigateTo": const DynamicCategoryScreen(categoryId: 'magic', title: 'Magic Words'), "icon": Icons.auto_fix_high_rounded},
    {"word": AppStrings.get('family'), "emoji": "👨‍👩‍👧", "colors": [Color(0xFF2193B0), Color(0xFF6DD5ED)], "navigateTo": const DynamicCategoryScreen(categoryId: 'family', title: 'Family'), "icon": Icons.family_restroom_rounded},
    
    // --- Regional Translations ---
    {"word": "Hindi\nTranslator", "emoji": "🇮🇳", "colors": [Color(0xFFD84315), Color(0xFFFF7043)], "navigateTo": RegionalTranslatorScreen(config: RegionalLanguageConfig('Hindi', TranslateLanguage.hindi, 'hi-IN', 'नमस्ते')), "icon": Icons.g_translate_rounded},
    {"word": "Tamil\nTranslator", "emoji": "🛕", "colors": [Color(0xFF2E7D32), Color(0xFF66BB6A)], "navigateTo": RegionalTranslatorScreen(config: RegionalLanguageConfig('Tamil', TranslateLanguage.tamil, 'ta-IN', 'வணக்கம்')), "icon": Icons.g_translate_rounded},
    {"word": "Bengali\nTranslator", "emoji": "🐅", "colors": [Color(0xFFC62828), Color(0xFFEF5350)], "navigateTo": RegionalTranslatorScreen(config: RegionalLanguageConfig('Bengali', TranslateLanguage.bengali, 'bn-IN', 'নমস্কার')), "icon": Icons.g_translate_rounded},
    {"word": "Telugu\nTranslator", "emoji": "🌶️", "colors": [Color(0xFF283593), Color(0xFF5C6BC0)], "navigateTo": RegionalTranslatorScreen(config: RegionalLanguageConfig('Telugu', TranslateLanguage.telugu, 'te-IN', 'నమస్కారం')), "icon": Icons.g_translate_rounded},

    // --- Advanced / Discovery ---
    {"word": AppStrings.get('andamaneseBeta'), "emoji": "🏝️", "colors": [Color(0xFF4A148C), Color(0xFF1A237E)], "navigateTo": const GAHubScreen(), "icon": Icons.language_rounded},
    {"word": AppStrings.get('natureHub'), "emoji": "🌿", "colors": [Color(0xFF1B5E20), Color(0xFF004D40)], "navigateTo": const FloraFaunaScreen(), "icon": Icons.eco_rounded},
    {"word": AppStrings.get('oralHistory'), "emoji": "📻", "colors": [Color(0xFF3E2723), Color(0xFF1B5E20)], "navigateTo": const StoryRadioScreen(), "icon": Icons.radio_rounded},
    {"word": AppStrings.get('tuhetKinship'), "emoji": "🌳", "colors": [Color(0xFF5D4037), Color(0xFF3E2723)], "navigateTo": const KinshipMapperScreen(), "icon": Icons.account_tree_rounded},
    {"word": AppStrings.get('islandExplorer'), "emoji": "🧭", "colors": [Color(0xFF0277BD), Color(0xFF01579B)], "navigateTo": const DialectHeatmapScreen(), "icon": Icons.explore_rounded},
    {"word": AppStrings.get('memoryPalace'), "emoji": "🏠", "colors": [Color(0xFF2E7D32), Color(0xFF1B5E20)], "navigateTo": const MemoryPalaceScreen(), "icon": Icons.map_rounded},
    {"word": AppStrings.get('community'), "emoji": "🌍", "colors": [Color(0xFF302B63), Color(0xFF24243E)], "navigateTo": const CommunityScreen(), "isSecret": true, "icon": Icons.public_rounded},
    {"word": "AI Setup", "emoji": "🧠", "colors": [Color(0xFF3b8d99), Color(0xFF6b6b83)], "navigateTo": const AISetupScreen(), "icon": Icons.psychology_rounded},
    {"word": AppStrings.get('feedback'), "emoji": "⭐", "colors": [Color(0xFFFF00CC), Color(0xFF333399)], "navigateTo": const FeedbackScreen(), "icon": Icons.feedback_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.studentTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8), // Lighter, clean background
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Elegant Light Background Gradients
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.pinkAccent.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
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
          ],
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
        ).animate().fadeIn().scale(curve: Curves.easeOutBack),
      );
  }

  Widget _buildDashboardContent() {
      return Padding(
         padding: const EdgeInsets.all(20),
         child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                 Text(AppStrings.get('yourProgress').toUpperCase(), style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                 const SizedBox(height: 10),
                 const GamificationHeader().animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                 const SizedBox(height: 30),
                 Text(AppStrings.get('exploreModules') != 'exploreModules' ? AppStrings.get('exploreModules').toUpperCase() : "EXPLORE MODULES", style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                 const SizedBox(height: 15),
                 _buildBentoGrid(),
                 const SizedBox(height: 100),
             ],
         ),
      );
  }

  Widget _buildBentoGrid() {
      return StaggeredGrid.count(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: List.generate(learningTiles.length, (index) {
          final tile = learningTiles[index];
          
          // Define Bento Grid Layout Configuration
          int crossAxisCellCount = 2; // Default width (half)
          int mainAxisCellCount = 2; // Default height

          if (index == 0) { // AR Translator gets full width hero tile
             crossAxisCellCount = 4; 
             mainAxisCellCount = 2;
          } else if (index == 1) { // Voice Vault
             crossAxisCellCount = 2;
             mainAxisCellCount = 3; // Taller
          } else if (index == 2) { // Book Scanner
             crossAxisCellCount = 2;
             mainAxisCellCount = 2; 
          } else if (index == 3) { // Games Hub
             crossAxisCellCount = 2;
             mainAxisCellCount = 2; 
          } else if (index == 4) { // Chat Translate
             crossAxisCellCount = 2;
             mainAxisCellCount = 1; // Shorter
          } else if (index == 6) { // Nature Hub Banner
             crossAxisCellCount = 4;
             mainAxisCellCount = 2;
          } else if (index % 11 == 0 && index > 10) { // Periodic large banners
             crossAxisCellCount = 4;
             mainAxisCellCount = 2;
          }

          return StaggeredGridTile.count(
            crossAxisCellCount: crossAxisCellCount,
            mainAxisCellCount: mainAxisCellCount,
            child: _buildPremiumTile(tile, index),
          );
        }),
      );
  }

  Widget _buildPremiumTile(Map<String, dynamic> tile, int index) {
      return TapScale(
          onTap: () {
              if (tile['isSecret'] == true) {
                  _showSecretAccessDialog(context, tile['navigateTo']);
              } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => tile['navigateTo']));
              }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (tile['colors'][0] as Color).withValues(alpha: 0.85),
                          (tile['colors'][1] as Color).withValues(alpha: 0.65),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                          BoxShadow(color: (tile['colors'][0] as Color).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0,8))
                      ]
                  ),
                  child: Stack(
                      children: [
                          // Large watermark icon for depth
                          Positioned(
                              right: -15, 
                              bottom: -15, 
                              child: Icon(tile['icon'], size: 100, color: Colors.white.withValues(alpha: 0.15))
                          ),
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                      Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.25), 
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1)
                                          ),
                                          child: Icon(tile['icon'], color: Colors.white, size: 24),
                                      ),
                                      Text(tile['word'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                                  ],
                              ),
                          )
                      ],
                  ),
              ),
            ),
          ),
      ).animate().fadeIn(delay: (index * 40).ms).scale(curve: Curves.easeOutBack, duration: 500.ms);
  }

  void _showSecretAccessDialog(BuildContext context, Widget targetScreen) {
    final answerController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🔒", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(AppStrings.get('seniorStudentAccess'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(AppStrings.get('solveToEnter'),
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
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
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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
                        child: Text(AppStrings.get('cancel')),
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
                              SnackBar(content: Text(AppStrings.get('incorrectAccessDenied'))));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(AppStrings.get('enter'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
