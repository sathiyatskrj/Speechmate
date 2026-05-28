import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/screens/voice_translator_screen.dart';
import 'package:speechmate/screens/ga_hub_screen.dart';
import 'package:speechmate/screens/camera_translation_screen.dart';
import 'package:speechmate/screens/dialect_comparison_screen.dart';
import 'package:speechmate/screens/culture_screen.dart';
import 'package:speechmate/screens/document_translation_hub.dart';
import 'package:speechmate/screens/feedback_screen.dart';
import 'package:speechmate/screens/about_screen.dart';
import 'package:speechmate/screens/languages.dart';
import 'package:speechmate/screens/voice_vault_screen.dart';
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/native_edge_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import 'package:speechmate/core/app_colors.dart';

// ────────────────────────────────────────────────────────────────────────────
// EXPLORER DASHBOARD — Andaman Coastal Design
// 6-zone layout: Status → Hero Strip → Quick Phrases → Word of Day → Bento → Nav
// ────────────────────────────────────────────────────────────────────────────

class ExplorerDashboard extends StatefulWidget {
  const ExplorerDashboard({super.key});

  @override
  State<ExplorerDashboard> createState() => _ExplorerDashboardState();
}

class _ExplorerDashboardState extends State<ExplorerDashboard> {
  Map<String, dynamic>? _wordOfDay;
  final TtsService _ttsService = TtsService();

  // VC control dashboard state (hidden behind developer mode)
  bool _teeVaultSealed = true;
  bool _batSyncListening = false;
  int _meshNodeCount = 3;
  int _beamWidth = 5;
  bool _gpuComputeAccelerated = true;
  double _signalStrength = -42.5;
  double _ambientLux = 120.0;
  int _versionTapCount = 0;

