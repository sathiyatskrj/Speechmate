import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/widgets/background.dart';

class ColorsPage extends StatefulWidget {
  const ColorsPage({super.key});

  @override
  State<ColorsPage> createState() => _ColorsPageState();
}

class _ColorsPageState extends State<ColorsPage> {
  final TtsService _ttsService = TtsService();

  final List<Map<String, dynamic>> _colors = [
    {"name": "Blue", "nicobarese": "Makalö", "color": Color(0xFF006994), "emoji": "🌊"},
    {"name": "Green", "nicobarese": "Maha", "color": Color(0xFF90C242), "emoji": "🥥"},
    {"name": "Orange", "nicobarese": "Föl", "color": Color(0xFFFF5E3A), "emoji": "🌅"},
    {"name": "White", "nicobarese": "Pöch", "color": Color(0xFFF6EAD1), "emoji": "🏖️"},
    {"name": "Pink", "nicobarese": "Hëw", "color": Color(0xFFFF6F61), "emoji": "🪸"},
    {"name": "Brown", "nicobarese": "Tanëh", "color": Color(0xFF8B4513), "emoji": "🏾"},
    {"name": "Red", "nicobarese": "Apël", "color": Color(0xFFDC143C), "emoji": "🍒"},
    {"name": "Dark Blue", "nicobarese": "Kamat", "color": Color(0xFF000080), "emoji": "🦈"},
    {"name": "Yellow", "nicobarese": "Univät", "color": Color(0xFFFFD700), "emoji": "☀️"},
    {"name": "Black", "nicobarese": "Hatöm", "color": Color(0xFF1a1a1a), "emoji": "🌑"},
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String colorName, String fallbackWord) async {
    // Play audio from assets: assets/audio/colors/blue.mp3
    final String assetPath = 'audio/colors/${colorName.toLowerCase()}.mp3';
    try {
        await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
        debugPrint("Error playing audio: $e");
        // Fallback to TTS: speak the Nicobarese word
        _ttsService.speakNicobarese(fallbackWord); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Colors of Nicobar 🎨"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Background(
        colors: const [Color(0xFFff9a9e), Color(0xFFfad0c4)],
        child: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.9,
            ),
            itemCount: _colors.length,
            itemBuilder: (context, index) {
              final colorItem = _colors[index];
              return _buildColorCard(colorItem, index);
            },
          ),
        ),
      ),
    );
  }

    return GestureDetector(
      onTap: () => _playAudio(item['name'], item['nicobarese']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: (item['color'] as Color).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: item['color'],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Center(
                  child: Text(
                    item['emoji'],
                    style: const TextStyle(fontSize: 50),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 2.seconds),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['name'],
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                     Text(
                      item['nicobarese'],
                      style: TextStyle(
                        color: (item['color'] as Color).withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontStyle: FontStyle.italic
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().slideY(
            begin: 0.5,
            duration: 500.ms,
            delay: Duration(milliseconds: index * 100),
            curve: Curves.easeOutBack,
          ).fade(),
    );
  }
}
