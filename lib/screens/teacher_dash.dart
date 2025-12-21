import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../widgets/background.dart';
import '../widgets/search_bar.dart';
import '../widgets/translation_card.dart';
import '../services/dictionary_service.dart';
import '../services/tts_service.dart';
import '../widgets/audio_phrase_card.dart';

class TeacherDash extends StatefulWidget {
  const TeacherDash({super.key});

  @override
  State<TeacherDash> createState() => _TeacherDashState();
}

class _TeacherDashState extends State<TeacherDash> with WidgetsBindingObserver {
  final TextEditingController searchController = TextEditingController();
  final DictionaryService dictionaryService = DictionaryService();
  final TtsService ttsService = TtsService();
  final AudioPlayer _player = AudioPlayer();

  Map<String, dynamic>? result;
  List<Map<String, dynamic>> phrases = [];
  bool isLoading = false;
  bool searchedNicobarese = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDictionaries();
  }

  // Monitor app lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Free memory when app goes to background or is paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      dictionaryService.unloadAll();
    }

    // Reload when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadDictionaries();
    }
  }

  // Load both words and phrases dictionaries
  Future<void> _loadDictionaries() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // Load both dictionaries needed for this screen
    await dictionaryService.loadMultiple([
      DictionaryType.words,
      DictionaryType.phrases,
    ]);

    // Get the phrases data
    final loadedPhrases = await dictionaryService.getDictionary(
      DictionaryType.phrases,
    );

    if (mounted) {
      setState(() {
        phrases = loadedPhrases;
        isLoading = false;
      });
    }
  }

  // Perform search in both words and phrases
  Future<void> performSearch() async {
    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // Search in both dictionaries
    final searchResult = await dictionaryService.searchEverywhere(
      searchController.text,
    );

    if (mounted) {
      setState(() {
        result = searchResult;

        searchedNicobarese = searchResult?['_searchedNicobarese'] == true;

        isLoading = false;
      });
    }
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      result = null;
    });
  }

  // Play audio from assets
  void playAudio(String category, String fileName) async {
    try {
      final path = 'audio/$category/$fileName';
      await _player.play(AssetSource(path));
      debugPrint('Trying to play: audio/$category/$fileName');
    } catch (e) {
      // Handle audio playback error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not play audio: $e')));
      }
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Dispose resources
    _player.dispose();
    searchController.dispose();

    // Free memory when leaving this screen
    dictionaryService.unloadAll();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: [Color(0xFF38BDF8), Color(0xFF94FFF8)],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      searchedNicobarese
                          ? "Nicobarese → English"
                          : "English → Nicobarese",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // SEARCH BAR
                    Search(
                      controller: searchController,
                      onSearch: performSearch,
                      onClear: clearSearch,
                    ),

                    const SizedBox(height: 5),

                    // Phrases list with audio
                    Expanded(
                      child:
                          phrases.isEmpty
                              ? const Center(
                                child: Text('No phrases available'),
                              )
                              : ListView(
                                padding: const EdgeInsets.only(bottom: 20),
                                children: [
                                  // Audio phrase cards
                                  ...phrases.map((item) {
                                    return AudioPhraseCard(
                                      text: item['text'] ?? 'Unknown phrase',
                                      onPlay: () {
                                        if (item['audio'] != null) {
                                          playAudio(
                                            item['audio']['category'] ?? '',
                                            item['audio']['file'] ?? '',
                                          );
                                        }
                                      },
                                    );
                                  }),

                                  // Translation result (AFTER audio cards)
                                  if (searchController.text.isNotEmpty &&
                                      result != null &&
                                      result!['_type'] == 'words')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: TranslationCard(
                                        nicobarese: result!['nicobarese'],
                                        english: result!['english'],
                                        isError: false,
                                        searchedNicobarese: searchedNicobarese,
                                        showSpeaker: true,
                                        onSpeakerTap: () {
                                          // 🔊 Speak only the searched language
                                          if (searchedNicobarese) {
                                            ttsService.speakEnglish(
                                              result!['english'],
                                            );
                                          } else {
                                            ttsService.speakNicobarese(
                                              result!['nicobarese'],
                                            );
                                          }
                                        },
                                      ),
                                    )
                                  else if (searchController.text.isNotEmpty &&
                                      result == null)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 16),
                                      child: TranslationCard(
                                        nicobarese: "Word not found",
                                        english: "",
                                        isError: true,
                                      ),
                                    ),
                                ],
                              ),
                    ),
                  ],
                ),
      ),
    );
  }
}
