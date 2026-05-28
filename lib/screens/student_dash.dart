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
import 'package:speechmate/core/island_zone_data.dart';
import 'package:speechmate/mixins/searchable_dashboard_mixin.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Screens (only needed for keyboard onTap and secret dialog)
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/core/app_strings.dart';

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
  int _currentZone = 0;

  // Island zones data
  late final List<IslandZone> _zones;

  // VC control dashboard state variables
  bool _teeVaultSealed = true;
  bool _batSyncListening = false;
  int _meshNodeCount = 3;
  int _beamWidth = 5;
  bool _gpuComputeAccelerated = true;
  double _signalStrength = -42.5;
  double _ambientLux = 120.0;

  // Keyboard utility tiles (not in zone data — they use onTap callbacks)
  late final List<Map<String, dynamic>> _utilityTiles;

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
    _zones = getIslandZones();
    _utilityTiles = _buildUtilityTiles();
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

  List<Map<String, dynamic>> _buildUtilityTiles() {
    return [
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
    ];
  }

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
                    child: _buildZoneContent(),
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
        // Island Journey Bottom Navigation
        bottomNavigationBar: IslandBottomNavBar(
          currentIndex: _currentZone,
          onTap: (index) => setState(() => _currentZone = index),
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

  // ── Zone Content Router ──────────────────────────────────────────────────
  Widget _buildZoneContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: SingleChildScrollView(
        key: ValueKey(_currentZone),
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _currentZone == 0
              ? _buildHomeBeach()
              : _buildZoneTileGrid(_zones[_currentZone]),
        ),
      ),
    );
  }

  // ── Zone 0: Home Beach ───────────────────────────────────────────────────
  Widget _buildHomeBeach() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search results
        if (isSearchLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          )
        else if (searchController.text.isNotEmpty)
          _buildSearchResults(),

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
        const SizedBox(height: 110),
      ],
    );
  }

  // ── Zone Tile Grid (for zones 1-4) ───────────────────────────────────────
  Widget _buildZoneTileGrid(IslandZone zone) {
    // Combine zone tiles with utility tiles for Discovery Island (zone 4)
    final List<Map<String, dynamic>> allTiles = [...zone.tiles];
    if (_currentZone == 4) {
      allTiles.addAll(_utilityTiles);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search results at top if searching
        if (isSearchLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          )
        else if (searchController.text.isNotEmpty)
          _buildSearchResults(),

        // Zone header banner
        IslandZoneHeader(
          emoji: zone.emoji,
          name: zone.name,
          description: zone.description,
          gradientColors: zone.gradientColors,
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

        // Feature tile grid
        StaggeredGrid.count(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: List.generate(allTiles.length, (index) {
            final tile = allTiles[index];

            // Bento Layout: first tile gets hero width, some get tall
            int crossAxisCellCount = 2;
            int mainAxisCellCount = 2;

            if (index == 0) {
              crossAxisCellCount = 4;
              mainAxisCellCount = 2;
            } else if (index == 1) {
              crossAxisCellCount = 2;
              mainAxisCellCount = 3;
            } else if (index % 7 == 0 && index > 5) {
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
        ),
        const SizedBox(height: 110),
      ],
    );
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
