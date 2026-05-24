import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/widgets/translation_card.dart';
import 'package:speechmate/widgets/gamification_header.dart';
import 'package:speechmate/widgets/smart_dashboard_header.dart';
import 'package:speechmate/core/app_theme.dart';
import 'package:speechmate/mixins/searchable_dashboard_mixin.dart';
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
import 'package:speechmate/screens/classroom_leaderboard_screen.dart';
import 'package:speechmate/screens/achievement_badges_screen.dart';
import 'package:speechmate/screens/cultural_calendar_screen.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// ============================================================================
// DECOMPOSED COMPONENTS (extracted for maintainability — was 2,536 lines)
// ============================================================================
import 'package:speechmate/screens/student_dash_widgets.dart';
import 'package:speechmate/screens/student_dash_pet.dart';
import 'package:speechmate/screens/student_dash_stats.dart';
import 'package:speechmate/screens/student_dash_engines.dart';

class StudentDash extends StatefulWidget {
  const StudentDash({super.key});

  @override
  State<StudentDash> createState() => _StudentDashState();
}

class _StudentDashState extends State<StudentDash>
    with WidgetsBindingObserver, SearchableDashboardMixin {
  final TextEditingController searchController = TextEditingController();
  final TtsService ttsService = TtsService();
  bool _showConfetti = false;

  void _triggerConfetti() {
    setState(() => _showConfetti = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

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
        {
          "word": AppStrings.get('arTranslator'),
          "emoji": "📷",
          "colors": [const Color(0xFF0F2027), const Color(0xFF2C5364)],
          "navigateTo": const ARTranslatorScreen(),
          "icon": Icons.view_in_ar_rounded
        },
        {
          "word": AppStrings.get('voiceVault'),
          "emoji": "🎙️",
          "colors": [const Color(0xFF4CA1AF), const Color(0xFF2C3E50)],
          "navigateTo": const VoiceVaultScreen(),
          "icon": Icons.mic_external_on_rounded,
        },
        {
          "word": AppStrings.get('bookScanner'),
          "emoji": "📖",
          "colors": [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
          "navigateTo": const CameraTranslationScreen(),
          "icon": Icons.document_scanner_rounded
        },
        {
          "word": AppStrings.get('games'),
          "emoji": "🎲",
          "colors": [const Color(0xFFF09819), const Color(0xFFEDDE5D)],
          "navigateTo": const GamesHubScreen(),
          "icon": Icons.sports_esports_rounded
        },
        {
          "word": 'Leaderboard',
          "emoji": "🏆",
          "colors": [const Color(0xFFDAA520), const Color(0xFFFF8C00)],
          "navigateTo": const ClassroomLeaderboardScreen(),
          "icon": Icons.leaderboard_rounded
        },
        {
          "word": 'Achievements',
          "emoji": "🏅",
          "colors": [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
          "navigateTo": const AchievementBadgesScreen(),
          "icon": Icons.emoji_events_rounded
        },
        {
          "word": 'Cultural Calendar',
          "emoji": "🎭",
          "colors": [const Color(0xFFEC4899), const Color(0xFFF472B6)],
          "navigateTo": const CulturalCalendarScreen(),
          "icon": Icons.calendar_month_rounded
        },
        {
          "word": AppStrings.get('chatTranslate'),
          "emoji": "💬",
          "colors": [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
          "navigateTo": const BetaChatScreen(isStudent: true),
          "icon": Icons.chat_bubble_rounded,
        },
        {
          "word": AppStrings.get('voiceTranslate'),
          "emoji": "🎙️",
          "colors": [const Color(0xFFff0844), const Color(0xFFffb199)],
          "navigateTo": const VoiceTranslatorScreen(),
          "icon": Icons.record_voice_over_rounded
        },

        // --- Core Learning Categories ---
        {
          "word": AppStrings.get('numbers'),
          "emoji": "123",
          "colors": [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'numbers', title: 'Numbers'),
          "icon": Icons.format_list_numbered_rounded
        },
        {
          "word": AppStrings.get('nature'),
          "emoji": "🌱",
          "colors": [const Color(0xFF11998E), const Color(0xFF38EF7D)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'nature', title: 'Nature'),
          "icon": Icons.eco_rounded
        },
        {
          "word": AppStrings.get('feelings'),
          "emoji": "🎭",
          "colors": [const Color(0xFFFF512F), const Color(0xFFDD2476)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'feelings', title: 'Feelings'),
          "icon": Icons.emoji_emotions_rounded
        },
        {
          "word": AppStrings.get('colors'),
          "emoji": "🎨",
          "colors": [const Color(0xFFff9a9e), const Color(0xFFfad0c4)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'colors', title: 'Colors'),
          "icon": Icons.palette_rounded
        },
        {
          "word": AppStrings.get('things'),
          "emoji": "🏡",
          "colors": [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'things', title: 'Things'),
          "icon": Icons.chair_rounded
        },
        {
          "word": AppStrings.get('bodyParts'),
          "emoji": "🦴",
          "colors": [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
          "navigateTo": const BodyPartsScreen(),
          "icon": Icons.accessibility_new_rounded
        },
        {
          "word": AppStrings.get('animals'),
          "emoji": "🐶",
          "colors": [const Color(0xFFFF8008), const Color(0xFFFFC837)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'animals', title: 'Animals'),
          "icon": Icons.pets_rounded
        },
        {
          "word": AppStrings.get('magicWords'),
          "emoji": "🔮",
          "colors": [const Color(0xFFCC2B5E), const Color(0xFF753A88)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'magic', title: 'Magic Words'),
          "icon": Icons.auto_fix_high_rounded
        },
        {
          "word": AppStrings.get('family'),
          "emoji": "👨‍👩‍👧",
          "colors": [const Color(0xFF2193B0), const Color(0xFF6DD5ED)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'family', title: 'Family'),
          "icon": Icons.family_restroom_rounded
        },

        // --- Regional Translations ---
        {
          "word": AppStrings.get('omniBroadcast'),
          "emoji": "📡",
          "colors": [const Color(0xFF1A2980), const Color(0xFF26D0CE)],
          "navigateTo": const OmniTranslatorScreen(),
          "icon": Icons.cell_tower_rounded
        },
        {
          "word": AppStrings.get('hindiTranslator'),
          "emoji": "🇮🇳",
          "colors": [const Color(0xFFD84315), const Color(0xFFFF7042)],
          "navigateTo": RegionalTranslatorScreen(
              config: RegionalLanguageConfig(
                  'Hindi', TranslateLanguage.hindi, 'hi', 'hi-IN', 'नमस्ते')),
          "icon": Icons.g_translate_rounded
        },
        {
          "word": AppStrings.get('tamilTranslator'),
          "emoji": "🛕",
          "colors": [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
          "navigateTo": RegionalTranslatorScreen(
              config: RegionalLanguageConfig(
                  'Tamil', TranslateLanguage.tamil, 'ta', 'ta-IN', 'வணக்கம்')),
          "icon": Icons.g_translate_rounded
        },
        {
          "word": AppStrings.get('bengaliTranslator'),
          "emoji": "🐅",
          "colors": [const Color(0xFFC62828), const Color(0xFFEF5350)],
          "navigateTo": RegionalTranslatorScreen(
              config: RegionalLanguageConfig('Bengali',
                  TranslateLanguage.bengali, 'bn', 'bn-IN', 'নমস্কার')),
          "icon": Icons.g_translate_rounded
        },
        {
          "word": AppStrings.get('teluguTranslator'),
          "emoji": "🌶️",
          "colors": [const Color(0xFF283593), const Color(0xFF5C6BC0)],
          "navigateTo": RegionalTranslatorScreen(
              config: RegionalLanguageConfig('Telugu', TranslateLanguage.telugu,
                  'te', 'te-IN', 'నమస్కారం')),
          "icon": Icons.g_translate_rounded
        },
        {
          "word": AppStrings.get('malayalamTranslator'),
          "emoji": "🥥",
          "colors": [const Color(0xFF00695C), const Color(0xFF26A69A)],
          "navigateTo": RegionalTranslatorScreen(
              config: RegionalLanguageConfig(
                  'Malayalam', null, 'ml', 'ml-IN', 'നമസ്കാരം')),
          "icon": Icons.g_translate_rounded
        },

        // --- Advanced / Discovery ---
        {
          "word": AppStrings.get('andamaneseBeta'),
          "emoji": "🏝️",
          "colors": [const Color(0xFF4A148C), const Color(0xFF1A237E)],
          "navigateTo": const GAHubScreen(),
          "icon": Icons.language_rounded
        },
        {
          "word": AppStrings.get('natureHub'),
          "emoji": "🌿",
          "colors": [const Color(0xFF1B5E20), const Color(0xFF004D40)],
          "navigateTo": const FloraFaunaScreen(),
          "icon": Icons.eco_rounded
        },
        {
          "word": AppStrings.get('oralHistory'),
          "emoji": "📻",
          "colors": [const Color(0xFF3E2723), const Color(0xFF1B5E20)],
          "navigateTo": const StoryRadioScreen(),
          "icon": Icons.radio_rounded
        },
        {
          "word": AppStrings.get('tuhetKinship'),
          "emoji": "🌳",
          "colors": [const Color(0xFF5D4037), const Color(0xFF3E2723)],
          "navigateTo": const KinshipMapperScreen(),
          "icon": Icons.account_tree_rounded
        },
        {
          "word": AppStrings.get('islandExplorer'),
          "emoji": "🧭",
          "colors": [const Color(0xFF0277BD), const Color(0xFF01579B)],
          "navigateTo": const DialectHeatmapScreen(),
          "icon": Icons.explore_rounded,
        },
        {
          "word": AppStrings.get('memoryPalace'),
          "emoji": "🏠",
          "colors": [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
          "navigateTo": const MemoryPalaceScreen(),
          "icon": Icons.map_rounded,
        },
        {
          "word": AppStrings.get('community'),
          "emoji": "🌍",
          "colors": [const Color(0xFF302B63), const Color(0xFF24243E)],
          "navigateTo": const CommunityScreen(),
          "isSecret": true,
          "icon": Icons.public_rounded,
        },
        {
          "word": AppStrings.get('aiSetup'),
          "emoji": "🧠",
          "colors": [const Color(0xFF3b8d99), const Color(0xFF6b6b83)],
          "navigateTo": const AISetupScreen(),
          "icon": Icons.psychology_rounded,
        },
        {
          "word": AppStrings.get('feedback'),
          "emoji": "⭐",
          "colors": [const Color(0xFFFF00CC), const Color(0xFF333399)],
          "navigateTo": const FeedbackScreen(),
          "icon": Icons.feedback_rounded
        },
      ];

  @override
  Widget build(BuildContext context) {
    try {
    return Theme(
      data: AppTheme.studentTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8), // Fallback color
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Vibrant Background for Glassmorphism
            // NOTE: AmbientGlassBackground returns Positioned.fill, so it must be
            // a direct Stack child (no RepaintBoundary wrapper — it's inside instead).
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
                                child: CircularProgressIndicator(
                                    color: Colors.cyanAccent),
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
            // NOTE: VirtualPetCompanion returns Positioned, so it must be
            // a direct Stack child (no RepaintBoundary wrapper).
            VirtualPetCompanion(onPetHappy: _triggerConfetti),
            ConfettiOverlay(trigger: _showConfetti),
          ],
        ),
      ),
    );
    } catch (e, stack) {
      debugPrint('[StudentDash] Build error: $e\n$stack');
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text("Dashboard Error", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(), style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center, maxLines: 5),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Go Back"),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSearchResults() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TranslationCard(
        nicobarese: searchResult != null
            ? (searchResult!['nicobarese'] ?? "Translation not available")
            : "No match found",
        english: searchResult != null
            ? (searchResult!['english'] ??
                searchResult!['text'] ??
                "No translation")
            : "",
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
            ttsService.speakNicobarese(textToSpeak,
                englishWord: searchResult!['english'] ?? searchResult!['text']);
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
          const DailyMissionCard()
              .animate()
              .fadeIn(duration: 700.ms)
              .slideY(begin: 0.15),
          const SizedBox(height: 20),

          // ⚡ Quick Stats Row (Stars, Streak, Level)
          const QuickStatsRow()
              .animate()
              .fadeIn(duration: 600.ms)
              .slideX(begin: -0.1),
          const SizedBox(height: 20),

          // 🎙️ Voice Waveform Visualizer
          KidsSectionHeader(emoji: '🎙️', label: AppStrings.get('sectionSoundWave')),
          const SizedBox(height: 8),
          const VoiceWaveformWidget().animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 20),

          // 🏆 My Progress
          KidsSectionHeader(emoji: '🏆', label: AppStrings.get('sectionMyProgress')),
          const SizedBox(height: 10),
          const GamificationHeader()
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 20),
          const ProgressRadarChartWidget()
              .animate()
              .fadeIn(duration: 900.ms)
              .scale(),
          const SizedBox(height: 20),

          // 🥇 My Badges
          KidsSectionHeader(emoji: '🥇', label: AppStrings.get('sectionMyBadges')),
          const SizedBox(height: 10),
          const AchievementShowcaseWidget()
              .animate()
              .fadeIn(duration: 800.ms)
              .slideX(begin: 0.1),
          const SizedBox(height: 28),

          // 🚀 Let's Learn!
          KidsSectionHeader(emoji: '🚀', label: AppStrings.get('sectionLetsLearn')),
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

        if (index == 0) {
          // AR Translator gets full width hero tile
          crossAxisCellCount = 4;
          mainAxisCellCount = 2;
        } else if (index == 1) {
          // Book Scanner
          crossAxisCellCount = 2;
          mainAxisCellCount = 3; // Taller
        } else if (index == 2) {
          // Games Hub
          crossAxisCellCount = 2;
          mainAxisCellCount = 2;
        } else if (index == 5) {
          // Nature category — periodic wide banner
          crossAxisCellCount = 4;
          mainAxisCellCount = 2;
        } else if (index % 11 == 0 && index > 10) {
          // Periodic large banners
          crossAxisCellCount = 4;
          mainAxisCellCount = 2;
        }

        return StaggeredGridTile.count(
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: mainAxisCellCount,
          child: _buildPremiumTile(
              tile, index, crossAxisCellCount, mainAxisCellCount),
        );
      }),
    );
  }

  Widget _buildPremiumTile(
      Map<String, dynamic> tile, int index, int crossAxis, int mainAxis) {
    bool isShort = mainAxis <= 1;
    bool isWide = crossAxis > 2;

    return PremiumTiltCard(
      onTap: () {
        if (tile['isSecret'] == true) {
          _showSecretAccessDialog(context, tile['navigateTo']);
        } else {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => tile['navigateTo']));
        }
      },
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
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color:
                      (tile['colors'][0] as Color).withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8))
            ]),
        child: Stack(
          children: [
            // Large watermark icon for depth
            Positioned(
              right: isShort ? -5 : -15,
              bottom: isShort ? -15 : -25,
              child: Opacity(
                  opacity: 0.1,
                  child: Icon(tile['icon'],
                      size: isShort ? 70 : 120, color: Colors.white)),
            ),
            // Static sparkle accent (no animation controller)
            Positioned(
              top: 10,
              right: 10,
              child: Icon(Icons.star_rounded,
                      color: Colors.white.withValues(alpha: 0.4), size: 24),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(isShort ? 12 : 16),
                child: isShort
                    ? _buildShortLayout(tile)
                    : _buildNormalLayout(tile, isWide),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index.clamp(0, 5) * 40).ms)
        .scale(curve: Curves.easeOutBack, duration: 400.ms);
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
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5), width: 1.5)),
          child: Icon(tile['icon'], color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tile['word'],
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.5),
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
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5), width: 2)),
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
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4)
                  ]),
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
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3), blurRadius: 30)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🔒", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(AppStrings.get('seniorStudentAccess'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(AppStrings.get('solveToEnter'),
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextField(
                  controller: answerController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "?",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white54),
                        child: Text(AppStrings.get('cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (answerController.text.trim() == "27") {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => targetScreen));
                          } else {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    AppStrings.get('incorrectAccessDenied'))));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(AppStrings.get('enter'),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
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
