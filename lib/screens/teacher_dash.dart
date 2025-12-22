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

class _TeacherDashState extends State<TeacherDash> with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final DictionaryService dictionaryService = DictionaryService();
  final TtsService ttsService = TtsService();
  final AudioPlayer _player = AudioPlayer();

  Map<String, dynamic>? result;
  List<Map<String, dynamic>> phrases = [];
  bool isLoading = false;
  bool searchedNicobarese = false;

  // Hidden Easter egg
  bool _showMagic = false;
  late AnimationController _magicController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ttsService.init();
    
    // Animation for hidden feature
    _magicController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    _loadDictionaries();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      dictionaryService.unloadAll();
    }

    if (state == AppLifecycleState.resumed) {
      _loadDictionaries();
    }
  }

  Future<void> _loadDictionaries() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    await dictionaryService.loadMultiple([
      DictionaryType.words,
      DictionaryType.phrases,
    ]);

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

  Future<void> performSearch() async {
    FocusScope.of(context).unfocus();

    // Hidden Easter egg - Try searching these words!
    final searchText = searchController.text.toLowerCase().trim();
    if (searchText == 'speechmate' || 
        searchText == 'nicobar' || 
        searchText == 'magic' ||
        searchText == 'treasure') {
      setState(() => _showMagic = true);
      _magicController.forward(from: 0);
      
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() => _showMagic = false);
          _magicController.reset();
        }
      });
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

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

  void playAudio(String category, String fileName) async {
    try {
      final path = 'audio/$category/$fileName';
      await _player.play(AssetSource(path));
      debugPrint('Trying to play: audio/$category/$fileName');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not play audio: $e')));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    searchController.dispose();
    _magicController.dispose();
    dictionaryService.unloadAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width < 400;
    
    final titleFontSize = isSmallScreen ? 18.0 : (isMediumScreen ? 20.0 : 22.0);
    final titleSpacing = isSmallScreen ? 15.0 : (isMediumScreen ? 20.0 : 30.0);
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Background(
              colors: const [Color(0xFF38BDF8), Color(0xFF94FFF8)],
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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

                          Search(
                            controller: searchController,
                            onSearch: performSearch,
                            onClear: clearSearch,
                          ),

                          const SizedBox(height: 5),

                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.only(
                                bottom: 20,
                                left: isSmallScreen ? 4 : 0,
                                right: isSmallScreen ? 4 : 0,
                              ),
                              children: [
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

                                if (phrases.isNotEmpty && searchController.text.isNotEmpty)
                                  const SizedBox(height: 16),

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
            
            // Hidden Easter Egg Animation
            if (_showMagic)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _magicController,
                  builder: (context, child) {
                    final progress = _magicController.value;
                    return Container(
                      color: Colors.black.withOpacity(0.7 * (1 - progress)),
                      child: Center(
                        child: Transform.scale(
                          scale: 0.3 + (progress * 0.7),
                          child: Opacity(
                            opacity: progress < 0.8 ? 1.0 : (1.0 - ((progress - 0.8) / 0.2)),
                            child: Container(
                              margin: EdgeInsets.all(isSmallScreen ? 30 : 40),
                              padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade400,
                                    Colors.blue.shade400,
                                    Colors.pink.shade400,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.6),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '✨🎉✨',
                                    style: TextStyle(
                                      fontSize: (isSmallScreen ? 50 : 70) * (0.5 + progress * 0.5),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 15 : 20),
                                  Text(
                                    'You Found It!',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 22 : 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 10),
                                  Text(
                                    '🌴 Hidden Treasure Unlocked! 🌴',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
