import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/database_manager.dart';

class BodyPartsScreen extends StatefulWidget {
  const BodyPartsScreen({super.key});

  @override
  State<BodyPartsScreen> createState() => _BodyPartsScreenState();
}

class _BodyPartsScreenState extends State<BodyPartsScreen> {
  final TtsService _ttsService = TtsService();
  List<Map<String, dynamic>> _bodyParts = [];
  Map<String, dynamic>? _selected;



  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadBodyParts();
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
    } catch (e) { debugPrint("Silent error caught: $e");
      return null;
    }
  }



  @override
  void dispose() {
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

                                    // Hotspot buttons removed per user request
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


