import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/progress_service.dart';
import 'package:speechmate/widgets/translation_card.dart';
import 'package:speechmate/widgets/smart_dashboard_header.dart';
import 'package:speechmate/core/app_theme.dart';
import 'package:speechmate/mixins/searchable_dashboard_mixin.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Screens
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/screens/dynamic_category_screen.dart';
import 'package:speechmate/screens/feedback_screen.dart';
import 'package:speechmate/screens/beta_chat_screen.dart';
import 'package:speechmate/screens/ga_hub_screen.dart';
import 'package:speechmate/screens/flora_fauna_screen.dart';
import 'package:speechmate/screens/omni_translator_screen.dart';

import 'package:speechmate/screens/story_radio_screen.dart';
import 'package:speechmate/screens/dialect_heatmap_screen.dart';
import 'package:speechmate/screens/camera_translation_screen.dart';
import 'package:speechmate/screens/voice_translator_screen.dart';
import 'package:speechmate/screens/ar_translator_screen.dart';
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
        // ═══════════════════════════════════════════════════
        // 🌐 TRANSLATION TOOLS (Top Priority for Public)
        // ═══════════════════════════════════════════════════
        {
          "word": AppStrings.get('voiceTranslate'),
          "emoji": "🎙️",
          "colors": [const Color(0xFFff0844), const Color(0xFFffb199)],
          "navigateTo": const VoiceTranslatorScreen(),
          "icon": Icons.record_voice_over_rounded
        },
        {
          "word": AppStrings.get('bookScanner'),
          "emoji": "📖",
          "colors": [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
          "navigateTo": const CameraTranslationScreen(),
          "icon": Icons.document_scanner_rounded
        },
        {
          "word": AppStrings.get('omniBroadcast'),
          "emoji": "📡",
          "colors": [const Color(0xFF1A2980), const Color(0xFF26D0CE)],
          "navigateTo": const OmniTranslatorScreen(),
          "icon": Icons.cell_tower_rounded
        },
        {
          "word": AppStrings.get('chatTranslate'),
          "emoji": "💬",
          "colors": [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
          "navigateTo": const BetaChatScreen(isStudent: true),
          "icon": Icons.chat_bubble_rounded,
        },
        {
          "word": AppStrings.get('arTranslator'),
          "emoji": "📷",
          "colors": [const Color(0xFF0F2027), const Color(0xFF2C5364)],
          "navigateTo": const ARTranslatorScreen(),
          "icon": Icons.view_in_ar_rounded
        },

        // ═══════════════════════════════════════════════════
        // 🇮🇳 REGIONAL LANGUAGE TRANSLATORS
        // ═══════════════════════════════════════════════════
        {
          "word": AppStrings.get('hindiTranslator'),
          "emoji": "🇮🇳",
          "colors": [const Color(0xFFD84315), const Color(0xFFFF7043)],
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

        // ═══════════════════════════════════════════════════
        // 🏝️ TRIBAL LANGUAGE HUBS
        // ═══════════════════════════════════════════════════
        {
          "word": AppStrings.get('andamaneseBeta'),
          "emoji": "🏝️",
          "colors": [const Color(0xFF4A148C), const Color(0xFF1A237E)],
          "navigateTo": const GAHubScreen(),
          "icon": Icons.language_rounded
        },

        // ═══════════════════════════════════════════════════
        // 🌿 CULTURAL DISCOVERY & TOURISM
        // ═══════════════════════════════════════════════════
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
          "word": AppStrings.get('islandExplorer'),
          "emoji": "🧭",
          "colors": [const Color(0xFF0277BD), const Color(0xFF01579B)],
          "navigateTo": const DialectHeatmapScreen(),
          "icon": Icons.explore_rounded,
        },
        {
          "word": AppStrings.get('community'),
          "emoji": "🌍",
          "colors": [const Color(0xFF302B63), const Color(0xFF24243E)],
          "navigateTo": const CommunityScreen(),
          "icon": Icons.public_rounded,
        },

        // ═══════════════════════════════════════════════════
        // 📚 QUICK DICTIONARY (Explore Vocabulary)
        // ═══════════════════════════════════════════════════
        {
          "word": AppStrings.get('numbers'),
          "emoji": "123",
          "colors": [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'numbers', title: 'Numbers'),
          "icon": Icons.format_list_numbered_rounded
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
          "word": AppStrings.get('nature'),
          "emoji": "🌱",
          "colors": [const Color(0xFF11998E), const Color(0xFF38EF7D)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'nature', title: 'Nature'),
          "icon": Icons.eco_rounded
        },
        {
          "word": AppStrings.get('family'),
          "emoji": "👨‍👩‍👧",
          "colors": [const Color(0xFF2193B0), const Color(0xFF6DD5ED)],
          "navigateTo": const DynamicCategoryScreen(
              categoryId: 'family', title: 'Family'),
          "icon": Icons.family_restroom_rounded
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

        // ═══════════════════════════════════════════════════
        // ⚙️ UTILITIES
        // ═══════════════════════════════════════════════════
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
          // 🎙️ Voice Waveform Visualizer
          KidsSectionHeader(emoji: '🎙️', label: AppStrings.get('sectionSoundWave')),
          const SizedBox(height: 8),
          const VoiceWaveformWidget().animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 20),

          // 🧭 Explore
          KidsSectionHeader(emoji: '🧭', label: 'Explore'),
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

// ============================================================================
// COMPETITION-GRADE ADVANCED UI COMPONENTS & ANALYTICS SUITE
// ============================================================================

// (dart:math imported at top of file)

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

class _AmbientGlassBackgroundState extends State<AmbientGlassBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _AmbientPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double progress;
  _AmbientPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient — clean white-to-ice blue
    final Rect rect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8F5FE), Color(0xFFF0FFFE), Color(0xFFE0F7FA)],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // FAST HARDWARE ACCELERATED GRADIENTS
    void drawFastGlowingOrb(double x, double y, double radius, Color color) {
      final rect = Rect.fromCircle(center: Offset(x, y), radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0.0)],
          stops: const [0.1, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    }

    // Orb 1 — Electric blue (top area)
    final double x1 =
        size.width * 0.5 + math.sin(progress * math.pi * 2) * size.width * 0.4;
    final double y1 = size.height * 0.25 +
        math.cos(progress * math.pi * 2) * size.height * 0.15;
    drawFastGlowingOrb(x1, y1, 300, const Color(0xFF00B0FF));

    // Orb 2 — Vivid teal (bottom-left)
    final double x2 = size.width * 0.2 +
        math.cos(progress * math.pi * 2 + math.pi) * size.width * 0.3;
    final double y2 = size.height * 0.75 +
        math.sin(progress * math.pi * 2 + math.pi) * size.height * 0.2;
    drawFastGlowingOrb(x2, y2, 320, const Color(0xFF00E5FF));

    // Orb 3 — Bright lime green (right side)
    final double x3 = size.width * 0.8 +
        math.sin(progress * math.pi * 2 + math.pi / 2) * size.width * 0.25;
    final double y3 = size.height * 0.5 +
        math.cos(progress * math.pi * 2 + math.pi / 2) * size.height * 0.3;
    drawFastGlowingOrb(x3, y3, 260, const Color(0xFF69F0AE));
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => oldDelegate.progress != progress;
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

