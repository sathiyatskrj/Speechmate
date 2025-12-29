import 'package:flutter/material.dart';
import 'package:speechmate/screens/word_management_screen.dart';
import 'package:speechmate/screens/about_screen.dart';
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/screens/quiz_screen.dart';
import 'package:speechmate/screens/progress_screen.dart';
import 'package:speechmate/screens/chat_translate_screen.dart';
import 'package:speechmate/screens/teacher_levels_screen.dart'; // Assuming this exists or using generic
import '../widgets/background.dart';
import '../widgets/search_bar.dart';
import '../widgets/translation_card.dart';
import '../services/dictionary_service.dart';
import '../services/tts_service.dart';
import 'package:speechmate/screens/common_phrases_screen.dart'; // Placeholder for new screen
import 'package:speechmate/screens/voice_vault_screen.dart'; // Placeholder for Record feature

class TeacherDash extends StatefulWidget {
  const TeacherDash({super.key});

  @override
  State<TeacherDash> createState() => _TeacherDashState();
}

class _TeacherDashState extends State<TeacherDash> {
  final TextEditingController _searchController = TextEditingController();
  final DictionaryService _dictionaryService = DictionaryService();
  final TtsService _ttsService = TtsService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  bool _searchedNicobarese = false;
  Map<String, dynamic>? _dailyWord;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadData();
  }

  Future<void> _loadData() async {
    // CRITICAL: Load dictionaries to prevent crashes
    await _dictionaryService.loadDictionary(DictionaryType.words);
    await _dictionaryService.loadDictionary(DictionaryType.phrases);
    
    // Load Daily Word
    final daily = await _dictionaryService.getDailyWord();
    
    if (mounted) {
      setState(() {
        _dailyWord = daily;
      });
    }
  }

  Future<void> _performSearch() async {
    FocusScope.of(context).unfocus();
    if (_searchController.text.isEmpty) return;

    setState(() => _isLoading = true);

    // 1. Direct Search
    var searchResult = await _dictionaryService.searchEverywhere(
      _searchController.text,
    );
    
    // 2. NLP Translation Fallback
    if (searchResult == null) {
        searchResult = await _dictionaryService.translateSentence(_searchController.text);
    }

    if (mounted) {
      setState(() {
        _result = searchResult;
        if (searchResult != null) {
          if (searchResult!.containsKey('_searchedNicobarese')) {
              _searchedNicobarese = searchResult!['_searchedNicobarese'];
          } else if (searchResult!.containsKey('_isGenerated')) {
             _searchedNicobarese = false; 
          } else {
              final query = _searchController.text.trim().toLowerCase();
              _searchedNicobarese =
                  searchResult!['nicobarese'].toString().toLowerCase() == query;
          }
        } else {
          _searchedNicobarese = false;
        }
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        colors: const [Color(0xFF141E30), Color(0xFF243B55)], // Professional Dark Navy
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: SingleChildScrollView(
             physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Teacher Panel",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Where language barriers end.",
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                
                const SizedBox(height: 25),

                // DAILY WORD
                if (_dailyWord != null)
                  _buildDailyWordCard(_dailyWord!),
                
                const SizedBox(height: 25),

                // TRANSLATION TOOL
                const Text(
                  "QUICK TRANSLATE",
                  style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                   ),
                   child: Column(
                     children: [
                        Search(
                          controller: _searchController, 
                          onSearch: _performSearch, 
                          onClear: _clearSearch, 
                          onMicTap: () {}, 
                        ),
                        if (_isLoading)
                           const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.cyanAccent)),
                        
                        if (_result != null)
                           Padding(
                             padding: const EdgeInsets.only(top: 15),
                             child: TranslationCard(
                                nicobarese: _result!['nicobarese'],
                                english: _result!['english'] ?? _result!['text'] ?? "",
                                searchedNicobarese: _searchedNicobarese,
                                isError: false,
                                showSpeaker: true, 
                                onSpeak: () {
                                    if (_result == null) return;
                                    if (_searchedNicobarese) {
                                        _ttsService.speakEnglish(_result!['english'] ?? _result!['text'] ?? "");
                                    } else {
                                        _ttsService.speakNicobarese(textToSpeak);
                                    }
                                },
                             ),
                           )
                     ],
                   ),
                ),

                const SizedBox(height: 25),

                // FEATURES GRID
                const Text(
                  "TOOLS & RESOURCES",
                  style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 15),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.3,
                  children: [
                    _buildFeatureCard(
                      context,
                      title: "Community",
                      icon: Icons.public,
                      color: Colors.blueAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: "Quiz Mode",
                      icon: Icons.quiz,
                      color: Colors.purpleAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: "Progress",
                      icon: Icons.bar_chart,
                      color: Colors.greenAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: "Translator",
                      icon: Icons.translate,
                      color: Colors.orangeAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatTranslateScreen())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: "Common Phrases",
                      icon: Icons.chat_bubble_outline,
                      color: Colors.pinkAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommonPhrasesScreen())),
                    ),
                    _buildFeatureCard(
                      context,
                      title: "Voice Vault",
                      icon: Icons.mic,
                      color: Colors.redAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceVaultScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyWordCard(Map<String, dynamic> word) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.blue.shade900]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text("DAILY WORD", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 10),
          Text(word['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(word['nicobarese'] ?? '', style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
