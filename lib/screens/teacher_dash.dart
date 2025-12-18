import 'package:flutter/material.dart';
import '../widgets/background.dart';
import '../widgets/search_bar.dart';
import '../widgets/translation_card.dart';
import '../services/dictionary_service.dart';
import '../services/audio_service.dart';

class TeacherDash extends StatefulWidget {
  const TeacherDash({super.key});

  @override
  State<TeacherDash> createState() => _TeacherDashState();
}

class _TeacherDashState extends State<TeacherDash> {
  final TextEditingController searchController = TextEditingController();
  final DictionaryService dictionaryService = DictionaryService();
  final AudioService audioService = AudioService();

  Map<String, dynamic>? result;

  final List<Map<String, String>> commonPhrases = [
    {
      "text": "Good Morning",
      "audio": "assets/audio/good_morning.mp3",
    },
    {
      "text": "How are you?",
      "audio": "assets/audio/how_are_you.mp3",
    },
    {
      "text": "Keep Silent",
      "audio": "assets/audio/keep_silent.mp3",
    },
  ];

  @override
  void initState() {
    super.initState();
    dictionaryService.load();
  }

  void performSearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      result = dictionaryService.search(searchController.text);
    });
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: const [Color(0xFF38BDF8), Color(0xFF94FFF8)],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "English → Nicobarese",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 20),

            Search(
              controller: searchController,
              onSearch: performSearch,
              onClear: clearSearch,
            ),

            const SizedBox(height: 20),

            if (searchController.text.isNotEmpty)
              TranslationCard(
                nicobarese:
                    result != null ? result!['nicobarese'] : "Word not found",
                english: result != null ? result!['english'] : "",
                isError: result == null,
                onPlayAudio: result != null && result!['audio'] != null
                    ? () => audioService.play(result!['audio'])
                    : null,
              ),

            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Common Classroom Phrases",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 10),

            Column(
              children: commonPhrases.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      audioService.playAsset(p["audio"]!);
                    },
                    child: Text("${p["text"]} (tribal lang)"),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
