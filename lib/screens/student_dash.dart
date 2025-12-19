import 'package:flutter/material.dart';
import '../widgets/background.dart';
import '../widgets/search_bar.dart';
import '../widgets/translation_card.dart';
import '../services/dictionary_service.dart';
import '../services/audio_service.dart';
import 'nature_screen.dart';
import 'numbers_screen.dart';

class StudentDash extends StatefulWidget {
  const StudentDash({super.key});

  @override
  State<StudentDash> createState() => _StudentDashState();
}

class _StudentDashState extends State<StudentDash> {
  final TextEditingController searchController = TextEditingController();
  final DictionaryService dictionaryService = DictionaryService();
  final AudioService audioService = AudioService();

  Map<String, dynamic>? result;

  final List<Map<String, String>> learnCategories = [
    {"title": "Nature", "emoji": "🌿", "route": "nature"},
    {"title": "Numbers", "emoji": "🔢", "route": "numbers"},
    {"title": "My Body", "emoji": "🧍"},
    {"title": "Feelings", "emoji": "😊"},
    {"title": "Family", "emoji": "👨‍👩‍👧"},
    {"title": "Animals", "emoji": "🐾"},
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
        colors: const [Color(0xFF94FFF8), Color(0xFF38BDF8)],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "English → Nicobarese",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 25),

              Search(
                controller: searchController,
                onSearch: performSearch,
                onClear: clearSearch,
              ),

              SizedBox(height: 20),

              if (searchController.text.isNotEmpty)
                TranslationCard(
                  nicobarese:
                      result != null ? result!['nicobarese'] : "Word not found",
                  english: result != null ? result!['english'] : "",
                  isError: result == null,
                  onPlayAudio: result != null && result!['audio'] != null
                      ? () => audioService.playAsset(result!['audio'])
                      : null,
                ),

              SizedBox(height: 35),

              Text(
                "Learn",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 15),

              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: learnCategories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final item = learnCategories[index];

                  return InkWell(
                    onTap: () {
                      if (item['route'] == 'nature') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NatureScreen(),
                          ),
                        );
                      } else if (item['route'] == 'numbers') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NumbersScreen(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text("${item['title']} coming soon"),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['emoji']!,
                            style: TextStyle(fontSize: 36),
                          ),
                          SizedBox(height: 10),
                          Text(
                            item['title']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
