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
import 'package:speechmate/screens/feedback_screen.dart';
import 'package:speechmate/screens/beta_chat_screen.dart';
import 'package:speechmate/screens/ga_hub_screen.dart';
import 'package:speechmate/screens/flora_fauna_screen.dart';
import 'package:speechmate/screens/omni_translator_screen.dart';

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
    ttsService.dispose();
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
    {"word": AppStrings.get('arTranslator'), "emoji": "📷", "colors": [const Color(0xFF0F2027), const Color(0xFF2C5364)], "navigateTo": const ARTranslatorScreen(), "icon": Icons.view_in_ar_rounded},
    {"word": AppStrings.get('voiceVault'), "emoji": "🎙️", "colors": [const Color(0xFF4CA1AF), const Color(0xFF2C3E50)], "navigateTo": const VoiceVaultScreen(), "icon": Icons.mic_external_on_rounded},
    {"word": AppStrings.get('bookScanner'), "emoji": "📖", "colors": [const Color(0xFF00B4DB), const Color(0xFF0083B0)], "navigateTo": const CameraTranslationScreen(), "icon": Icons.document_scanner_rounded},
    {"word": AppStrings.get('games'), "emoji": "🎲", "colors": [const Color(0xFFF09819), const Color(0xFFEDDE5D)], "navigateTo": const GamesHubScreen(), "icon": Icons.sports_esports_rounded},
    {"word": AppStrings.get('chatTranslate'), "emoji": "💬", "colors": [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)], "navigateTo": const BetaChatScreen(isStudent: true), "icon": Icons.chat_bubble_rounded},
    {"word": AppStrings.get('voiceTranslate'), "emoji": "🎙️", "colors": [const Color(0xFFff0844), const Color(0xFFffb199)], "navigateTo": const VoiceTranslatorScreen(), "icon": Icons.record_voice_over_rounded},
    
    // --- Core Learning Categories ---
    {"word": AppStrings.get('numbers'), "emoji": "123", "colors": [const Color(0xFF6A11CB), const Color(0xFF2575FC)], "navigateTo": const DynamicCategoryScreen(categoryId: 'numbers', title: 'Numbers'), "icon": Icons.format_list_numbered_rounded},
    {"word": AppStrings.get('nature'), "emoji": "🌱", "colors": [const Color(0xFF11998E), const Color(0xFF38EF7D)], "navigateTo": const DynamicCategoryScreen(categoryId: 'nature', title: 'Nature'), "icon": Icons.eco_rounded},
    {"word": AppStrings.get('feelings'), "emoji": "🎭", "colors": [const Color(0xFFFF512F), const Color(0xFFDD2476)], "navigateTo": const DynamicCategoryScreen(categoryId: 'feelings', title: 'Feelings'), "icon": Icons.emoji_emotions_rounded},
    {"word": AppStrings.get('colors'), "emoji": "🎨", "colors": [const Color(0xFFff9a9e), const Color(0xFFfad0c4)], "navigateTo": const DynamicCategoryScreen(categoryId: 'colors', title: 'Colors'), "icon": Icons.palette_rounded},
    {"word": AppStrings.get('things'), "emoji": "🏡", "colors": [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)], "navigateTo": const DynamicCategoryScreen(categoryId: 'things', title: 'Things'), "icon": Icons.chair_rounded},
    {"word": AppStrings.get('bodyParts'), "emoji": "🦴", "colors": [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)], "navigateTo": const BodyPartsScreen(), "icon": Icons.accessibility_new_rounded},
    {"word": AppStrings.get('animals'), "emoji": "🐶", "colors": [const Color(0xFFFF8008), const Color(0xFFFFC837)], "navigateTo": const DynamicCategoryScreen(categoryId: 'animals', title: 'Animals'), "icon": Icons.pets_rounded},
    {"word": AppStrings.get('magicWords'), "emoji": "🔮", "colors": [const Color(0xFFCC2B5E), const Color(0xFF753A88)], "navigateTo": const DynamicCategoryScreen(categoryId: 'magic', title: 'Magic Words'), "icon": Icons.auto_fix_high_rounded},
    {"word": AppStrings.get('family'), "emoji": "👨‍👩‍👧", "colors": [const Color(0xFF2193B0), const Color(0xFF6DD5ED)], "navigateTo": const DynamicCategoryScreen(categoryId: 'family', title: 'Family'), "icon": Icons.family_restroom_rounded},
    
    // --- Regional Translations ---
    {"word": "Omni Broadcast", "emoji": "📡", "colors": [const Color(0xFF1A2980), const Color(0xFF26D0CE)], "navigateTo": const OmniTranslatorScreen(), "icon": Icons.cell_tower_rounded},
    {"word": "Hindi\nTranslator", "emoji": "🇮🇳", "colors": [const Color(0xFFD84315), const Color(0xFFFF7043)], "navigateTo": RegionalTranslatorScreen(config: RegionalLanguageConfig('Hindi', TranslateLanguage.hindi, 'hi', 'hi-IN', 'नमस्ते')), "icon": Icons.g_translate_rounded},
    {"word": "Tamil\nTranslator", "emoji": "🛕", "colors": [const Color(0xFF2E7D32), const Color(0xFF66BB6A)], "navigateTo": RegionalTranslatorScreen(config: RegionalLanguageConfig('Tamil', TranslateLanguage.tamil, 'ta', 'ta-IN', 'வணக்கம்')), "icon": Icons.g_translate_rounded},
    {"word": "Bengali\nTranslator", "emoji": "🐅", "colors": [const Color(0xFFC62828), const Color(0xFFEF5350)], "navigateTo": RegionalTranslatorScreen(config: RegionalLanguageConfig('Bengali', TranslateLanguage.bengali, 'bn', 'bn-IN', 'নমস্কার')), "icon": Icons.g_translate_rounded},
    {"word": "Telugu\nTranslator", "emoji": "🌶️", "colors": [const Color(0xFF283593), const Color(0xFF5C6BC0)], "navigateTo": RegionalTranslatorScreen(config: RegionalLanguageConfig('Telugu', TranslateLanguage.telugu, 'te', 'te-IN', 'నమస్కారం')), "icon": Icons.g_translate_rounded},
    {"word": "Malayalam\nTranslator", "emoji": "🥥", "colors": [const Color(0xFF00695C), const Color(0xFF26A69A)], "navigateTo": RegionalTranslatorScreen(config: RegionalLanguageConfig('Malayalam', null, 'ml', 'ml-IN', 'നമസ്കാരം')), "icon": Icons.g_translate_rounded},

    // --- Advanced / Discovery ---
    {"word": AppStrings.get('andamaneseBeta'), "emoji": "🏝️", "colors": [const Color(0xFF4A148C), const Color(0xFF1A237E)], "navigateTo": const GAHubScreen(), "icon": Icons.language_rounded},
    {"word": AppStrings.get('natureHub'), "emoji": "🌿", "colors": [const Color(0xFF1B5E20), const Color(0xFF004D40)], "navigateTo": const FloraFaunaScreen(), "icon": Icons.eco_rounded},
    {"word": AppStrings.get('oralHistory'), "emoji": "📻", "colors": [const Color(0xFF3E2723), const Color(0xFF1B5E20)], "navigateTo": const StoryRadioScreen(), "icon": Icons.radio_rounded},
    {"word": AppStrings.get('tuhetKinship'), "emoji": "🌳", "colors": [const Color(0xFF5D4037), const Color(0xFF3E2723)], "navigateTo": const KinshipMapperScreen(), "icon": Icons.account_tree_rounded},
    {"word": AppStrings.get('islandExplorer'), "emoji": "🧭", "colors": [const Color(0xFF0277BD), const Color(0xFF01579B)], "navigateTo": const DialectHeatmapScreen(), "icon": Icons.explore_rounded},
    {"word": AppStrings.get('memoryPalace'), "emoji": "🏠", "colors": [const Color(0xFF2E7D32), const Color(0xFF1B5E20)], "navigateTo": const MemoryPalaceScreen(), "icon": Icons.map_rounded},
    {"word": AppStrings.get('community'), "emoji": "🌍", "colors": [const Color(0xFF302B63), const Color(0xFF24243E)], "navigateTo": const CommunityScreen(), "isSecret": true, "icon": Icons.public_rounded},
    {"word": "AI Setup", "emoji": "🧠", "colors": [const Color(0xFF3b8d99), const Color(0xFF6b6b83)], "navigateTo": const AISetupScreen(), "icon": Icons.psychology_rounded},
    {"word": AppStrings.get('feedback'), "emoji": "⭐", "colors": [const Color(0xFFFF00CC), const Color(0xFF333399)], "navigateTo": const FeedbackScreen(), "icon": Icons.feedback_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.studentTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8), // Fallback color
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Vibrant Background for Glassmorphism
            const AmbientGlassBackground(),
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
          const VirtualPetCompanion(),
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
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // 🎯 Daily Mission Card
                  const DailyMissionCard().animate().fadeIn(duration: 700.ms).slideY(begin: 0.15),
                  const SizedBox(height: 20),

                  // ⚡ Quick Stats Row (Stars, Streak, Level)
                  const QuickStatsRow().animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                  const SizedBox(height: 24),

                  // 🏆 My Progress
                  const KidsSectionHeader(emoji: '🏆', label: 'My Progress'),
                  const SizedBox(height: 10),
                  const GamificationHeader().animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                  const SizedBox(height: 20),
                  const ProgressRadarChartWidget().animate().fadeIn(duration: 900.ms).scale(),
                  const SizedBox(height: 20),

                  // 🥇 My Badges
                  const KidsSectionHeader(emoji: '🥇', label: 'My Badges'),
                  const SizedBox(height: 10),
                  const AchievementShowcaseWidget().animate().fadeIn(duration: 800.ms).slideX(begin: 0.1),
                  const SizedBox(height: 28),

                  // 🚀 Let's Learn!
                  const KidsSectionHeader(emoji: '🚀', label: "Let's Learn!"),
                  const SizedBox(height: 14),
                  _buildBentoGrid(),
                  const SizedBox(height: 110),
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
            child: _buildPremiumTile(tile, index, crossAxisCellCount, mainAxisCellCount),
          );
        }),
      );
  }

  Widget _buildPremiumTile(Map<String, dynamic> tile, int index, int crossAxis, int mainAxis) {
      bool isShort = mainAxis <= 1;
      bool isWide = crossAxis > 2;

      return PremiumTiltCard(
          onTap: () {
              if (tile['isSecret'] == true) {
                  _showSecretAccessDialog(context, tile['navigateTo']);
              } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => tile['navigateTo']));
              }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (tile['colors'][0] as Color).withValues(alpha: 0.7), 
                              (tile['colors'][1] as Color).withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                          boxShadow: [
                              BoxShadow(color: (tile['colors'][0] as Color).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))
                          ]
                      ),
                      child: Stack(
                          children: [
                              // Large watermark icon for depth
                              Positioned(
                                  right: isShort ? -5 : -15, 
                                  bottom: isShort ? -15 : -25, 
                                  child: Opacity(
                                    opacity: 0.1,
                                    child: Icon(tile['icon'], size: isShort ? 70 : 120, color: Colors.white)
                                  ),
                              ),
                              // Optional Animated Sparkles for kids
                              Positioned(
                                  top: 10, right: 10,
                                  child: Icon(Icons.star_rounded, color: Colors.white.withValues(alpha: 0.5), size: 28).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(end: 1.3, duration: 800.ms),
                              ),
                              Positioned.fill(
                                  child: Padding(
                                      padding: EdgeInsets.all(isShort ? 12 : 16),
                                      child: isShort ? _buildShortLayout(tile) : _buildNormalLayout(tile, isWide),
                                  ),
                              ),
                          ],
                      ),
              ),
            ),
          ),
      ).animate().fadeIn(delay: (index * 40).ms).scale(curve: Curves.easeOutBack, duration: 500.ms);
  }

  Widget _buildShortLayout(Map<String, dynamic> tile) {
      return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25), 
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5)
                  ),
                  child: Icon(tile['icon'], color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      tile['word'], 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                  ),
              ),
          ],
      );
  }

  Widget _buildNormalLayout(Map<String, dynamic> tile, bool isWide) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25), 
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2)
                  ),
                  child: Icon(tile['icon'], color: Colors.white, size: 32),
              ),
              Expanded(
                  child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                          tile['word'], 
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900, 
                            fontSize: isWide ? 24 : 18, 
                            height: 1.1,
                            letterSpacing: 0.5, 
                            shadows: [
                              Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 2), blurRadius: 4)
                            ]
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                      ),
                  ),
              ),
          ],
      );
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