class _PremiumTiltCardState extends State<PremiumTiltCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
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
    return LayoutBuilder(builder: (context, constraints) {
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
    });
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
                colors: [
                  Colors.white.withValues(alpha: 0.6),
                  Colors.white.withValues(alpha: 0.2)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("WORD OF THE DAY",
                        style: TextStyle(
                            color: Colors.purple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                  ),
                  const Spacer(),
                  const Icon(Icons.volume_up_rounded,
                      color: Colors.purpleAccent),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Pōt",
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.0)),
              const Text("Nicobarese",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.black12),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.translate_rounded,
                      size: 16, color: Colors.black54),
                  SizedBox(width: 8),
                  Text("Meaning:",
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  Text("Ocean / Sea",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold)),
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
  State<ProgressRadarChartWidget> createState() =>
      _ProgressRadarChartWidgetState();
}

class _ProgressRadarChartWidgetState extends State<ProgressRadarChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Dummy data for competition showcase presentation
  final List<double> values = [0.85, 0.60, 0.95, 0.45, 0.75];
  final List<String> labels = [
    "Nature",
    "Family",
    "Numbers",
    "Colors",
    "Animals"
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..forward();
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
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)
          ]),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarChartPainter(
              values: values,
              labels: labels,
              progress:
                  CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
                      .value,
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

  _RadarChartPainter(
      {required this.values, required this.labels, required this.progress});

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
          style: const TextStyle(
              color: Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.bold));
      final tp = TextPainter(text: labelSpan, textDirection: TextDirection.ltr)
        ..layout();

      // Calculate label offsets outside the web
      final double lx = center.dx +
          (radius + 20) * math.cos(i * angle - math.pi / 2) -
          tp.width / 2;
      final double ly = center.dy +
          (radius + 20) * math.sin(i * angle - math.pi / 2) -
          tp.height / 2;
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

      final pointPaint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      final pointBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), 4, pointBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
      {
        'title': 'First Word',
        'color': Colors.orangeAccent,
        'icon': Icons.star_rounded
      },
      {
        'title': 'Explorer',
        'color': Colors.cyanAccent,
        'icon': Icons.explore_rounded
      },
      {
        'title': '7 Day Streak',
        'color': Colors.pinkAccent,
        'icon': Icons.local_fire_department_rounded
      },
      {
        'title': 'Grammar Pro',
        'color': Colors.greenAccent,
        'icon': Icons.spellcheck_rounded
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            AppStrings.get('achievements') != 'achievements'
                ? AppStrings.get('achievements').toUpperCase()
                : "ACHIEVEMENTS",
            style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
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
                          border: Border.all(
                              color:
                                  (a['color'] as Color).withValues(alpha: 0.8),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: (a['color'] as Color)
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]),
                      child: Icon(a['icon'] as IconData,
                          color: a['color'] as Color, size: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(a['title'] as String,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        textAlign: TextAlign.center,
                        maxLines: 2),
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

class _DailyMissionCardState extends State<DailyMissionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  double _progress = 0.0;
  late Map<String, dynamic> _todaysMission;

  @override
  void initState() {
    super.initState();
    _shimmer =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _todaysMission = SmartMissionEngine.getTodaysMission();
    _loadRealProgress();
  }

  Future<void> _loadRealProgress() async {
    final progressService = ProgressService();
    final stats = await progressService.getProgressStats();
    final wordsLearned = stats['wordsLearned'] ?? 0;
    final target = _todaysMission['target'] as int;
    if (mounted) {
      setState(() {
        _progress = (wordsLearned / target).clamp(0.0, 1.0);
      });
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int xpReward = _todaysMission['xp'];
    final String missionText = _todaysMission['text'];
    final int target = _todaysMission['target'];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(AppStrings.get('dailyMission'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _shimmer,
                  builder: (ctx, _) => Text(
                    '+$xpReward ⭐',
                    style: TextStyle(
                      color: Colors.white
                          .withValues(alpha: 0.7 + 0.3 * _shimmer.value),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              missionText,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.get('missionHint'),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
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
                Text('${(_progress * target).round()} / $target',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text('${(_progress * 100).round()}% ${AppStrings.get('percentDone')}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 2. Quick Stats Row (Streak 🔥, Stars ⭐, Level 🏅)
// ----------------------------------------------------------------------------
/// Three colourful bubble-cards showing a student's key stats at a glance.
class QuickStatsRow extends StatefulWidget {
  const QuickStatsRow({super.key});

  @override
  State<QuickStatsRow> createState() => _QuickStatsRowState();
}

class _QuickStatsRowState extends State<QuickStatsRow> {
  int _streak = 0;
  int _stars = 0;
  String _levelName = 'Seedling';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final progressService =
        ProgressService(); // Must import 'package:speechmate/services/progress_service.dart' if not already
    final stats = await progressService.getProgressStats();
    final xpInfo = StudentXPEngine.getLevelInfo(stats['studentXP'] ?? 0);

    if (mounted) {
      setState(() {
        _streak = stats['dayStreak'] ?? 0;
        _stars = stats['studentStars'] ?? 0;
        _levelName = xpInfo['name'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
          height: 80,
          child: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent)));
    }

    return Row(
      children: [
        _buildStatBubble(
            emoji: '🔥',
            label: AppStrings.get('streakLabel'),
            value: '$_streak ${AppStrings.get('days')}',
            color: const Color(0xFFFF6B35)),
        const SizedBox(width: 12),
        _buildStatBubble(
            emoji: '⭐',
            label: AppStrings.get('starsLabel'),
            value: '$_stars',
            color: const Color(0xFFFFD700)),
        const SizedBox(width: 12),
        _buildStatBubble(
            emoji: '🏅',
            label: AppStrings.get('levelLabel'),
            value: _levelName,
            color: const Color(0xFF7B61FF)),
      ],
    );
  }

  Widget _buildStatBubble(
      {required String emoji,
      required String label,
      required String value,
      required Color color}) {
    // NO BackdropFilter here — 3 stacked blurs destroy mobile perf
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
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
  const KidsSectionHeader(
      {super.key, required this.emoji, required this.label});

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
              gradient: const LinearGradient(
                  colors: [Colors.black12, Colors.transparent]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// 4. Fun Virtual Companion for Kids (Tamagotchi-Inspired)
// ----------------------------------------------------------------------------
/// An interactive virtual pet with mood states, hunger/energy stats,
/// XP-driven evolution, dynamic behaviors, and speech bubbles.
/// Inspired by Study Buddy, Catode32, Codachi, and Tamagotchi.
class VirtualPetCompanion extends StatefulWidget {
  final VoidCallback? onPetHappy;
  const VirtualPetCompanion({super.key, this.onPetHappy});

  @override
  State<VirtualPetCompanion> createState() => _VirtualPetCompanionState();
}

/// Pet mood determined by stats
enum PetMood { happy, neutral, hungry, sleepy, excited, sick }

/// Evolution stage driven by XP
enum PetStage { egg, baby, teen, adult, legendary }

class _VirtualPetCompanionState extends State<VirtualPetCompanion>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _heartController;
  final TtsService _ttsService = TtsService();
  final math.Random _rng = math.Random();

  // ── Tamagotchi Stats (0–100) ──
  double _happiness = 70;
  double _hunger = 60;   // 100 = full, 0 = starving
  double _energy = 80;

  // ── Evolution ──
  int _petXP = 0;
  PetStage _stage = PetStage.baby;

  // ── Mood & Behavior ──
  PetMood _mood = PetMood.neutral;
  String _currentBehavior = 'idle';
  bool _showSpeech = false;
  String _speechText = '';
  bool _showHearts = false;
  bool _showZzz = false;
  int _tapCount = 0;

  // ── Pet identity ──
  int _petIndex = 0;

  // Evolution stages: each stage has its own set of animals
  static const List<List<String>> _stageAnimals = [
    ['🥚'],                                        // egg
    ['🐣', '🐥', '🐤'],                             // baby
    ['🦊', '🐶', '🐱', '🐰', '🐹'],                 // teen
    ['🐯', '🦁', '🐼', '🐨', '🦝', '🐺'],           // adult
    ['🦄', '🐉', '🦅', '🐬', '🦩', '🦋', '🌟'],     // legendary
  ];

  static const List<Color> _stageColors = [
    Color(0xFF9E9E9E),   // egg - gray
    Color(0xFFFFB74D),   // baby - warm orange
    Color(0xFFEC407A),   // teen - pink
    Color(0xFF7C4DFF),   // adult - purple
    Color(0xFFFFD700),   // legendary - gold
  ];

  // ── Speech lines per mood ──
  List<String> get _moodSpeechLines {
    switch (_mood) {
      case PetMood.happy:
        return [AppStrings.get('petHappySpeech'), '🎉 Woohoo!', '💖 Love you!', '✨ Amazing!'];
      case PetMood.hungry:
        return ['🍕 Feed me!', '😋 Hungry...', '🍎 Snack time?'];
      case PetMood.sleepy:
        return ['😴 So tired...', '💤 Zzz...', '🌙 Nap time?'];
      case PetMood.excited:
        return ['🚀 Let\'s GO!', '⚡ ZOOMIES!', '🎮 Play time!'];
      case PetMood.sick:
        return ['🤒 Not great...', '💊 Need rest...'];
      case PetMood.neutral:
        return [AppStrings.get('petHappySpeech'), '👋 Hi there!', '🌈 Nice day!'];
    }
  }

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _bounceController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _heartController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _loadPetState();
    _startLifecycleLoop();
  }

  /// Load XP from ProgressService to determine evolution stage
  Future<void> _loadPetState() async {
    final stats = await ProgressService().getProgressStats();
    final totalXP = (stats['wordsLearned'] ?? 0) * 10;
    if (mounted) {
      setState(() {
        _petXP = totalXP;
        _stage = _calculateStage(totalXP);
        _updateMood();
      });
    }
  }

  PetStage _calculateStage(int xp) {
    if (xp >= 500) return PetStage.legendary;
    if (xp >= 200) return PetStage.adult;
    if (xp >= 50) return PetStage.teen;
    if (xp >= 10) return PetStage.baby;
    return PetStage.egg;
  }

  /// Passive stat decay every 30s (Tamagotchi lifecycle)
  void _startLifecycleLoop() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      setState(() {
        _hunger = (_hunger - 2).clamp(0, 100);
        _energy = (_energy - 1).clamp(0, 100);
        if (_hunger < 30) _happiness = (_happiness - 3).clamp(0, 100);
        _updateMood();
        _pickAutoBehavior();
      });
      return mounted;
    });
  }

  void _updateMood() {
    if (_hunger < 20) {
      _mood = PetMood.hungry;
    } else if (_energy < 20) {
      _mood = PetMood.sleepy;
    } else if (_happiness < 25) {
      _mood = PetMood.sick;
    } else if (_happiness > 85) {
      _mood = PetMood.excited;
    } else if (_happiness > 55) {
      _mood = PetMood.happy;
    } else {
      _mood = PetMood.neutral;
    }
  }

  /// Auto-behaviors inspired by Catode32
  void _pickAutoBehavior() {
    if (_energy < 15) {
      _currentBehavior = 'sleeping';
      _showZzz = true;
    } else if (_hunger < 20) {
      _currentBehavior = 'begging';
    } else if (_happiness > 90 && _rng.nextDouble() > 0.7) {
      _currentBehavior = 'zoomies';
    } else {
      _currentBehavior = 'idle';
      _showZzz = false;
    }
  }

  /// Feed the pet (long press)
  void _feedPet() {
    _ttsService.speakEnglish('Yummy!');
    setState(() {
      _hunger = (_hunger + 25).clamp(0, 100);
      _happiness = (_happiness + 10).clamp(0, 100);
      _currentBehavior = 'eating';
      _speechText = '😋 Yummy!';
      _showSpeech = true;
      _updateMood();
    });
    _hideSpeechAfterDelay();
  }

  /// Pet/play interaction (tap)
  void _petInteraction() {
    _tapCount++;
    if (widget.onPetHappy != null) widget.onPetHappy!();

    // Gain XP from interaction
    _petXP += 5;
    final newStage = _calculateStage(_petXP);
    final evolved = newStage != _stage;

    setState(() {
      _happiness = (_happiness + 15).clamp(0, 100);
      _energy = (_energy - 3).clamp(0, 100);
      _stage = newStage;
      _petIndex = (_petIndex + 1) % _stageAnimals[_stage.index].length;
      _updateMood();

      if (evolved) {
        _speechText = '🎉 I EVOLVED!';
        _ttsService.speakEnglish('I evolved! Look at me!');
      } else {
        final lines = _moodSpeechLines;
        _speechText = lines[_rng.nextInt(lines.length)];
        _ttsService.speakEnglish(_speechText);
      }
      _showSpeech = true;
      _showHearts = true;
      _currentBehavior = _tapCount % 5 == 0 ? 'zoomies' : 'playing';
    });

    // Trigger heart animation
    _heartController.forward(from: 0);

    // Bounce faster during interaction
    _bounceController.duration = const Duration(milliseconds: 250);
    _bounceController.repeat(reverse: true);

    _hideSpeechAfterDelay();
  }

  void _hideSpeechAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSpeech = false;
          _showHearts = false;
          _showZzz = false;
          _currentBehavior = 'idle';
        });
        _bounceController.duration = const Duration(seconds: 2);
        _bounceController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _heartController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColors[_stage.index];
    final animals = _stageAnimals[_stage.index];
    final currentAnimal = animals[_petIndex % animals.length];
    final bounceHeight = _currentBehavior == 'zoomies' ? 25.0 : 15.0;

    return Positioned(
      bottom: 20,
      right: 20,
      child: GestureDetector(
        onTap: _petInteraction,
        onLongPress: _feedPet,
        child: AnimatedBuilder(
          animation: _bounceController,
          builder: (context, child) {
            final dx = _currentBehavior == 'zoomies'
                ? math.sin(_bounceController.value * math.pi * 4) * 8
                : 0.0;
            return Transform.translate(
              offset: Offset(dx,
                  -bounceHeight * Curves.easeInOutSine.transform(_bounceController.value)),
              child: child,
            );
          },
          child: SizedBox(
            width: 120,
            height: 140,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // ── Speech Bubble ──
                if (_showSpeech)
                  Positioned(
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Text(_speechText,
                          style: TextStyle(color: stageColor, fontWeight: FontWeight.bold, fontSize: 11),
                          textAlign: TextAlign.center),
                    ).animate().scale(curve: Curves.elasticOut),
                  ),

                // ── Floating Hearts ──
                if (_showHearts)
                  ...List.generate(3, (i) => Positioned(
                    bottom: 60 + i * 15.0,
                    right: 10 + i * 12.0,
                    child: AnimatedBuilder(
                      animation: _heartController,
                      builder: (_, __) => Opacity(
                        opacity: (1 - _heartController.value).clamp(0, 1),
                        child: Transform.translate(
                          offset: Offset(0, -30 * _heartController.value),
                          child: const Text('❤️', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  )),

                // ── Zzz for sleeping ──
                if (_showZzz)
                  Positioned(
                    top: 15,
                    right: 5,
                    child: const Text('💤', style: TextStyle(fontSize: 20))
                        .animate(onPlay: (c) => c.repeat())
                        .fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms),
                  ),

                // ── Pet Body ──
                Positioned(
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pet avatar
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: stageColor.withValues(alpha: 0.5),
                              blurRadius: _currentBehavior == 'zoomies' ? 30 : 20,
                              spreadRadius: _currentBehavior == 'zoomies' ? 5 : 0,
                              offset: const Offset(0, 8),
                            )
                          ],
                          border: Border.all(color: stageColor, width: 3),
                        ),
                        child: Center(
                          child: Text(currentAnimal,
                              style: const TextStyle(fontSize: 44)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // ── Mini stat bars ──
                      SizedBox(
                        width: 70,
                        child: Column(
                          children: [
                            _buildMiniBar('❤️', _happiness, Colors.pinkAccent),
                            const SizedBox(height: 2),
                            _buildMiniBar('🍕', _hunger, Colors.orangeAccent),
                            const SizedBox(height: 2),
                            _buildMiniBar('⚡', _energy, Colors.cyan),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Stage badge ──
                Positioned(
                  bottom: 70,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: stageColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _stage.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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

  Widget _buildMiniBar(String emoji, double value, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 8)),
        const SizedBox(width: 2),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                value < 25 ? Colors.redAccent : color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ENGINE 1: Student XP & Leveling Engine
// ============================================================================
/// Lightweight progression engine that calculates XP, levels, and streaks.
/// All computation is O(1) — no loops, no heavy allocations.
class StudentXPEngine {
  // XP thresholds for each level (exponential curve)
  static const List<int> _levelThresholds = [
    0,
    50,
    150,
    350,
    700,
    1200,
    2000,
    3200,
    5000,
    8000,
    12000
  ];

  static const List<String> _levelNames = [
    'Seedling',
    'Sprout',
    'Explorer',
    'Adventurer',
    'Pathfinder',
    'Discoverer',
    'Scholar',
    'Champion',
    'Master',
    'Legend',
    'Elder'
  ];

  static const List<String> _levelEmojis = [
    '🌱',
    '🌿',
    '🧭',
    '⚔️',
    '🗺️',
    '🔭',
    '📚',
    '🏆',
    '👑',
    '⭐',
    '🌟'
  ];

  /// Gets the current level info from total XP (O(1) binary-search style)
  static Map<String, dynamic> getLevelInfo(int totalXP) {
    int level = 0;
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (totalXP >= _levelThresholds[i]) {
        level = i;
        break;
      }
    }

    final int currentThreshold = _levelThresholds[level];
    final int nextThreshold = level < _levelThresholds.length - 1
        ? _levelThresholds[level + 1]
        : _levelThresholds[level] + 5000;

    final double progressToNext =
        (totalXP - currentThreshold) / (nextThreshold - currentThreshold);

    return {
      'level': level,
      'name': _levelNames[level.clamp(0, _levelNames.length - 1)],
      'emoji': _levelEmojis[level.clamp(0, _levelEmojis.length - 1)],
      'totalXP': totalXP,
      'xpForNext': nextThreshold - totalXP,
      'progress': progressToNext.clamp(0.0, 1.0),
    };
  }

  /// Calculates XP reward for an action with streak multiplier
  static int calculateReward({
    required String action,
    int streakDays = 0,
  }) {
    // Base XP values per action type
    int baseXP;
    switch (action) {
      case 'translate_word':
        baseXP = 10;
        break;
      case 'ar_scan':
        baseXP = 25;
        break;
      case 'voice_record':
        baseXP = 30;
        break;
      case 'complete_game':
        baseXP = 50;
        break;
      case 'daily_mission':
        baseXP = 100;
        break;
      default:
        baseXP = 5;
    }

    // Streak multiplier: +5% per day, capped at 2x
    final double streakMultiplier = 1.0 + (streakDays * 0.05).clamp(0.0, 1.0);
    return (baseXP * streakMultiplier).round();
  }
}

// ============================================================================
// ENGINE 2: Lightweight Confetti Celebration Engine
// ============================================================================
/// A performance-safe confetti particle system using a single CustomPainter.
/// Max 25 particles, no blur, no shadows — pure rect/circle drawing.
class ConfettiOverlay extends StatefulWidget {
  final bool trigger;
  const ConfettiOverlay({super.key, required this.trigger});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_ConfettiParticle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _particles.clear();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger) {
      _spawnParticles();
    }
  }

  void _spawnParticles() {
    _particles = List.generate(
        25,
        (_) => _ConfettiParticle(
              x: _rng.nextDouble(),
              y: -0.1 - _rng.nextDouble() * 0.3,
              vx: (_rng.nextDouble() - 0.5) * 0.3,
              vy: 0.3 + _rng.nextDouble() * 0.5,
              rotation: _rng.nextDouble() * math.pi * 2,
              rotationSpeed: (_rng.nextDouble() - 0.5) * 6,
              size: 6 + _rng.nextDouble() * 8,
              color: [
                const Color(0xFFFF6B6B),
                const Color(0xFFFFD93D),
                const Color(0xFF6BCB77),
                const Color(0xFF4D96FF),
                const Color(0xFFFF6BFF),
                const Color(0xFFFF9A3C),
              ][_rng.nextInt(6)],
            ));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_particles.isEmpty) return const SizedBox.shrink();
          return RepaintBoundary(
            child: CustomPaint(
              painter: _ConfettiPainter(_particles, _controller.value),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  double x, y, vx, vy, rotation, rotationSpeed, size;
  Color color;
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final double fade = t > 0.7 ? (1.0 - t) / 0.3 : 1.0; // Fade out in last 30%

    for (final p in particles) {
      final double px = (p.x + p.vx * t) * size.width;
      final double py = (p.y + p.vy * t + 0.5 * t * t) * size.height; // Gravity
      final double rot = p.rotation + p.rotationSpeed * t;

      paint.color = p.color.withValues(alpha: fade * 0.9);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

// ============================================================================
// ENGINE 3: Smart Daily Mission Engine (Lightweight SRS)
// ============================================================================
/// Generates personalized daily missions based on what the child hasn't
/// practiced recently. Uses a simple staleness score — no heavy computation.
class SmartMissionEngine {
  /// Mission text keys for localization
  static const List<String> _missionTextKeys = [
    'missionLearnWords',
    'missionPlayGames',
    'missionScanAR',
    'missionRecordVoice',
    'missionBodyQuiz',
    'missionAnimals',
    'missionNature',
    'missionNumbers',
    'missionStories',
    'missionColors',
  ];

  /// Pre-defined mission templates (targets and XP)
  static const List<Map<String, dynamic>> _missionTemplates = [
    {'target': 5, 'xp': 50, 'category': 'vocabulary', 'emoji': '📖'},
    {'target': 2, 'xp': 40, 'category': 'games', 'emoji': '🎮'},
    {'target': 3, 'xp': 60, 'category': 'ar', 'emoji': '📷'},
    {'target': 3, 'xp': 45, 'category': 'voice', 'emoji': '🎤'},
    {'target': 1, 'xp': 35, 'category': 'quiz', 'emoji': '🦴'},
    {'target': 4, 'xp': 40, 'category': 'animals', 'emoji': '🐾'},
    {'target': 3, 'xp': 35, 'category': 'nature', 'emoji': '🌿'},
    {'target': 5, 'xp': 30, 'category': 'numbers', 'emoji': '🔢'},
    {'target': 1, 'xp': 55, 'category': 'stories', 'emoji': '📻'},
    {'target': 4, 'xp': 35, 'category': 'colors', 'emoji': '🎨'},
  ];

  /// Picks today's mission deterministically from the day-of-year.
  /// Same mission all day, different tomorrow. No storage needed.
  static Map<String, dynamic> getTodaysMission() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _missionTemplates.length;
    final template = Map<String, dynamic>.from(_missionTemplates[index]);
    // Resolve localized text at runtime
    template['text'] = AppStrings.get(_missionTextKeys[index]);
    return template;
  }

  /// Calculates a staleness score for each category based on
  /// simulated last-practice timestamps. Higher = needs more practice.
  static Map<String, double> getCategoryStaleness() {
    // In production, these would come from local storage.
    // For demo, we simulate varied staleness.
    final now = DateTime.now();
    final rng = math.Random(now.day);
    final categories = [
      'vocabulary',
      'games',
      'ar',
      'voice',
      'quiz',
      'animals',
      'nature',
      'numbers',
      'stories',
      'colors'
    ];
    return Map.fromEntries(
        categories.map((c) => MapEntry(c, rng.nextDouble())));
  }
}

// ============================================================================
// ENGINE 4: Voice Waveform Visualizer (Lightweight Canvas)
// ============================================================================
/// A smooth, animated audio waveform that can respond to mock amplitude data.
/// Uses a single CustomPainter with only ~20 bars — no FFT, no heavy math.
class VoiceWaveformWidget extends StatefulWidget {
  const VoiceWaveformWidget({super.key});

  @override
  State<VoiceWaveformWidget> createState() => _VoiceWaveformWidgetState();
}

class _VoiceWaveformWidgetState extends State<VoiceWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _WaveformPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double t;
  _WaveformPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const int barCount = 20;
    final double barWidth = size.width / (barCount * 2);
    final double maxHeight = size.height * 0.8;
    final double centerY = size.height / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      // Smooth sine-wave animation: each bar has a phase offset
      final double phase = i * 0.3 + t * math.pi * 2;
      final double amplitude = (math.sin(phase) * 0.5 + 0.5) * maxHeight * 0.5;
      final double x = (i * 2 + 0.5) * barWidth;

      // Gradient colour from cyan to purple based on position
      final double ratio = i / barCount;
      paint.color = Color.lerp(
        const Color(0xFF00BCD4), // Cyan
        const Color(0xFF9C27B0), // Purple
        ratio,
      )!
          .withValues(alpha: 0.7);

      // Draw symmetric bar from center
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(x, centerY),
            width: barWidth * 0.8,
            height: amplitude + 4),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) => old.t != t;
}
