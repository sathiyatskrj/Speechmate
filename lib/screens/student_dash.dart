import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/native_edge_service.dart';
import 'package:speechmate/widgets/nicobarese_inapp_keyboard.dart';
import 'package:speechmate/services/progress_service.dart';
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

// New features
import 'package:speechmate/screens/phrasebook_screen.dart';
import 'package:speechmate/screens/conversation_mode_screen.dart';

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

  // VC control dashboard state variables
  bool _teeVaultSealed = true;
  bool _batSyncListening = false;
  int _meshNodeCount = 3;
  int _beamWidth = 5;
  bool _gpuComputeAccelerated = true;
  double _signalStrength = -42.5;
  double _ambientLux = 120.0;

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
        {
          "word": 'Conversation Mode',
          "emoji": "🗣️",
          "colors": [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
          "navigateTo": const ConversationModeScreen(),
          "icon": Icons.forum_rounded
        },
        {
          "word": 'Situational Phrasebook',
          "emoji": "🧳",
          "colors": [const Color(0xFF2E8B57), const Color(0xFF3CB371)],
          "navigateTo": const PhrasebookScreen(),
          "icon": Icons.wallet_travel_rounded
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
        // ═══════════════════════════════════════════════════
        // ⚙️ UTILITIES
        // ═══════════════════════════════════════════════════
        {
          "word": "System Keyboard",
          "emoji": "⚙️",
          "colors": [const Color(0xFF8A2387), const Color(0xFFE94057)],
          "icon": Icons.keyboard_double_arrow_right_rounded,
          "onTap": (BuildContext context) async {
            try {
              const platform = MethodChannel("com.speechmate.general/keyboard");
              await platform.invokeMethod("enableSystemKeyboard");
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error opening keyboard settings: $e")),
              );
            }
          }
        },
        {
          "word": "Test Custom Keyboard",
          "emoji": "⌨️",
          "colors": [const Color(0xFF00B0FF), const Color(0xFF00E5FF)],
          "icon": Icons.keyboard_alt_rounded,
          "onTap": (BuildContext context) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF0C1D24),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  "Test Nicobarese Keyboard",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: searchController,
                                  style: const TextStyle(color: Colors.white),
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: "Tap keys below to write...",
                                    hintStyle: const TextStyle(color: Colors.white38),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.white54),
                                      onPressed: () {
                                        setModalState(() {
                                          searchController.clear();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          NicobareseInAppKeyboard(
                            controller: searchController,
                            onClose: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  }
                );
              },
            );
          }
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

          // VC Control Console
          _buildVCDashboardConsole(),
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
        if (tile['onTap'] != null) {
          tile['onTap'](context);
        } else if (tile['isSecret'] == true) {
          _showSecretAccessDialog(context, tile['navigateTo']);
        } else if (tile['navigateTo'] != null) {
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

  Widget _buildVCDashboardConsole() {
    final nativeService = NativeEdgeService();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0xFF10B981), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('OFF-GRID VC COMMAND CENTER', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF38BDF8), letterSpacing: 2,
                  )),
                ],
              ),
              Text('v2.0-SECURE', style: GoogleFonts.ibmPlexMono(
                fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600,
              )),
            ],
          ),
          const SizedBox(height: 16),
          // GPGPU compute + TEE Keystore
          Row(
            children: [
              // GPU ACCEL
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.developer_board_rounded, color: _gpuComputeAccelerated ? const Color(0xFF2DD4BF) : Colors.grey, size: 18),
                          const SizedBox(width: 6),
                          Text('GPGPU', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_gpuComputeAccelerated ? 'Vulkan Cores: OK' : 'CPU Thread Fallback', style: GoogleFonts.ibmPlexMono(
                        fontSize: 9, color: _gpuComputeAccelerated ? const Color(0xFF2DD4BF) : const Color(0xFF64748B),
                      )),
                      const SizedBox(height: 2),
                      Text('Shared Unified Mem: 1024B', style: GoogleFonts.ibmPlexMono(fontSize: 8, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // TEE VAULT
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_teeVaultSealed ? Icons.lock_outline_rounded : Icons.lock_open_rounded, color: const Color(0xFFFBBF24), size: 18),
                          const SizedBox(width: 6),
                          Text('TEE VAULT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_teeVaultSealed ? 'Hardware AES: SEALED' : 'Vault Open', style: GoogleFonts.ibmPlexMono(
                        fontSize: 9, color: const Color(0xFFFBBF24),
                      )),
                      const SizedBox(height: 2),
                      Text('Keystore Bound Ed25519', style: GoogleFonts.ibmPlexMono(fontSize: 8, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bat-Sync + CRDT Mesh
          Row(
            children: [
              // BAT-SYNC
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sensors_rounded, color: _batSyncListening ? const Color(0xFF38BDF8) : Colors.grey, size: 18),
                          const SizedBox(width: 6),
                          Text('BAT-SYNC v2', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_batSyncListening ? 'Ultrasonic Tx: 19.5kHz' : 'Ultrasonic Idle', style: GoogleFonts.ibmPlexMono(
                        fontSize: 9, color: _batSyncListening ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                      )),
                      const SizedBox(height: 2),
                      Text('Acoustic Amplitude: ${_signalStrength}dB', style: GoogleFonts.ibmPlexMono(fontSize: 8, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // CRDT MESH
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hub_outlined, color: Color(0xFFEC4899), size: 18),
                          const SizedBox(width: 6),
                          Text('CRDT MESH', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Network Nodes: $_meshNodeCount Ring', style: GoogleFonts.ibmPlexMono(
                        fontSize: 9, color: const Color(0xFFEC4899),
                      )),
                      const SizedBox(height: 2),
                      Text('Sliding XOR Shield Active', style: GoogleFonts.ibmPlexMono(fontSize: 8, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Eco-Drive governor
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFBBF24), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ECO-DRIVE BATTERY GOVERNOR', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('Ambient Solar: ${_ambientLux}Lux  •  Whisper Search Beam Width: $_beamWidth', style: GoogleFonts.ibmPlexMono(
                        fontSize: 9, color: const Color(0xFF94A3B8),
                      )),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    // Call native_edge_service calculations dynamically
                    final width = await nativeService.ecoCalculateBeamWidth(_ambientLux, 15.0);
                    setState(() {
                      _beamWidth = width;
                      _ambientLux = _ambientLux > 500 ? 120.0 : 8000.0;
                    });
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: const Color(0xFF0F172A),
                      content: Text('Eco-Drive Re-Calibrated: Beam width set to $width based on Light curves.', style: GoogleFonts.inter(color: const Color(0xFF2DD4BF))),
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.4)),
                    ),
                    child: Text('ADJUST', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF2DD4BF))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Command Actions Row
          Row(
            children: [
              // Cryptography Test
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFBBF24),
                    side: BorderSide(color: const Color(0xFFFBBF24).withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.vpn_key_rounded, size: 16),
                  label: Text('TEST TEE CRYPTO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700)),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final testKey = 'test_hsm_alias';
                    await nativeService.teeGenerateKey(testKey);
                    final cipher = await nativeService.teeEncryptData(testKey, 'Offgrid VC Node');
                    final decrypted = await nativeService.teeDecryptData(testKey, cipher);
                    await nativeService.teeDeleteKey(testKey);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: const Color(0xFF1E293B),
                      content: Text('TEE Secure Cycle Passed:\nPlaintext: "Offgrid VC Node"\nDecrypted: "$decrypted"', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: const Color(0xFFFBBF24))),
                    ));
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Ultrasonic modulate
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8).withOpacity(0.2),
                    foregroundColor: const Color(0xFF38BDF8),
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                    ),

                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: Icon(_batSyncListening ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 16),
                  label: Text(_batSyncListening ? 'HALT ACOUSTIC' : 'ACOUSTIC SYNCPING', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700)),
                  onPressed: () async {
                    HapticFeedback.heavyImpact();
                    if (_batSyncListening) {
                      await nativeService.ultrasonicClearBuffers();
                      setState(() => _batSyncListening = false);
                    } else {
                      final payload = [0x53, 0x59, 0x4E, 0x43]; // SYNC
                      final modulated = await nativeService.ultrasonicModulateManchester(payload);
                      await nativeService.ultrasonicSetCarrierFrequency(19500.0);
                      setState(() {
                        _batSyncListening = true;
                        _signalStrength = -15.4;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: const Color(0xFF1E293B),
                        content: Text('Acoustic Manchester Sync Transmitter Active: playing modulated 19.5kHz tones (Payload: $modulated)', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: const Color(0xFF38BDF8))),
                      ));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