// ============================================================================
// COMPETITION-GRADE ADVANCED UI COMPONENTS & ANALYTICS SUITE
// ============================================================================

import 'dart:math' as math;

// ----------------------------------------------------------------------------
// 1. Ambient Animated Glass Background (Custom Painted Canvas)
// ----------------------------------------------------------------------------
/// Renders a dynamic, heavily optimized animated blob gradient background.
/// Uses multiple overlapping radial gradients painted on a custom canvas
/// to avoid widget tree bloat and maintain 60FPS scrolling performance.
class AmbientGlassBackground extends StatefulWidget {
  const AmbientGlassBackground({super.key});

  @override
  State<AmbientGlassBackground> createState() => _AmbientGlassBackgroundState();
}

class _AmbientGlassBackgroundState extends State<AmbientGlassBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _AmbientPainter(_controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double progress;
  _AmbientPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    final Rect rect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // FAST HARDWARE ACCELERATED GRADIENTS (FIXES HANGING ON PHONES)
    // Replaced MaskFilter.blur which kills mobile performance with RadialGradients.
    void drawFastGlowingOrb(double x, double y, double radius, Color color) {
       final rect = Rect.fromCircle(center: Offset(x, y), radius: radius);
       final paint = Paint()
         ..shader = RadialGradient(
           colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.0)],
           stops: const [0.1, 1.0],
         ).createShader(rect);
       canvas.drawRect(rect, paint);
    }

    final double x1 = size.width * 0.5 + math.sin(progress * math.pi * 2) * size.width * 0.4;
    final double y1 = size.height * 0.3 + math.cos(progress * math.pi * 2) * size.height * 0.2;
    drawFastGlowingOrb(x1, y1, 300, Colors.cyanAccent);

    final double x2 = size.width * 0.2 + math.cos(progress * math.pi * 2 + math.pi) * size.width * 0.3;
    final double y2 = size.height * 0.8 + math.sin(progress * math.pi * 2 + math.pi) * size.height * 0.3;
    drawFastGlowingOrb(x2, y2, 350, Colors.pinkAccent);

    final double x3 = size.width * 0.8 + math.sin(progress * math.pi * 2 + math.pi/2) * size.width * 0.3;
    final double y3 = size.height * 0.5 + math.cos(progress * math.pi * 2 + math.pi/2) * size.height * 0.4;
    drawFastGlowingOrb(x3, y3, 280, Colors.purpleAccent);
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => true;
}

