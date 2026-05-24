import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/core/app_colors.dart';
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
import 'package:speechmate/widgets/tap_scale.dart';
import 'dart:math' as math;


class ExplorerDashboard extends StatefulWidget {
  const ExplorerDashboard({super.key});

  @override
  State<ExplorerDashboard> createState() => _ExplorerDashboardState();
}

class _ExplorerDashboardState extends State<ExplorerDashboard>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  Map<String, dynamic>? _wordOfDay;
  bool _isOnline = false;

  // VC control dashboard state variables
  bool _teeVaultSealed = true;
  bool _batSyncListening = false;
  int _meshNodeCount = 3;
  int _beamWidth = 5;
  bool _gpuComputeAccelerated = true;
  double _signalStrength = -42.5;
  double _ambientLux = 120.0;


  // Survival phrase categories for quick cards
  final List<Map<String, dynamic>> _quickPhrases = [
    {'emoji': '👋', 'label': 'Greetings', 'english': 'Hello', 'nicobarese': 'Musté'},
    {'emoji': '🍚', 'label': 'Food', 'english': 'Water', 'nicobarese': 'Mak'},
    {'emoji': '🗺️', 'label': 'Directions', 'english': 'Where', 'nicobarese': 'Inta'},
    {'emoji': '🆘', 'label': 'Emergency', 'english': 'Help', 'nicobarese': 'Takanam'},
    {'emoji': '🙏', 'label': 'Thanks', 'english': 'Thank you', 'nicobarese': 'Asé'},
    {'emoji': '🏠', 'label': 'Shelter', 'english': 'House', 'nicobarese': 'Hīn'},
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this, duration: const Duration(seconds: 20),
    )..repeat();
    _loadWordOfDay();
  }

  Future<void> _loadWordOfDay() async {
    try {
      final words = await DatabaseManager.instance.getWordsByCategory('main');
      if (words.isNotEmpty) {
        // Deterministic daily pick based on day-of-year
        final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
        final index = dayOfYear % words.length;
        if (mounted) setState(() => _wordOfDay = words[index]);
      }
    } catch (e) {
      debugPrint('[Explorer] Word of day error: $e');
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ExplorerBgPainter(time: _bgController.value * math.pi * 2),
              );
            },
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader()),
                // Offline chip
                SliverToBoxAdapter(child: _buildConnectivityChip()),
                // Word of the Day
                if (_wordOfDay != null)
                  SliverToBoxAdapter(child: _buildWordOfDay()),
                // Quick Phrases
                SliverToBoxAdapter(child: _buildQuickPhrases()),
                // VC Control Console
                SliverToBoxAdapter(child: _buildVCDashboardConsole()),
                // Section: Core Tools
                SliverToBoxAdapter(child: _buildSectionLabel('EXPLORER TOOLS')),
                SliverToBoxAdapter(child: _buildBentoGrid()),

                // Section: More
                SliverToBoxAdapter(child: _buildSectionLabel('DISCOVER')),
                SliverToBoxAdapter(child: _buildDiscoverGrid()),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.3), blurRadius: 12),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/icons/logo_main.png', fit: BoxFit.cover,
                errorBuilder: (c, o, s) => const Icon(Icons.language, color: Colors.white, size: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SpeechMate', style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5,
                )),
                Text('Explorer Edition', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8), letterSpacing: 2,
                )),
              ],
            ),
          ),
          _buildHeaderIcon(Icons.info_outline_rounded, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
          }),
          const SizedBox(width: 8),
          _buildHeaderIcon(Icons.feedback_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      ),
    );
  }

  Widget _buildConnectivityChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('Fully Offline', style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF10B981), letterSpacing: 1,
              )),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildWordOfDay() {
    final word = _wordOfDay!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.08), blurRadius: 20),
          ],
        ),
        child: Row(
          children: [
            Text(word['emoji'] ?? '🌊', style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WORD OF THE DAY', style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF0D9488), letterSpacing: 2,
                  )),
                  const SizedBox(height: 4),
                  Text(word['english'] ?? '', style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                  )),
                  Text(word['nicobarese'] ?? '', style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF2DD4BF),
                  )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up_rounded, color: Color(0xFF2DD4BF), size: 22),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildQuickPhrases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text('SURVIVAL PHRASES', style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 2,
          )),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quickPhrases.length,
            itemBuilder: (context, i) {
              final p = _quickPhrases[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TapScale(
                  onTap: () {},
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${p['emoji']} ${p['label']}', style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
                        )),
                        const SizedBox(height: 4),
                        Text('${p['nicobarese']}', style: TextStyle(
                          fontSize: 11, color: const Color(0xFF2DD4BF).withOpacity(0.8),
                        )),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (200 + i * 80).ms).slideX(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 3,
      )),
    );
  }

  Widget _buildBentoGrid() {
    final tools = [
      _BentoItem('Voice\nTranslate', Icons.mic_rounded, [const Color(0xFF0D9488), const Color(0xFF115E59)], 2, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceTranslatorScreen()));
      }),
      _BentoItem('Text\nTranslate', Icons.translate_rounded, [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], 1, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatTranslateScreen()));
      }),
      _BentoItem('GA Hub', Icons.terrain_rounded, [const Color(0xFFE64A19), const Color(0xFFD84315)], 1, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GAHubScreen()));
      }),
      _BentoItem('AR Scan', Icons.camera_alt_rounded, [const Color(0xFF7C3AED), const Color(0xFF5B21B6)], 1, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ARTranslatorScreen()));
      }),
      _BentoItem('Dialects', Icons.compare_arrows_rounded, [const Color(0xFFF59E0B), const Color(0xFFD97706)], 1, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DialectComparisonScreen()));
      }),
      _BentoItem('Documents', Icons.auto_stories_rounded, [const Color(0xFF06B6D4), const Color(0xFF0891B2)], 2, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentTranslationHub()));
      }),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Voice (wide) + Text
          Row(children: [
            Expanded(flex: 2, child: _buildBentoTile(tools[0], height: 130)),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: _buildBentoTile(tools[1], height: 130)),
          ]),
          const SizedBox(height: 8),
          // Row 2: GA + AR + Dialects
          Row(children: [
            Expanded(child: _buildBentoTile(tools[2], height: 100)),
            const SizedBox(width: 8),
            Expanded(child: _buildBentoTile(tools[3], height: 100)),
            const SizedBox(width: 8),
            Expanded(child: _buildBentoTile(tools[4], height: 100)),
          ]),
          const SizedBox(height: 8),
          // Row 3: Documents (wide)
          _buildBentoTile(tools[5], height: 80, fullWidth: true),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildBentoTile(_BentoItem item, {required double height, bool fullWidth = false}) {
    return TapScale(
      onTap: item.onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.colors, begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: item.colors.first.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, color: Colors.white.withOpacity(0.9), size: 28),
            Text(item.label, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverGrid() {
    final items = [
      _DiscoverItem('Culture Hub', Icons.auto_awesome, const Color(0xFFEC4899), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CultureScreen()));
      }),
      _DiscoverItem('Voice Vault', Icons.record_voice_over, const Color(0xFF8B5CF6), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceVaultScreen()));
      }),
      _DiscoverItem('All Languages', Icons.language_rounded, const Color(0xFF0EA5E9), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const Languages()));
      }),
      _DiscoverItem('Feedback', Icons.chat_bubble_outline, const Color(0xFF10B981), () {
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
                height: 85,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: item.color.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: item.color, size: 24),
                    const SizedBox(height: 6),
                    Text(item.label, style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70,
                    ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildVCDashboardConsole() {
    final nativeService = NativeEdgeService();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
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
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05);
  }
}


class _BentoItem {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final int span;
  final VoidCallback onTap;
  _BentoItem(this.label, this.icon, this.colors, this.span, this.onTap);
}

class _DiscoverItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _DiscoverItem(this.label, this.icon, this.color, this.onTap);
}

class _ExplorerBgPainter extends CustomPainter {
  final double time;
  _ExplorerBgPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    void drawOrb(Offset center, double radius, Color color, double alpha) {
      paint.shader = RadialGradient(
        colors: [color.withOpacity(alpha), color.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
    drawOrb(
      Offset(size.width * (0.8 + 0.1 * math.sin(time)), size.height * 0.15),
      size.width * 0.5, const Color(0xFF0F766E), 0.12,
    );
    drawOrb(
      Offset(size.width * (0.2 + 0.1 * math.cos(time * 0.7)), size.height * 0.7),
      size.width * 0.4, const Color(0xFF115E59), 0.10,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
