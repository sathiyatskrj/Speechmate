import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';
import '../widgets/background.dart';

class MagicWordsPage extends StatefulWidget {
  const MagicWordsPage({super.key});

  @override
  State<MagicWordsPage> createState() => _MagicWordsPageState();
}

class _MagicWordsPageState extends State<MagicWordsPage> {
  final DictionaryService _dictionaryService = DictionaryService();
  final AudioPlayer _player = AudioPlayer();
  List<Map<String, dynamic>> _words = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _dictionaryService.loadDictionary(DictionaryType.magic);
    final items = await _dictionaryService.getDictionary(DictionaryType.magic);
    if (mounted) {
      setState(() {
        _words = items;
        _isLoading = false;
      });
    }
  }

  void _playSound(String fileName) async {
    try {
      await _player.play(AssetSource('audio/magic/$fileName'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Magic Words ✨"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Background(
        colors: const [Color(0xFFa18cd1), Color(0xFFfbc2eb)], // Magical Purple/Pink
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
                itemCount: _words.length,
                itemBuilder: (context, index) {
                  final word = _words[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.purple),
                      ),
                      title: Text(
                        word['text'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        word['nicobarese'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.volume_up_rounded, size: 30, color: Colors.blue),
                        onPressed: () {
                          if (word['audio'] != null) {
                            _playSound(word['audio']['file']);
                          }
                        },
                      ),
                      onTap: () {
                          if (word['audio'] != null) {
                            _playSound(word['audio']['file']);
                          }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