// ----------------------------------------------------------------------------
// 2. Interactive 3D Tilt Card wrapper (Gyroscope-like Interaction)
// ----------------------------------------------------------------------------
/// Captures pan gestures on a child widget and applies a 3D matrix transformation
/// to simulate depth, shadow shifting, and tactile responsiveness.
class PremiumTiltCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const PremiumTiltCard({super.key, required this.child, required this.onTap});

  @override
  State<PremiumTiltCard> createState() => _PremiumTiltCardState();
}

class _PremiumTiltCardState extends State<PremiumTiltCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);
    final double percentX = (localPos.dx / size.width) - 0.5;
    final double percentY = (localPos.dy / size.height) - 0.5;
    setState(() {
      _tiltX = percentY * 0.3; // Constrained pitch rotation
      _tiltY = -percentX * 0.3; // Constrained yaw rotation
    });
  }

  void _reset() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _reset();
            widget.onTap();
          },
          onTapCancel: _reset,
          onPanUpdate: (details) => _onPanUpdate(details, size),
          onPanEnd: (_) => _reset(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = 1.0 - (_controller.value * 0.05);
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateX(_tiltX)
                  ..rotateY(_tiltY)
                  ..scale(scale, scale, scale),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: widget.child,
          ),
        );
      }
    );
  }
}

