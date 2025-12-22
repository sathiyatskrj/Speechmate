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

class TeacherDash extends StatefulWidget {
  const TeacherDash({super.key});

  @override
  State<TeacherDash> createState() => _TeacherDashState();
}

class _TeacherDashState extends State<TeacherDash> with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

    final loadedPhrases = await dictionaryService.getDictionary(DictionaryType.phrases);
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
    dictionaryService.unloadAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (searchController.text.isNotEmpty) {
      content = Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                 ...phrases.map((item) => AudioPhraseCard(
                      text: item['text'] ?? '',
                      onPlay: () {
                         if (item['audio'] != null) playAudio(item['audio']['category'], item['audio']['file']);
                      },
                 )),

                 if (result != null && result!['_type'] == 'words')
                   Padding(
                     padding: const EdgeInsets.only(top: 16),
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
          )
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           if (dailyWord != null) ...[
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text("📅 Daily Word", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                 IconButton(
                   icon: const Icon(Icons.share, color: Colors.blue),
                   onPressed: () {
                     Share.share(
                       '📚 Today\'s Nicobarese Word:\n\n'
                       '${dailyWord!['nicobarese']} = ${dailyWord!['english']}\n\n'
                       'Learn with Speechmate!',
                     );
                   },
                 ),
               ],
             ),
             const SizedBox(height: 10),
             TranslationCard(
               nicobarese: dailyWord!['nicobarese'],
               english: dailyWord!['english'],
             ),
             const SizedBox(height: 20),
           ],

           if (history.isNotEmpty) ...[
             const Text("🕒 Recent Searches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
             const SizedBox(height: 10),
             Expanded(
               child: ListView.builder(
                 itemCount: history.length,
                 itemBuilder: (context, index) {
                   return Card(
                     child: ListTile(
                       leading: const Icon(Icons.history, size: 20),
                       title: Text(history[index]),
                       onTap: () {
                         searchController.text = history[index];
                         performSearch();
                       },
                     ),
                   );
                 },
               ),
             )
           ] else 
             const Expanded(child: Center(child: Text("Start searching to learn!", style: TextStyle(color: Colors.black45)))),
        ],
      );
    }

    return Scaffold(
      body: Background(
        colors: const [Color(0xFF38BDF8), Color(0xFF94FFF8)],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const SizedBox(width: 40),
                 Text(
                   searchedNicobarese ? "Nicobarese → English" : "English → Nicobarese",
                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                 ),
                 Row(
                   children: [
                     IconButton(
                       icon: const Icon(Icons.quiz_outlined, color: Colors.deepPurple),
                       tooltip: 'Quiz Mode',
                       onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
                     ),
                     IconButton(
                       icon: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                       tooltip: 'Chat Translator',
                       onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatTranslateScreen())),
                     ),
                     IconButton(
                       icon: const Icon(Icons.bar_chart, color: Colors.green),
                       tooltip: 'Progress',
                       onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
                     ),
                   ],
                 )
               ],
             ),
             const SizedBox(height: 30),
             Search(
               controller: searchController,
               onSearch: performSearch,
               onClear: clearSearch,
               onVoiceSearch: performVoiceSearch,
             ),
             const SizedBox(height: 15),
             Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

