import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/database_manager.dart';
import 'dart:ui';

class BodyPartsScreen extends StatefulWidget {
  const BodyPartsScreen({super.key});

  @override
  State<BodyPartsScreen> createState() => _BodyPartsScreenState();
}

class _BodyPartsScreenState extends State<BodyPartsScreen>
    with TickerProviderStateMixin {
  final TtsService _ttsService = TtsService();
  List<Map<String, dynamic>> _bodyParts = [];
  Map<String, dynamic>? _selected;
  late AnimationController _pulseController;

  // Hotspot positions (as fractions of image size, manually calibrated for body_parts.png)
  static const List<_BodyHotspot> _hotspots = [
    _BodyHotspot(name: 'Head',    x: 0.50, y: 0.055),
    _BodyHotspot(name: 'Hair',    x: 0.67, y: 0.045),
    _BodyHotspot(name: 'Eye',     x: 0.50, y: 0.095),
    _BodyHotspot(name: 'Ear',     x: 0.35, y: 0.100),
    _BodyHotspot(name: 'Nose',    x: 0.50, y: 0.115),
    _BodyHotspot(name: 'Mouth',   x: 0.50, y: 0.135),
    _BodyHotspot(name: 'Teeth',   x: 0.65, y: 0.140),
    _BodyHotspot(name: 'Heart',   x: 0.43, y: 0.270),
    _BodyHotspot(name: 'Stomach', x: 0.50, y: 0.360),
    _BodyHotspot(name: 'Hand',    x: 0.22, y: 0.400),
    _BodyHotspot(name: 'Leg',     x: 0.42, y: 0.660),
    _BodyHotspot(name: 'Foot',    x: 0.40, y: 0.870),
  ];

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadBodyParts();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  Future<void> _loadBodyParts() async {
    final data = await DatabaseManager.instance.getWordsByCategory('body_parts');
    if (mounted) setState(() => _bodyParts = data);
  }

  Map<String, dynamic>? _findByName(String name) {
    try {
      return _bodyParts.firstWhere(
        (p) => (p['english'] ?? '').toString().toLowerCase() == name.toLowerCase() ||
               (p['text'] ?? '').toString().toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  void _selectHotspot(_BodyHotspot hotspot) {
    final item = _findByName(hotspot.name);
    if (item == null) return;
    setState(() => _selected = item);

    final audioData = item['audio'];
    if (audioData != null) {
      String cat = '', file = '';
      if (audioData is Map) {
        cat = audioData['category']?.toString() ?? 'body_parts';
        file = audioData['file']?.toString() ?? '';
      } else if (audioData is String && audioData.contains('/')) {
        final parts = audioData.split('/');
        cat = parts[0]; file = parts[1];
      }
      if (file.isNotEmpty) {
        _ttsService.playFromCategory(cat, file);
        return;
      }
    }
    _ttsService.speakNicobarese(
      item['nicobarese'] ?? '',
      englishWord: item['english'] ?? item['text'],
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // Sci-Fi gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0F1E), Color(0xFF0D2137), Color(0xFF0A1628)],
              ),
            ),
          ),

          // Glowing circle blobs
          Positioned(top: -80, right: -80,
            child: Container(width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.cyanAccent.withValues(alpha: 0.1), Colors.transparent]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
                        style: IconButton.styleFrom(backgroundColor: Colors.white10),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Body Parts', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Tap a body part to hear Nicobarese', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selected Word Display
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selected != null
                    ? _buildSelectedCard()
                    : Container(
                        key: const ValueKey('empty'),
                        height: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Center(
                          child: Text('👆 Tap a hotspot on the body', style: TextStyle(color: Colors.white38, fontSize: 14)),
                        ),
                      ),
                ),

                const SizedBox(height: 12),

                // Interactive Body Map
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: AspectRatio(
                            aspectRatio: 1920 / 2208,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final imgW = constraints.maxWidth;
                                final imgH = constraints.maxHeight;
                                return Stack(
                                  children: [
                                    // Body image
                                    Positioned.fill(
                                      child: Image.asset(
                                        'assets/images/body_parts.png',
                                        fit: BoxFit.fill,
                                      ),
                                    ),

                                    // Hotspot buttons
                                    ..._hotspots.map((hotspot) {
                                      final isSelected = _selected != null &&
                                          (_selected!['english'] ?? _selected!['text'] ?? '').toString().toLowerCase() == hotspot.name.toLowerCase();
                                      return _buildHotspot(hotspot, imgW, imgH, isSelected);
                                    }),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Bottom word grid
                _buildBottomWordGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCard() {
    final eng = _selected!['english'] ?? _selected!['text'] ?? '';
    final nic = _selected!['nicobarese'] ?? '';
    return Container(
      key: ValueKey(eng),
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.cyanAccent.withValues(alpha: 0.15), Colors.blueAccent.withValues(alpha: 0.1)],
        ),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.15), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_rounded, color: Colors.cyanAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eng, style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1)),
                Text(nic, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _ttsService.speakNicobarese(nic, englishWord: eng);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up_rounded, color: Colors.cyanAccent, size: 22),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildHotspot(_BodyHotspot hotspot, double imgW, double imgH, bool isSelected) {
    // body_parts.png aspect ratio — image is fitted with BoxFit.contain
    // We position relative to the full stack area
    return Positioned(
      left: hotspot.x * imgW - 14,
      top: hotspot.y * imgH - 14,
      child: GestureDetector(
        onTap: () => _selectHotspot(hotspot),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (ctx, _) {
            final scale = isSelected ? 1.0 + _pulseController.value * 0.25 : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                    ? Colors.cyanAccent.withValues(alpha: 0.9)
                    : Colors.cyanAccent.withValues(alpha: 0.5),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.cyanAccent,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: isSelected ? 0.7 : 0.3),
                      blurRadius: isSelected ? 16 : 8,
                      spreadRadius: isSelected ? 3 : 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: isSelected ? 10 : 7,
                    height: isSelected ? 10 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomWordGrid() {
    if (_bodyParts.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: _bodyParts.length,
        itemBuilder: (ctx, i) {
          final item = _bodyParts[i];
          final eng = item['english'] ?? item['text'] ?? '';
          final nic = item['nicobarese'] ?? '';
          final isActive = _selected != null &&
              (_selected!['english'] ?? _selected!['text'] ?? '').toString() == eng;
          return GestureDetector(
            onTap: () {
              setState(() => _selected = item);
              _ttsService.speakNicobarese(nic, englishWord: eng);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isActive
                  ? Colors.cyanAccent.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: isActive ? Colors.cyanAccent : Colors.white24,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item['emoji'] ?? '🫀', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(eng, style: TextStyle(color: isActive ? Colors.cyanAccent : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BodyHotspot {
  final String name;
  final double x;
  final double y;
  const _BodyHotspot({required this.name, required this.x, required this.y});
}