// ----------------------------------------------------------------------------
// 3. Daily Discovery Glass Card
// ----------------------------------------------------------------------------
/// Prominently displays the "Word of the Day" with rich typography and 
/// glassmorphic background to encourage daily engagement.
class DailyDiscoveryCard extends StatelessWidget {
  const DailyDiscoveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("WORD OF THE DAY", style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                  const Spacer(),
                  const Icon(Icons.volume_up_rounded, color: Colors.purpleAccent),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Pōt", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.0)),
              const Text("Nicobarese", style: TextStyle(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.black12),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.translate_rounded, size: 16, color: Colors.black54),
                  SizedBox(width: 8),
                  Text("Meaning:", style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  Text("Ocean / Sea", style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 4. Progress Radar Chart Widget (Animated Custom Canvas)
// ----------------------------------------------------------------------------
/// Renders a complex spider/radar chart displaying the student's fluency 
/// across multiple linguistic domains. Built purely via the Canvas API.
class ProgressRadarChartWidget extends StatefulWidget {
  const ProgressRadarChartWidget({super.key});

  @override
  State<ProgressRadarChartWidget> createState() => _ProgressRadarChartWidgetState();
}

class _ProgressRadarChartWidgetState extends State<ProgressRadarChartWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Dummy data for competition showcase presentation
  final List<double> values = [0.85, 0.60, 0.95, 0.45, 0.75];
  final List<String> labels = ["Nature", "Family", "Numbers", "Colors", "Animals"];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)
        ]
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarChartPainter(
              values: values,
              labels: labels,
              progress: CurvedAnimation(parent: _controller, curve: Curves.elasticOut).value,
            ),
          );
        },
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double progress;

  _RadarChartPainter({required this.values, required this.labels, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.8;
    final int sides = values.length;
    final double angle = (2 * math.pi) / sides;

    // Draw Polygonal Webs (Background rings)
    final webPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int step = 1; step <= 4; step++) {
      final double r = radius * (step / 4);
      final Path webPath = Path();
      for (int i = 0; i < sides; i++) {
        final double x = center.dx + r * math.cos(i * angle - math.pi / 2);
        final double y = center.dy + r * math.sin(i * angle - math.pi / 2);
        if (i == 0) {
          webPath.moveTo(x, y);
        } else {
          webPath.lineTo(x, y);
        }
      }
      webPath.close();
      canvas.drawPath(webPath, webPaint);
    }

    // Draw Radial Spokes and Labels
    for (int i = 0; i < sides; i++) {
      final double x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final double y = center.dy + radius * math.sin(i * angle - math.pi / 2);
      canvas.drawLine(center, Offset(x, y), webPaint);
      
      final labelSpan = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)
      );
      final tp = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)..layout();
      
      // Calculate label offsets outside the web
      final double lx = center.dx + (radius + 20) * math.cos(i * angle - math.pi / 2) - tp.width/2;
      final double ly = center.dy + (radius + 20) * math.sin(i * angle - math.pi / 2) - tp.height/2;
      tp.paint(canvas, Offset(lx, ly));
    }

    // Draw Data Polygon Mask (Animated)
    final Path dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final double r = radius * values[i] * progress;
      final double x = center.dx + r * math.cos(i * angle - math.pi / 2);
      final double y = center.dy + r * math.sin(i * angle - math.pi / 2);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Fill with translucent cyan
    final dataPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, dataPaint);

    // Outline path
    final dataBorderPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, dataBorderPaint);
    
    // Draw Data Points on top
    for (int i = 0; i < sides; i++) {
      final double r = radius * values[i] * progress;
      final double x = center.dx + r * math.cos(i * angle - math.pi / 2);
      final double y = center.dy + r * math.sin(i * angle - math.pi / 2);
      
      final pointPaint = Paint()..color = Colors.cyanAccent..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x,y), 4, pointPaint);
      final pointBorder = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x,y), 4, pointBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) => true;
}

