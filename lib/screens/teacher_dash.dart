import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/background.dart';
import '../widgets/search_bar.dart';
import '../widgets/translation_card.dart';
import '../services/dictionary_service.dart';
import '../services/tts_service.dart';
import '../widgets/audio_phrase_card.dart';
import 'quiz_screen.dart';
import 'chat_translate_screen.dart';
import 'progress_screen.dart';
import 'teacher_levels_screen.dart';
import 'community_screen.dart';
import 'package:record/record.dart'; // Added
import 'package:path_provider/path_provider.dart'; // Added
import 'dart:io'; // Added
import 'package:flutter/services.dart'; // Added for rootBundle
import '../services/whisper_service.dart'; // Added

class TeacherDash extends StatefulWidget {
  const TeacherDash({super.key});

  @override
  State<TeacherDash> createState() => _TeacherDashState();
}

class _TeacherDashState extends State<TeacherDash> with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final DictionaryService dictionaryService = DictionaryService();
  final FavoritesService favoritesService = FavoritesService();
  final HistoryService historyService = HistoryService();
  final ProgressService progressService = ProgressService();
  final TtsService ttsService = TtsService();
  final AudioPlayer _player = AudioPlayer();

  Map<String, dynamic>? result;
  List<Map<String, dynamic>> phrases = [];
  bool isLoading = false;
  bool searchedNicobarese = false;
  bool isFavorite = false;

  Map<String, dynamic>? dailyWord;
  List<String> history = [];

  // Hidden Easter egg
  bool _showMagic = false;
  late AnimationController _magicController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ttsService.init();
    
    _magicController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    _loadAllData();
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
    await dictionaryService.loadMultiple([
      DictionaryType.words,
      DictionaryType.phrases,
    ]);
  }

  Future<void> _loadAllData() async {
    if (mounted) setState(() => isLoading = true);

    await _loadDictionaries();

    final loadedPhrases = dictionaryService.getDictionary(DictionaryType.phrases);
    final h = await historyService.getHistory();
    final dWord = await dictionaryService.getDailyWord();

    if (mounted) {
      setState(() {
        phrases = loadedPhrases;
        history = h;
        dailyWord = dWord;
        isLoading = false;
      });
    }
  }

  Future<void> performSearch() async {
    FocusScope.of(context).unfocus();
    if (searchController.text.isEmpty) return;

    // Hidden Easter egg
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

    if (mounted) setState(() => isLoading = true);

    await progressService.incrementSearchCount();
    await progressService.updateStreak();

    final searchResult = await dictionaryService.searchEverywhere(searchController.text);

    if (searchResult != null) {
      await historyService.addToHistory(searchController.text);
      final newHistory = await historyService.getHistory();
      if (mounted) setState(() => history = newHistory);
    }

    bool fav = false;
    if (searchResult != null && searchResult['_type'] == 'words') {
      fav = await favoritesService.isFavorite(searchResult['english'] ?? '');
    }

    if (mounted) {
      setState(() {
        result = searchResult;
        searchedNicobarese = searchResult?['_searchedNicobarese'] == true;
        isFavorite = fav;
        isLoading = false;
      });
    }
  }

  // --- WHISPER LOGIC START ---
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocDir.path}/temp_recording_teacher.wav';
        
        await _audioRecorder.start(path: filePath, encoder: AudioEncoder.wav, samplingRate: 16000);
        
        setState(() {
          _isRecording = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("🎙️ Listening... Tap again to stop."), duration: Duration(seconds: 10), backgroundColor: Colors.redAccent)
        );
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        isLoading = true; // Show loading while transcribing
      });

      if (path != null) {
        final modelPath = await _getModelPath();
        final text = await WhisperService().transcribe(modelPath, path);
        
        if (text.startsWith("Error")) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
        } else {
           final cleanText = text.replaceAll("[BLANK_AUDIO]", "").trim();
           if (cleanText.isEmpty) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❓ Could not hear anything.")));
           } else {
               searchController.text = cleanText;
               performSearch();
           }
        }
      }
      setState(() => isLoading = false);
    } catch (e) {
      print("Error stopping record: $e");
      setState(() => isLoading = false);
    }
  }

  Future<String> _getModelPath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String modelPath = '${appDocDir.path}/ggml-tiny.en.bin';
    final File modelFile = File(modelPath);

    if (!await modelFile.exists()) {
       try {
          final ByteData data = await rootBundle.load('assets/models/ggml-tiny.en.bin');
          final List<int> bytes = data.buffer.asUint8List();
          await modelFile.writeAsBytes(bytes, flush: true);
       } catch (e) {
          print("Error copying model: $e");
          return ""; 
       }
    }
    return modelPath;
  }

  void _onMicTap() {
      if (_isRecording) {
          _stopRecording();
      } else {
          _startRecording();
      }
  }
  // --- WHISPER LOGIC END ---

  void toggleFavorite() async {
    if (result == null || result!['_type'] != 'words') return;
    final word = result!['english'] ?? '';
    if (isFavorite) {
      await favoritesService.removeFavorite(word);
    } else {
      await favoritesService.addFavorite(word);
    }
    setState(() => isFavorite = !isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isFavorite ? 'Added to Favorites' : 'Removed from Favorites'), duration: const Duration(seconds: 1)),
    );
  }

  void showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Issue"),
        content: const TextField(
          decoration: InputDecoration(hintText: "What is wrong?"),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanks for your feedback!")));
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      result = null;
    });
  }

  void playAudio(String category, String fileName) async {
    try {
      await _player.play(AssetSource('audio/$category/$fileName'));
    } catch (e) {
      // ignore
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

    final titleFontSize = isSmallScreen ? 16.0 : (isMediumScreen ? 17.0 : 18.0);
    final titleSpacing = isSmallScreen ? 15.0 : (isMediumScreen ? 20.0 : 30.0);
    final sectionFontSize = isSmallScreen ? 16.0 : 18.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;

    Widget content;

    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (searchController.text.isNotEmpty) {
      content = Expanded(
        child: ListView(
          padding: EdgeInsets.only(
            bottom: 20,
            left: isSmallScreen ? 4 : 0,
            right: isSmallScreen ? 4 : 0,
          ),
          children: [
            if (result != null && result!['_type'] == 'words')
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 0),
                child: TranslationCard(
                  nicobarese: result!['nicobarese'],
                  english: result!['english'],
                  searchedNicobarese: searchedNicobarese,
                  showSpeaker: true,
                  onSpeakerTap: () {
                    if (searchedNicobarese) {
                      ttsService.speakEnglish(result!['english']);
                    } else {
                      ttsService.speakNicobarese(result!['nicobarese']);
                    }
                  },
                  isFavorite: isFavorite,
                  onFavoriteToggle: toggleFavorite,
                  onReport: showReportDialog,
                ),
              )
            else if (result == null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 0),
                child: const TranslationCard(
                  nicobarese: "Word not found",
                  english: "",
                  isError: true,
                ),
              ),
          ],
        ),
      );
    } else {
      content = Expanded(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 20, 
            vertical: 10
          ),
          children: [
            // Common Phrases Section
            if (phrases.isNotEmpty) ...[
              Text("💬 Common Phrases", style: TextStyle(fontSize: sectionFontSize, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              SizedBox(
                height: 80, // Height for horizontal scrolling cards
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: phrases.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = phrases[index];
                    return GestureDetector(
                      onTap: () {
                         if (item['audio'] != null) playAudio(item['audio']['category'], item['audio']['file']);
                      },
                      child: Container(
                         width: 160,
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         decoration: BoxDecoration(
                           color: Colors.white, 
                           borderRadius: BorderRadius.circular(15),
                           boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                           border: Border.all(color: Colors.blue.withOpacity(0.3))
                         ),
                         alignment: Alignment.center,
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const Icon(Icons.volume_up, size: 20, color: Colors.blue),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(
                                 item['text'] ?? '', 
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                                 maxLines: 2, 
                                 overflow: TextOverflow.ellipsis
                               ),
                             ),
                           ],
                         ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // New Teacher Certification section
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLevelsScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.school, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Teacher Certification", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Master 10 Levels & Get Certified!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Community Hub Mockup Link
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                    border: Border.all(color: Colors.purple.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_rounded, color: Colors.purple, size: 30),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Community Hub 🌏", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("See what others are sharing", style: TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black26, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],

            if (dailyWord != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("📅 Daily Word", style: TextStyle(fontSize: sectionFontSize, fontWeight: FontWeight.bold, color: Colors.black87)),
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.blue, size: iconSize),
                    onPressed: () {
                      Share.share('📚 Today\'s Nicobarese Word:\n\n${dailyWord!['nicobarese']} = ${dailyWord!['english']}\n\nLearn with Speechmate!');
                    },
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
              TranslationCard(
                nicobarese: dailyWord!['nicobarese'],
                english: dailyWord!['english'],
              ),
              SizedBox(height: isSmallScreen ? 15 : 20),
            ],
            
            if (history.isNotEmpty) ...[
              Text("🕒 Recent Searches", style: TextStyle(fontSize: sectionFontSize, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: isSmallScreen ? 8 : 10),
              // Flattened History List
              ...history.map((term) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.history, size: isSmallScreen ? 18 : 20, color: Colors.orange),
                    ),
                    title: Text(term, style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.north_west, size: 16, color: Colors.grey),
                    onTap: () {
                      searchController.text = term;
                      performSearch();
                    },
                  ),
                );
              }),
              const SizedBox(height: 20),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 50, color: Colors.black12),
                      const SizedBox(height: 10),
                      Text("Start searching to learn!", style: TextStyle(color: Colors.black45, fontSize: isSmallScreen ? 14 : 16)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Background(
              colors: const [Color(0xFF38BDF8), Color(0xFF94FFF8)],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          searchedNicobarese ? "Nicobarese → English" : "English → Nicobarese",
                          style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.quiz_outlined, color: Colors.deepPurple, size: iconSize),
                            tooltip: 'Quiz Mode',
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          ),
                          IconButton(
                            icon: Icon(Icons.chat_bubble_outline, color: Colors.blueAccent, size: iconSize),
                            tooltip: 'Chat Translator',
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatTranslateScreen())),
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          ),
                          IconButton(
                            icon: Icon(Icons.bar_chart, color: Colors.green, size: iconSize),
                            tooltip: 'Progress',
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          ),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: titleSpacing),
                  Search(controller: searchController, onSearch: performSearch, onClear: clearSearch, onMicTap: _onMicTap),
                  SizedBox(height: isSmallScreen ? 10 : 15),
                  content,
                ],
              ),
            ),
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
                                gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.blue.shade400, Colors.pink.shade400]),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.6), blurRadius: 30, spreadRadius: 10)],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('✨🎉✨', style: TextStyle(fontSize: (isSmallScreen ? 50 : 70) * (0.5 + progress * 0.5))),
                                  SizedBox(height: isSmallScreen ? 15 : 20),
                                  Text('You Found It!', style: TextStyle(fontSize: isSmallScreen ? 22 : 28, fontWeight: FontWeight.bold, color: Colors.white)),
                                  SizedBox(height: isSmallScreen ? 8 : 10),
                                  Text('🌴 Hidden Treasure Unlocked! 🌴', textAlign: TextAlign.center, style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w500)),
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