  final List<Map<String, dynamic>> _quickPhrases = [
    {'emoji': '👋', 'label': 'Hello', 'nicobarese': 'Musté', 'english': 'Hello', 'isEmergency': false},
    {'emoji': '🙏', 'label': 'Thank you', 'nicobarese': 'Asé', 'english': 'Thank you', 'isEmergency': false},
    {'emoji': '🗺️', 'label': 'Where is...?', 'nicobarese': 'Inta', 'english': 'Where', 'isEmergency': false},
    {'emoji': '💰', 'label': 'How much?', 'nicobarese': 'Taka-inta', 'english': 'How much', 'isEmergency': false},
    {'emoji': '🆘', 'label': 'Help!', 'nicobarese': 'Takanam', 'english': 'Help', 'isEmergency': true},
    {'emoji': '🍚', 'label': 'Water', 'nicobarese': 'Mak', 'english': 'Water', 'isEmergency': false},
    {'emoji': '🏠', 'label': 'House', 'nicobarese': 'Hīn', 'english': 'House', 'isEmergency': false},
  ];

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadWordOfDay();
  }

  Future<void> _loadWordOfDay() async {
    try {
      final words = await DatabaseManager.instance.getWordsByCategory('main');
      if (words.isNotEmpty) {
        final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
        final index = dayOfYear % words.length;
        if (mounted) setState(() => _wordOfDay = words[index]);
      }
    } catch (e) {
      debugPrint('[Explorer] Word of day error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndamanPalette.sandWhite,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Zone 1: Header + Status
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildStatusBar()),
            // Zone 2: Hero Translate Strip
            SliverToBoxAdapter(child: _buildHeroStrip()),
            // Zone 3: Quick Phrases
            SliverToBoxAdapter(child: _buildQuickPhrases()),
            // Zone 4: Word of the Day
            if (_wordOfDay != null)
              SliverToBoxAdapter(child: _buildWordOfDay()),
            // Zone 5: Bento Grid
            SliverToBoxAdapter(child: _buildSectionLabel('EXPLORE')),
            SliverToBoxAdapter(child: _buildBentoGrid()),
            SliverToBoxAdapter(child: _buildSectionLabel('DISCOVER')),
            SliverToBoxAdapter(child: _buildDiscoverGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ZONE 1: HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AndamanPalette.oceanTeal,
              boxShadow: [
                BoxShadow(color: AndamanPalette.oceanTeal.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/icons/logo_main.png', fit: BoxFit.cover,
                errorBuilder: (c, o, s) => const Icon(Icons.language, color: Colors.white, size: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SpeechMate', style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.w600, color: AndamanPalette.stone,
                )),
                Text('Explorer Edition', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w500, color: AndamanPalette.mist, letterSpacing: 0.5,
                )),
              ],
            ),
          ),
          _buildHeaderButton(Icons.settings_rounded, () => _showSettingsDialog()),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AndamanPalette.mangrove,
          shape: BoxShape.circle,
          border: Border.all(color: AndamanPalette.border, width: 1),
        ),
        child: Icon(icon, color: AndamanPalette.mist, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ZONE 1B: STATUS BAR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          // Offline ready badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AndamanPalette.emeraldSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AndamanPalette.emerald.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6,
                  decoration: const BoxDecoration(color: AndamanPalette.emerald, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Offline ready', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w500, color: AndamanPalette.emerald,
                )),
              ],
            ),
          ),
          const Spacer(),
          // Language chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AndamanPalette.oceanTealSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AndamanPalette.borderTeal),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌴', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text('Nicobarese', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w500, color: AndamanPalette.oceanTeal,
                )),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ZONE 2: HERO TRANSLATE STRIP
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          // Speak button — primary action
          Expanded(
            child: TapScale(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceTranslatorScreen()));
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AndamanPalette.oceanTeal,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AndamanPalette.oceanTeal.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text('Speak', style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white,
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Scan button — secondary action
          Expanded(
            child: TapScale(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraTranslationScreen()));
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AndamanPalette.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AndamanPalette.oceanTeal, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.document_scanner_rounded, color: AndamanPalette.oceanTeal, size: 22),
                    const SizedBox(width: 8),
                    Text('Scan', style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w500, color: AndamanPalette.oceanTeal,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ZONE 3: QUICK PHRASES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickPhrases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text('SURVIVAL PHRASES', style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: AndamanPalette.mist, letterSpacing: 1.5,
          )),
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quickPhrases.length,
            itemBuilder: (context, i) {
              final p = _quickPhrases[i];
              final isEmergency = p['isEmergency'] == true;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TapScale(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _ttsService.speakNicobarese(p['nicobarese'], englishWord: p['english']);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isEmergency ? AndamanPalette.reefCoralSoft : AndamanPalette.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isEmergency ? AndamanPalette.reefCoral.withOpacity(0.4) : AndamanPalette.border,
                        width: isEmergency ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEmergency ? Icons.warning_amber_rounded : Icons.volume_up_rounded,
                          size: 14,
                          color: isEmergency ? AndamanPalette.reefCoral : AndamanPalette.oceanTeal,
                        ),
                        const SizedBox(width: 6),
                        Text(p['label'], style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isEmergency ? FontWeight.w600 : FontWeight.w500,
                          color: isEmergency ? AndamanPalette.reefCoral : AndamanPalette.stone,
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ZONE 4: WORD OF THE DAY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWordOfDay() {
    final word = _wordOfDay!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: TapScale(
        onTap: () {
          HapticFeedback.lightImpact();
          _ttsService.speakNicobarese(
            word['nicobarese'] ?? '',
            englishWord: word['english'] ?? '',
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AndamanPalette.mangrove,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AndamanPalette.borderTeal, width: 1),
          ),
          child: Row(
            children: [
              Text(word['emoji'] ?? '🌊', style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AndamanPalette.amberSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('WORD OF THE DAY', style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w600, color: AndamanPalette.amber, letterSpacing: 1,
                      )),
                    ),
                    const SizedBox(height: 6),
                    Text(word['english'] ?? '', style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.w500, color: AndamanPalette.stone,
                    )),
                    const SizedBox(height: 2),
                    Text(word['nicobarese'] ?? '', style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w500, color: AndamanPalette.oceanTeal,
                    )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AndamanPalette.oceanTealSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volume_up_rounded, color: AndamanPalette.oceanTeal, size: 22),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.03);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ZONE 5: ASYMMETRIC BENTO GRID
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: AndamanPalette.mist, letterSpacing: 1.5,
      )),
    );
  }

  Widget _buildBentoGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: GA Hub (wide) + Dialects
          Row(children: [
            Expanded(flex: 2, child: _buildBentoCard(
              'GA Hub', 'Great Andamanese', Icons.terrain_rounded, AndamanPalette.bentoAmber, 120,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GAHubScreen())),
            )),
            const SizedBox(width: 10),
            Expanded(flex: 1, child: _buildBentoCard(
              'Dialects', null, Icons.compare_arrows_rounded, AndamanPalette.bentoPurple, 120,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DialectComparisonScreen())),
            )),
          ]),
          const SizedBox(height: 10),
          // Row 2: Voice Vault + Documents + Community
          Row(children: [
            Expanded(child: _buildBentoCard(
              'Voice\nVault', null, Icons.record_voice_over_rounded, AndamanPalette.bentoSky, 100,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceVaultScreen())),
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildBentoCard(
              'Documents', null, Icons.auto_stories_rounded, AndamanPalette.bentoEmerald, 100,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentTranslationHub())),
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildBentoCard(
              'Community', null, Icons.people_rounded, AndamanPalette.bentoCoral, 100,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())),
            )),
          ]),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildBentoCard(String title, String? subtitle, IconData icon, Color accent, double height, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AndamanPalette.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AndamanPalette.border, width: 1),
          boxShadow: [
            BoxShadow(color: AndamanPalette.shadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AndamanPalette.stone, height: 1.2,
                )),
                if (subtitle != null)
                  Text(subtitle, style: GoogleFonts.inter(
                    fontSize: 10, color: AndamanPalette.mist,
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DISCOVER GRID
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDiscoverGrid() {
    final items = [
      _DiscoverItem('Culture', Icons.auto_awesome, AndamanPalette.bentoCoral, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CultureScreen()));
      }),
      _DiscoverItem('Languages', Icons.language_rounded, AndamanPalette.bentoSky, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const Languages()));
      }),
      _DiscoverItem('Feedback', Icons.chat_bubble_outline, AndamanPalette.bentoEmerald, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
      }),
      _DiscoverItem('About', Icons.info_outline_rounded, AndamanPalette.mist, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
      }),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items.map((item) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TapScale(
              onTap: item.onTap,
              child: Container(
                height: 84,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AndamanPalette.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AndamanPalette.border, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(item.label, style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w500, color: AndamanPalette.stone,
                    ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SETTINGS DIALOG (VC Console hidden behind 5× version tap)
  // ══════════════════════════════════════════════════════════════════════════

  void _showSettingsDialog() {
    final nativeService = NativeEdgeService();
    _versionTapCount = 0; // Reset on open

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
              decoration: const BoxDecoration(
                color: AndamanPalette.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AndamanPalette.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.settings_rounded, color: AndamanPalette.stone, size: 22),
                        const SizedBox(width: 10),
                        Text('Settings', style: GoogleFonts.outfit(
                          fontSize: 20, fontWeight: FontWeight.w500, color: AndamanPalette.stone,
                        )),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AndamanPalette.mangrove,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: AndamanPalette.mist),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: AndamanPalette.border, height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _settingsTile(Icons.info_outline_rounded, 'About SpeechMate', 'Version, credits & licenses', () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                          }),
                          _settingsTile(Icons.feedback_outlined, 'Send Feedback', 'Report bugs or suggest features', () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
                          }),
                          _settingsTile(Icons.language_rounded, 'Change Language', 'Switch heritage language', () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const Languages()));
                          }),
                          const SizedBox(height: 24),
                          // Version number — 5× tap to reveal VC Console
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                _versionTapCount++;
                                if (_versionTapCount >= 5) {
                                  _versionTapCount = 0;
                                  setModalState(() {}); // Trigger rebuild to show VC
                                  HapticFeedback.heavyImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    backgroundColor: const Color(0xFF0F172A),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    content: Text('🔓 VC Command Center unlocked', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                                  ));
                                }
                              },
                              child: Text('v1.4.9 · Explorer Edition', style: GoogleFonts.inter(
                                fontSize: 11, color: AndamanPalette.mistLight,
                              )),
                            ),
                          ),
                          // VC Console — only visible after 5× tap
                          if (_versionTapCount == 0 && _vcUnlocked) ...[
                            const SizedBox(height: 16),
                            _buildVCConsole(nativeService, setModalState),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _vcUnlocked = false;

  Widget _buildVCConsole(NativeEdgeService nativeService, StateSetter setModalState) {
    _vcUnlocked = true;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.developer_board_rounded, color: Color(0xFF38BDF8), size: 18),
          ),
          title: Text('Off-Grid VC Command Center', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
          )),
          subtitle: Text('v2.0 • Advanced system controls', style: GoogleFonts.inter(
            fontSize: 10, color: const Color(0xFF64748B),
          )),
          iconColor: const Color(0xFF64748B),
          collapsedIconColor: const Color(0xFF64748B),
          children: [
            _vcInfoRow('GPGPU', _gpuComputeAccelerated ? 'Vulkan Cores: OK' : 'CPU Fallback', const Color(0xFF2DD4BF)),
            _vcInfoRow('TEE VAULT', _teeVaultSealed ? 'AES: SEALED' : 'Vault Open', const Color(0xFFFBBF24)),
            _vcInfoRow('BAT-SYNC', _batSyncListening ? 'Tx: 19.5kHz' : 'Idle', const Color(0xFF38BDF8)),
            _vcInfoRow('CRDT MESH', '$_meshNodeCount Nodes Active', const Color(0xFFEC4899)),
            _vcInfoRow('ECO-DRIVE', 'Beam Width: $_beamWidth • ${_ambientLux}Lux', const Color(0xFFFBBF24)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final testKey = 'test_hsm_alias';
                      await nativeService.teeGenerateKey(testKey);
                      final cipher = await nativeService.teeEncryptData(testKey, 'Offgrid VC Node');
                      final decrypted = await nativeService.teeDecryptData(testKey, cipher);
                      await nativeService.teeDeleteKey(testKey);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: const Color(0xFF1E293B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: Text('TEE Cycle OK: "$decrypted"', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: const Color(0xFFFBBF24))),
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBF24).withOpacity(0.15),
                      foregroundColor: const Color(0xFFFBBF24),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('TEST CRYPTO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final width = await nativeService.ecoCalculateBeamWidth(_ambientLux, 15.0);
                      setModalState(() {
                        _beamWidth = width;
                        _ambientLux = _ambientLux > 500 ? 120.0 : 8000.0;
                      });
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8).withOpacity(0.15),
                      foregroundColor: const Color(0xFF38BDF8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text('ADJUST ECO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AndamanPalette.mangrove,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AndamanPalette.stone, size: 20),
        ),
        title: Text(title, style: GoogleFonts.outfit(
          fontSize: 15, fontWeight: FontWeight.w500, color: AndamanPalette.stone,
        )),
        subtitle: Text(subtitle, style: GoogleFonts.inter(
          fontSize: 12, color: AndamanPalette.mist,
        )),
        trailing: const Icon(Icons.chevron_right_rounded, color: AndamanPalette.borderStrong, size: 20),
      ),
    );
  }

  Widget _vcInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70)),
          const Spacer(),
          Text(value, style: GoogleFonts.ibmPlexMono(fontSize: 9, color: color)),
        ],
      ),
    );
  }
}

// ────── DATA CLASSES ──────

class _DiscoverItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _DiscoverItem(this.label, this.icon, this.color, this.onTap);
}
