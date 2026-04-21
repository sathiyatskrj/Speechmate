import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/dictionary_service.dart';
import '../services/tts_service.dart';
import '../core/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CommonPhrasesScreen extends StatefulWidget {
  const CommonPhrasesScreen({super.key});

  @override
  State<CommonPhrasesScreen> createState() => _CommonPhrasesScreenState();
}

class _CommonPhrasesScreenState extends State<CommonPhrasesScreen> {
  final DictionaryService _dictionaryService = DictionaryService();
  final TtsService _ttsService = TtsService();
  List<Map<String, dynamic>> _phrases = [];

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadPhrases();
  }

  Future<void> _loadPhrases() async {
    try {
      final data = await _dictionaryService.loadDictionary(DictionaryType.phrases);
      if (mounted) {
        setState(() {
          _phrases = data;
        });
      }
    } catch (e) {
      debugPrint("Error loading phrases: $e");
      if (mounted) {
        setState(() => _phrases = []);
      }
    }
  }

  Future<void> _playPhrase(Map<String, dynamic> phrase) async {
    try {
      final nicobarese = phrase['nicobarese']?.toString() ?? '';
      final english = phrase['text']?.toString() ?? phrase['english']?.toString() ?? '';
      
      if (nicobarese.isNotEmpty) {
        _ttsService.speakNicobarese(nicobarese, englishWord: english);
      } else if (english.isNotEmpty) {
        _ttsService.speakEnglish(english);
      }
    } catch (e) {
      debugPrint("TTS error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio playback not available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Common Phrases", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
               AppColors.studentAccent.withOpacity(0.8),
               Colors.black
            ]
          )
        ),
        child: _phrases.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
                itemCount: _phrases.length,
                itemBuilder: (context, index) {
                  final item = _phrases[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white24)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        item['text'] ?? item['english'] ?? '', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                      ),
                      subtitle: item['nicobarese'] != null 
                        ? Text(
                            item['nicobarese'] ?? '', 
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontStyle: FontStyle.italic)
                          )
                        : const Text(
                            'Tap speaker to hear',
                            style: TextStyle(color: Colors.white54, fontSize: 14, fontStyle: FontStyle.italic)
                          ),
                      trailing: IconButton(
                        icon: Icon(Icons.volume_up, color: AppColors.studentAccent),
                        onPressed: () => _playPhrase(item),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: (index % 10) * 50));
                },
              ),
      ),
    );
  }
}
