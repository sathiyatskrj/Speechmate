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
    ttsService.init(); // Initialize TTS
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width < 400;
    
    // Responsive font sizes
    final titleFontSize = isSmallScreen ? 18.0 : (isMediumScreen ? 20.0 : 22.0);
    final titleSpacing = isSmallScreen ? 15.0 : (isMediumScreen ? 20.0 : 30.0);
    
    return Scaffold(
      body: SafeArea(
        child: Background(
          colors: const [Color(0xFF38BDF8), Color(0xFF94FFF8)],
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8.0 : 0.0,
                        ),
                        child: Text(
                          searchedNicobarese
                              ? "Nicobarese → English"
                              : "English → Nicobarese",
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: titleSpacing),

                      // SEARCH BAR
                      Search(
                        controller: searchController,
                        onSearch: performSearch,
                        onClear: clearSearch,
                      ),

                      const SizedBox(height: 5),

                      // Phrases list with audio and search results
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.only(
                            bottom: 20,
                            left: isSmallScreen ? 4 : 0,
                            right: isSmallScreen ? 4 : 0,
                          ),
                          children: [
                            // Audio phrase cards - ALWAYS VISIBLE
                            if (phrases.isNotEmpty)
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

                            // Spacing between phrases and search results
                            if (phrases.isNotEmpty && searchController.text.isNotEmpty)
                              const SizedBox(height: 16),

                            // Translation result (AFTER audio cards)
                            if (searchController.text.isNotEmpty &&
                                result != null &&
                                result!['_type'] == 'words')
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isSmallScreen ? 4 : 0,
                                  right: isSmallScreen ? 4 : 0,
                                ),
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
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isSmallScreen ? 4 : 0,
                                  right: isSmallScreen ? 4 : 0,
                                ),
                                child: const TranslationCard(
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
      ),
    );
  }
}
