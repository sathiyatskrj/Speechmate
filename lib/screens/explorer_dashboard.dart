import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/screens/voice_translator_screen.dart';
import 'package:speechmate/screens/chat_translate_screen.dart';
import 'package:speechmate/screens/ga_hub_screen.dart';
import 'package:speechmate/screens/ar_translator_screen.dart';
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

// ────── DUOLINGO-STYLE VIBRANT LIGHT PALETTE ──────
class _DuoColors {
  static const bg = Color(0xFFF7F7F7);
  static const white = Color(0xFFFFFFFF);
  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF4CAD00);
  static const blue = Color(0xFF1CB0F6);
  static const purple = Color(0xFFCE82FF);
  static const red = Color(0xFFFF4B4B);
  static const orange = Color(0xFFFF9600);
  static const yellow = Color(0xFFFFC800);
  static const teal = Color(0xFF00CD9C);
  static const textDark = Color(0xFF3C3C3C);
  static const textMuted = Color(0xFF777777);
  static const border = Color(0xFFE5E5E5);
  static const cardShadow = Color(0x14000000);
}

class ExplorerDashboard extends StatefulWidget {
  const ExplorerDashboard({super.key});

  @override
  State<ExplorerDashboard> createState() => _ExplorerDashboardState();
}

class _ExplorerDashboardState extends State<ExplorerDashboard> {
  Map<String, dynamic>? _wordOfDay;
  final TtsService _ttsService = TtsService();

  // VC control dashboard state (moved to settings dialog)
  bool _teeVaultSealed = true;
  bool _batSyncListening = false;
  int _meshNodeCount = 3;
  int _beamWidth = 5;
  bool _gpuComputeAccelerated = true;
  double _signalStrength = -42.5;
  double _ambientLux = 120.0;