// ----------------------------------------------------------------------------
// 5. Achievement Showcase Ribbon List
// ----------------------------------------------------------------------------
/// Renders a horizontal scrolling list of dynamically painted achievement medals.
class AchievementShowcaseWidget extends StatelessWidget {
  const AchievementShowcaseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {'title': 'First Word', 'color': Colors.orangeAccent, 'icon': Icons.star_rounded},
      {'title': 'Explorer', 'color': Colors.cyanAccent, 'icon': Icons.explore_rounded},
      {'title': '7 Day Streak', 'color': Colors.pinkAccent, 'icon': Icons.local_fire_department_rounded},
      {'title': 'Grammar Pro', 'color': Colors.greenAccent, 'icon': Icons.spellcheck_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.get('achievements') != 'achievements' ? AppStrings.get('achievements').toUpperCase() : "ACHIEVEMENTS", style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.5),
                        border: Border.all(color: (a['color'] as Color).withValues(alpha: 0.8), width: 2),
                        boxShadow: [
                          BoxShadow(color: (a['color'] as Color).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(a['title'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center, maxLines: 2),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// KID-FRIENDLY WIDGETS FOR AGES 6–14
// ============================================================================

// ----------------------------------------------------------------------------
// 1. Daily Mission Card
// ----------------------------------------------------------------------------
/// A bright, animated mission card that gives students a fun daily learning goal.
class DailyMissionCard extends StatefulWidget {
  const DailyMissionCard({super.key});
  @override
  State<DailyMissionCard> createState() => _DailyMissionCardState();
}

class _DailyMissionCardState extends State<DailyMissionCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  final double _progress = 0.45; // 45% done — mocked

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF6B6B).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎯', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Text('DAILY MISSION', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (ctx, _) => Text(
                      '+50 ⭐',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7 + 0.3 * _shimmer.value),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Learn 5 new Nicobarese words!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                'Use the AR Scanner or Games to explore words 🌟',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(_progress * 5).round()} / 5 words', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${(_progress * 100).round()}% done!', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 2. Quick Stats Row (Streak 🔥, Stars ⭐, Level 🏅)
// ----------------------------------------------------------------------------
/// Three colourful bubble-cards showing a student's key stats at a glance.
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatBubble(emoji: '🔥', label: 'Streak', value: '7 days', color: const Color(0xFFFF6B35)),
        const SizedBox(width: 12),
        _buildStatBubble(emoji: '⭐', label: 'Stars', value: '342', color: const Color(0xFFFFD700)),
        const SizedBox(width: 12),
        _buildStatBubble(emoji: '🏅', label: 'Level', value: 'Explorer', color: const Color(0xFF7B61FF)),
      ],
    );
  }

  Widget _buildStatBubble({required String emoji, required String label, required String value, required Color color}) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 3. Kids Section Header
