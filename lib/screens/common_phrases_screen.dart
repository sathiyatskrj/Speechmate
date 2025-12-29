import 'package:flutter/material.dart';
import '../widgets/background.dart';
import '../services/dictionary_service.dart';
import '../services/tts_service.dart';

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
    _loadPhrases();
    _ttsService.init();
  }

  Future<void> _loadPhrases() async {
    final data = await _dictionaryService.loadDictionary(DictionaryType.phrases);
    setState(() {
      _phrases = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Common Phrases"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Background(
        colors: const [Color(0xFFee9ca7), Color(0xFFffdde1)],
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(item['text'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text(item['nicobarese'] ?? '', style: const TextStyle(color: Colors.teal, fontSize: 16, fontStyle: FontStyle.italic)),
                      trailing: IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.blueAccent),
                        onPressed: () {
                           _ttsService.speakNicobarese(item['nicobarese'] ?? '');
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
