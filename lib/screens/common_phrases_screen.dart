import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/dictionary_service.dart';
import '../core/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CommonPhrasesScreen extends StatefulWidget {
  const CommonPhrasesScreen({super.key});

  @override
  State<CommonPhrasesScreen> createState() => _CommonPhrasesScreenState();
}

class _CommonPhrasesScreenState extends State<CommonPhrasesScreen> {
  final DictionaryService _dictionaryService = DictionaryService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _phrases = [];


  @override
  void initState() {
    super.initState();

    _loadPhrases();
  }



  Future<void> _loadPhrases() async {
    final data = await _dictionaryService.loadDictionary(DictionaryType.phrases);
    setState(() {
      _phrases = data;
    });
  }

  Future<void> _playAudio(Map<String, dynamic> phrase) async {
    try {
      final audio = phrase['audio'];
      if (audio != null && audio is Map) {
        final category = audio['category'] ?? 'phrases';
        final file = audio['file'];
        if (file != null) {
          final audioPath = 'audio/$category/$file';
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource(audioPath));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio not available: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
                        item['text'] ?? '', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                      ),
                      subtitle: item['nicobarese'] != null 
                        ? Text(
                            item['nicobarese'] ?? '', 
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 16, fontStyle: FontStyle.italic)
                          )
                        : const Text(
                            'Tap to hear pronunciation',
                            style: TextStyle(color: Colors.white54, fontSize: 14, fontStyle: FontStyle.italic)
                          ),
                      trailing: IconButton(
                        icon: Icon(Icons.volume_up, color: AppColors.studentAccent),
                        onPressed: () => _playAudio(item),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: (index % 10) * 50));
                },
              ),
      ),
    );
  }
}