// ----------------------------------------------------------------------------
/// A fun, colourful section label with a big emoji for easy reading.
class KidsSectionHeader extends StatelessWidget {
  final String emoji;
  final String label;
  const KidsSectionHeader({super.key, required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.black12, Colors.transparent]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// 4. Fun Virtual Companion for Kids
// ----------------------------------------------------------------------------
/// A bouncing, interactive virtual pet that floats at the bottom-right corner.
/// Provides positive reinforcement when tapped.
class VirtualPetCompanion extends StatefulWidget {
  const VirtualPetCompanion({super.key});

  @override
  State<VirtualPetCompanion> createState() => _VirtualPetCompanionState();
}

class _VirtualPetCompanionState extends State<VirtualPetCompanion> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  bool _isHappy = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          if (_isHappy) return;
          setState(() => _isHappy = true);
          _bounceController.duration = const Duration(milliseconds: 300);
          _bounceController.repeat(reverse: true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _isHappy = false);
              _bounceController.duration = const Duration(seconds: 2);
              _bounceController.repeat(reverse: true);
            }
          });
        },
        child: AnimatedBuilder(
          animation: _bounceController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -15 * Curves.easeInOutSine.transform(_bounceController.value)),
              child: child,
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_isHappy)
                Positioned(
                  top: -52,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: const Text("Yay! Let's learn! 🌟", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ).animate().scale(curve: Curves.elasticOut),
                ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                  border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.6), width: 3),
                ),
                child: Center(
                  child: Text(_isHappy ? '🐶' : '🦊', style: const TextStyle(fontSize: 42)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
