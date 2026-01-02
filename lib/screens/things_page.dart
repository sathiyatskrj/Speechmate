import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/widgets/background.dart';

class ThingsPage extends StatefulWidget {
  const ThingsPage({super.key});

  @override
  State<ThingsPage> createState() => _ThingsPageState();
}

class _ThingsPageState extends State<ThingsPage> {
  final TtsService _ttsService = TtsService();

  final List<Map<String, dynamic>> _things = [
    {"name": "Table", "nicobarese": "Mish", "emoji": "🪑"},
    {"name": "Chair", "nicobarese": "Anūchö", "emoji": "🛋️"},
    {"name": "Pen", "nicobarese": "Kanūich", "emoji": "🖊️"},
    {"name": "Book", "nicobarese": "Mat Lipööre", "emoji": "📖"}, // Shortened for UI
    {"name": "Bag", "nicobarese": "Bag", "emoji": "🎒"},
    {"name": "Bottle", "nicobarese": "Pilūn", "emoji": "🍾"},
    {"name": "Clock", "nicobarese": "Kāriyāl", "emoji": "⏰"}, // Replaced Phone
    {"name": "Light", "nicobarese": "Eānvö", "emoji": "💡"},
    {"name": "Fan", "nicobarese": "Fan", "emoji": "🌬️"},
    {"name": "Door", "nicobarese": "Inkūp", "emoji": "🚪"},
    {"name": "Window", "nicobarese": "Khirki", "emoji": "🪟"},
    {"name": "Bed", "nicobarese": "Tahāklöö", "emoji": "🛏️"},
    {"name": "Plate", "nicobarese": "Pingāl", "emoji": "🍽️"},
    {"name": "Spoon", "nicobarese": "Chāmāch", "emoji": "🥄"},
    {"name": "Cup", "nicobarese": "Kööp", "emoji": "☕"},
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _ttsService.init();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String thingName, String fallbackWord) async {
    // Play audio from assets: assets/audio/things/table.mp3
    final String assetPath = 'audio/things/${thingName.toLowerCase()}.mp3';
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
        title: const Text("Everyday Things 🏡"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Background(
        colors: const [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
        child: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // More dense for things
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            itemCount: _things.length,
            itemBuilder: (context, index) {
              final thing = _things[index];
              return _buildThingCard(thing, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThingCard(Map<String, dynamic> item, int index) {
    return GestureDetector(
      onTap: () => _playAudio(item['name'], item['nicobarese']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: Text(
                    item['emoji'],
                    style: const TextStyle(fontSize: 40),
                  ).animate(target: 1).shimmer(duration: 2.seconds, delay: 2.seconds),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['name'],
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                     Text(
                      item['nicobarese'],
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontStyle: FontStyle.italic
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().scale(
            duration: 400.ms,
            delay: Duration(milliseconds: index * 50),
            curve: Curves.easeOutBack,
          ),
    );
  }
}
