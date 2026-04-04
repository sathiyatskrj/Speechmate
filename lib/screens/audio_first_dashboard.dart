import 'package:flutter/material.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Using TTS/Audio as a placeholder for recorded audio
import 'package:speechmate/widgets/background.dart';

class AudioFirstDashboard extends StatefulWidget {
  const AudioFirstDashboard({super.key});

  @override
  State<AudioFirstDashboard> createState() => _AudioFirstDashboardState();
}

class _AudioFirstDashboardState extends State<AudioFirstDashboard> {
  final FlutterTts _tts = FlutterTts();
  int _playingIndex = -1;

  final List<Map<String, dynamic>> _audioCategories = [
    {"icon": Icons.forest, "color": Colors.green, "audioKey": "jungleAdventure", "label": "Jungle"},
    {"icon": Icons.water, "color": Colors.blue, "audioKey": "islandColors", "label": "Island"},
    {"icon": Icons.pets, "color": Colors.orange, "audioKey": "animals", "label": "Animals"},
    {"icon": Icons.groups, "color": Colors.purple, "audioKey": "community", "label": "Community"},
    {"icon": Icons.mic, "color": Colors.red, "audioKey": "voiceVault", "label": "Vault"},
    {"icon": Icons.favorite, "color": Colors.pink, "audioKey": "feelings", "label": "Feelings"},
  ];

  Future<void> _playAudio(int index, String key) async {
    setState(() {
      _playingIndex = index;
    });
    
    // In a real implementation for indigenous languages, this would play 
    // a pre-recorded community asset audio file instead of TTS.
    await _tts.speak(AppStrings.get(key));
    
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _playingIndex = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppStrings.get('audioFirstDash'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "🔊 ${AppStrings.get('tapMicToRecord')}",
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: _audioCategories.length,
                      itemBuilder: (context, index) {
                        final cat = _audioCategories[index];
                        final isPlaying = _playingIndex == index;
                        
                        return GestureDetector(
                          onTap: () => _playAudio(index, cat['audioKey']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isPlaying ? cat['color'] : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isPlaying ? Colors.white : Colors.white24,
                                width: isPlaying ? 3 : 1,
                              ),
                              boxShadow: isPlaying ? [
                                BoxShadow(color: cat['color'].withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
                              ] : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isPlaying ? Icons.volume_up : cat['icon'],
                                  size: isPlaying ? 70 : 60,
                                  color: isPlaying ? Colors.white : cat['color'],
                                ).animate(target: isPlaying ? 1 : 0)
                                 .scale(end: const Offset(1.2, 1.2)),
                                const SizedBox(height: 15),
                                Text(
                                  AppStrings.get(cat['audioKey']),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
