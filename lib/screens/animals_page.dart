import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';
import '../widgets/background.dart';

class AnimalsPage extends StatefulWidget {
  const AnimalsPage({super.key});

  @override
  State<AnimalsPage> createState() => _AnimalsPageState();
}

class _AnimalsPageState extends State<AnimalsPage> {
  final DictionaryService _dictionaryService = DictionaryService();
  final AudioPlayer _player = AudioPlayer();
  List<Map<String, dynamic>> _animals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _dictionaryService.loadDictionary(DictionaryType.animals);
    final items = _dictionaryService.getDictionary(DictionaryType.animals);
    if (mounted) {
      setState(() {
        _animals = items;
        _isLoading = false;
      });
    }
  }

  void _playSound(String fileName) async {
    try {
      await _player.play(AssetSource('audio/animals/$fileName'));
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
        title: const Text("Island Animals"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      extendBodyBehindAppBar: true,
      body: Background(
        colors: const [Color(0xFF84FAB0), Color(0xFF8FD3F4)], // Nature Green/Blue
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _animals.length,
                itemBuilder: (context, index) {
                  final animal = _animals[index];
                  return GestureDetector(
                    onTap: () {
                      if (animal['audio'] != null) {
                        _playSound(animal['audio']['file']);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Playing ${animal['text']} sound..."),
                          duration: const Duration(milliseconds: 500),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(
                                animal['image'] ?? 'assets/images/generic_animal.png',
                                errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 50, color: Colors.brown),
                              ),
                            ),
                          ),
                          Text(
                            animal['text'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            animal['nicobarese'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Icon(Icons.volume_up_rounded, color: Colors.blueAccent),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