  final List<Map<String, dynamic>> _quickPhrases = [
    {'emoji': '👋', 'label': 'Hello', 'nicobarese': 'Musté', 'english': 'Hello'},
    {'emoji': '🍚', 'label': 'Water', 'nicobarese': 'Mak', 'english': 'Water'},
    {'emoji': '🗺️', 'label': 'Where', 'nicobarese': 'Inta', 'english': 'Where'},
    {'emoji': '🆘', 'label': 'Help', 'nicobarese': 'Takanam', 'english': 'Help'},
    {'emoji': '🙏', 'label': 'Thanks', 'nicobarese': 'Asé', 'english': 'Thank you'},
    {'emoji': '🏠', 'label': 'House', 'nicobarese': 'Hīn', 'english': 'House'},
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
      backgroundColor: _DuoColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildStreakBar()),
            if (_wordOfDay != null)
              SliverToBoxAdapter(child: _buildWordOfDay()),
            SliverToBoxAdapter(child: _buildQuickPhrases()),
            SliverToBoxAdapter(child: _buildSectionLabel('EXPLORER TOOLS')),
            SliverToBoxAdapter(child: _buildToolsGrid()),
            SliverToBoxAdapter(child: _buildSectionLabel('DISCOVER')),
            SliverToBoxAdapter(child: _buildDiscoverGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ────── HEADER ──────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          // Logo
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _DuoColors.green,
              boxShadow: [
                BoxShadow(color: _DuoColors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/icons/logo_main.png', fit: BoxFit.cover,
                errorBuilder: (c, o, s) => const Icon(Icons.language, color: Colors.white, size: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SpeechMate', style: GoogleFonts.outfit(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _DuoColors.textDark,
                )),
                Text('Explorer Edition', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _DuoColors.textMuted, letterSpacing: 1.5,
                )),
              ],
            ),
          ),
          // Settings gear (contains VC Command Center)
          _buildHeaderButton(Icons.settings_rounded, () => _showSettingsDialog()),
          const SizedBox(width: 8),
          _buildHeaderButton(Icons.info_outline_rounded, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _DuoColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _DuoColors.border, width: 2),
          boxShadow: const [BoxShadow(color: _DuoColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Icon(icon, color: _DuoColors.textMuted, size: 20),
      ),
    );
  }

  // ────── STREAK / GAMIFICATION BAR ──────
  Widget _buildStreakBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          // Offline badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _DuoColors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _DuoColors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: _DuoColors.green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Fully Offline', style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _DuoColors.green,
                )),
              ],
            ),
          ),
          const Spacer(),
          // Nicobarese tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_DuoColors.orange, _DuoColors.yellow]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌴', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('Nicobarese', style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                )),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ────── WORD OF THE DAY ──────
  Widget _buildWordOfDay() {
    final word = _wordOfDay!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: TapScale(
        onTap: () {
          _ttsService.speakNicobarese(
            word['nicobarese'] ?? '',
            englishWord: word['english'] ?? '',
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _DuoColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _DuoColors.border, width: 2),
            boxShadow: const [BoxShadow(color: _DuoColors.cardShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              Text(word['emoji'] ?? '🌊', style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _DuoColors.yellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('WORD OF THE DAY', style: GoogleFonts.outfit(
                        fontSize: 9, fontWeight: FontWeight.w800, color: _DuoColors.orange, letterSpacing: 1.5,
                      )),
                    ),
                    const SizedBox(height: 6),
                    Text(word['english'] ?? '', style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.w800, color: _DuoColors.textDark,
                    )),
                    Text(word['nicobarese'] ?? '', style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600, color: _DuoColors.teal,
                    )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _DuoColors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volume_up_rounded, color: _DuoColors.blue, size: 24),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  // ────── QUICK SURVIVAL PHRASES ──────
  Widget _buildQuickPhrases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text('SURVIVAL PHRASES', style: GoogleFonts.outfit(
            fontSize: 12, fontWeight: FontWeight.w800, color: _DuoColors.textMuted, letterSpacing: 2,
          )),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quickPhrases.length,
            itemBuilder: (context, i) {
              final p = _quickPhrases[i];
              final colors = [
                _DuoColors.green, _DuoColors.blue, _DuoColors.purple,
                _DuoColors.red, _DuoColors.orange, _DuoColors.teal,
              ];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TapScale(
                  onTap: () {
                    _ttsService.speakNicobarese(p['nicobarese'], englishWord: p['english']);
                  },
                  child: Container(
                    width: 115,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _DuoColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors[i % colors.length].withOpacity(0.3), width: 2),
                      boxShadow: const [BoxShadow(color: _DuoColors.cardShadow, blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${p['emoji']} ${p['label']}', style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _DuoColors.textDark,
                        )),
                        const SizedBox(height: 4),
                        Text('${p['nicobarese']}', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: colors[i % colors.length],
                        )),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (150 + i * 60).ms).slideX(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }

  // ────── SECTION LABEL ──────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(label, style: GoogleFonts.outfit(
        fontSize: 13, fontWeight: FontWeight.w800, color: _DuoColors.textMuted, letterSpacing: 2.5,
      )),
    );
  }

  // ────── TOOLS BENTO GRID (Duolingo-style) ──────
  Widget _buildToolsGrid() {
    final tools = [
      _ToolItem('Voice\nTranslate', Icons.mic_rounded, _DuoColors.green, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceTranslatorScreen()));
      }),
      _ToolItem('Text\nTranslate', Icons.translate_rounded, _DuoColors.blue, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatTranslateScreen()));
      }),
      _ToolItem('GA Hub', Icons.terrain_rounded, _DuoColors.orange, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GAHubScreen()));
      }),
      _ToolItem('AR Scan', Icons.camera_alt_rounded, _DuoColors.purple, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ARTranslatorScreen()));
      }),
      _ToolItem('Dialects', Icons.compare_arrows_rounded, _DuoColors.yellow, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DialectComparisonScreen()));
      }),
      _ToolItem('Documents', Icons.auto_stories_rounded, _DuoColors.teal, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentTranslationHub()));
      }),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Voice (wide) + Text
          Row(children: [
            Expanded(flex: 2, child: _buildToolCard(tools[0], height: 130)),
            const SizedBox(width: 10),
            Expanded(flex: 1, child: _buildToolCard(tools[1], height: 130)),
          ]),
          const SizedBox(height: 10),
          // Row 2: GA + AR + Dialects
          Row(children: [
            Expanded(child: _buildToolCard(tools[2], height: 110)),
            const SizedBox(width: 10),
            Expanded(child: _buildToolCard(tools[3], height: 110)),
            const SizedBox(width: 10),
            Expanded(child: _buildToolCard(tools[4], height: 110)),
          ]),
          const SizedBox(height: 10),
          // Row 3: Documents (wide)
          _buildToolCard(tools[5], height: 85, fullWidth: true),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildToolCard(_ToolItem item, {required double height, bool fullWidth = false}) {
    return TapScale(
      onTap: item.onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DuoColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: item.color.withOpacity(0.25), width: 2.5),
          boxShadow: [
            BoxShadow(color: item.color.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 5)),
            const BoxShadow(color: _DuoColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            Text(item.label, style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w700, color: _DuoColors.textDark, height: 1.2,
            )),
          ],
        ),
      ),
    );
  }

  // ────── DISCOVER GRID ──────
  Widget _buildDiscoverGrid() {
    final items = [
      _DiscoverItem('Culture Hub', Icons.auto_awesome, _DuoColors.red, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CultureScreen()));
      }),
      _DiscoverItem('Voice Vault', Icons.record_voice_over, _DuoColors.purple, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceVaultScreen()));
      }),
      _DiscoverItem('Languages', Icons.language_rounded, _DuoColors.blue, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const Languages()));
      }),
      _DiscoverItem('Feedback', Icons.chat_bubble_outline, _DuoColors.green, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
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
                height: 95,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _DuoColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: item.color.withOpacity(0.2), width: 2),
                  boxShadow: const [BoxShadow(color: _DuoColors.cardShadow, blurRadius: 8, offset: Offset(0, 3))],
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
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(item.label, style: GoogleFonts.outfit(
                      fontSize: 11, fontWeight: FontWeight.w700, color: _DuoColors.textDark,
                    ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ────── SETTINGS DIALOG (VC Command Center moved here) ──────
  void _showSettingsDialog() {
    final nativeService = NativeEdgeService();
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
                color: _DuoColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: _DuoColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.settings_rounded, color: _DuoColors.textDark, size: 24),
                        const SizedBox(width: 10),
                        Text('Settings & System', style: GoogleFonts.outfit(
                          fontSize: 20, fontWeight: FontWeight.w800, color: _DuoColors.textDark,
                        )),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _DuoColors.bg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 18, color: _DuoColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: _DuoColors.border),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // General settings
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
                          const SizedBox(height: 16),
                          // VC Command Center — collapsed expandable
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(20),
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
                          ),
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

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _DuoColors.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _DuoColors.textDark, size: 20),
        ),
        title: Text(title, style: GoogleFonts.outfit(
          fontSize: 15, fontWeight: FontWeight.w700, color: _DuoColors.textDark,
        )),
        subtitle: Text(subtitle, style: GoogleFonts.inter(
          fontSize: 12, color: _DuoColors.textMuted,
        )),
        trailing: const Icon(Icons.chevron_right_rounded, color: _DuoColors.border, size: 22),
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

class _ToolItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ToolItem(this.label, this.icon, this.color, this.onTap);
}

class _DiscoverItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _DiscoverItem(this.label, this.icon, this.color, this.onTap);
}
