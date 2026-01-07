import 'package:flutter/material.dart';
import 'package:speechmate/screens/word_management_screen.dart';
import 'package:speechmate/screens/about_screen.dart';
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/screens/quiz_screen.dart';
import 'package:speechmate/screens/progress_screen.dart';
import 'package:speechmate/screens/chat_translate_screen.dart';
import 'package:speechmate/screens/teacher_levels_screen.dart';
import 'package:speechmate/screens/beta_chat_screen.dart';
import 'package:speechmate/screens/common_phrases_screen.dart'; // [FIX] Added
import 'package:speechmate/screens/voice_vault_screen.dart'; // [FIX] Added
import 'package:speechmate/screens/culture_screen.dart'; // [FIX] Added
import 'package:speechmate/services/dictionary_service.dart'; // [FIX] Added
import 'package:speechmate/services/tts_service.dart'; // [FIX] Added
import 'package:speechmate/widgets/smart_dashboard_header.dart';
import 'package:speechmate/widgets/voice_reactive_aurora.dart';
import 'package:speechmate/core/app_theme.dart';




import 'package:speechmate/screens/feedback_screen.dart'; // [FIX] Added
import 'package:speechmate/widgets/exit_feedback_dialog.dart'; // [FIX] Added
import 'package:speechmate/services/neural_engine_service.dart'; // [NEW]

class TeacherDash extends StatefulWidget {
  const TeacherDash({super.key});

  @override
  State<TeacherDash> createState() => _TeacherDashState();
}

class _TeacherDashState extends State<TeacherDash> {
  final TextEditingController _searchController = TextEditingController();
  final DictionaryService _dictionaryService = DictionaryService();
  final TtsService _ttsService = TtsService();
  final NeuralEngineService _neuralEngine = NeuralEngineService(); // [NEW]
  // AudioRecorder removed
  
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  bool _searchedNicobarese = false;
  bool _hasSearched = false;
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



  Future<void> _performSearch(String query) async {
    FocusScope.of(context).unfocus();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    // 1. Direct Search
    var searchResult = await _dictionaryService.searchEverywhere(query);
    
    // 2. Neural Engine Fallback
    if (searchResult == null) {
        final neuralResult = await _neuralEngine.predict(query);
        
        if (neuralResult.text.isNotEmpty) {
             searchResult = {
                'english': query,
                'nicobarese': neuralResult.text,
                '_isGenerated': true,
                '_confidence': neuralResult.confidence
             };
        }
    }

    if (mounted) {
      setState(() {
        _result = searchResult;
        _hasSearched = true;
        if (searchResult != null) {
          if (searchResult!.containsKey('_searchedNicobarese')) {
              _searchedNicobarese = searchResult!['_searchedNicobarese'];
          } else if (searchResult!.containsKey('_isGenerated')) {
             _searchedNicobarese = false; 
          } else {
              final q = query.trim().toLowerCase();
              _searchedNicobarese =
                  searchResult!['nicobarese'].toString().toLowerCase() == q;
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
      _hasSearched = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
  // Removed Mic/Whisper logic (now in header)


  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.teacherTheme,
    return Theme(
      data: AppTheme.teacherTheme,
      child: Scaffold(
          body: VoiceReactiveAurora(
            isDark: true,
          child: Column(
            children: [
              SmartDashboardHeader(
                isTeacher: true,
                searchController: _searchController,
                onSearch: _performSearch,
                onClear: _clearSearch,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (_dailyWord != null) ...[
                          _buildDailyWordCard(_dailyWord!),
                          const SizedBox(height: 25),
                        ],
                        if (_isLoading)
                           const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                        
                        if (!_isLoading && _hasSearched)
                           Padding(
                             padding: const EdgeInsets.only(bottom: 25),
                             child: TranslationCard(
                                nicobarese: _result != null ? _result!['nicobarese'] : "No match found",
                                english: _result != null ? (_result!['english'] ?? _result!['text'] ?? "") : "",
                                searchedNicobarese: _searchedNicobarese,
                                isError: _result == null,
                                showSpeaker: _result != null, 
                                onSpeak: () {
                                    if (_result == null) return;
                                    if (_searchedNicobarese) {
                                        _ttsService.speakEnglish(_result!['english'] ?? _result!['text'] ?? "");
                                    } else {
                                        _ttsService.speakNicobarese(
                                          _result!['nicobarese'] ?? "",
                                          englishWord: _result!['english'] ?? _result!['text']
                                        );
                                    }
                                },
                             ),
                           ),
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
                        title: "Certification",
                        icon: Icons.verified,
                        color: Colors.amberAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLevelsScreen())),
                      ),
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
                      _buildFeatureCard(
                        context,
                        title: "Culture",
                        icon: Icons.account_balance,
                        color: Colors.tealAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CultureScreen())),
                      ),
                      _buildFeatureCard(
                        context,
                        title: "Beta Chat",
                        icon: Icons.forum,
                        color: Colors.indigoAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BetaChatScreen(isStudent: false))),
                      ),
                      _buildFeatureCard(
                        context,
                        title: "Feedback",
                        icon: Icons.rate_review,
                        color: Colors.pinkAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
              ],
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
          Text(word['english'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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

class TranslationCard extends StatelessWidget {
  final String nicobarese;
  final String english;
  final bool searchedNicobarese;
  final bool isError;
  final bool showSpeaker;
  final VoidCallback onSpeak;

  const TranslationCard({
    super.key,
    required this.nicobarese,
    required this.english,
    required this.searchedNicobarese,
    this.isError = false,
    this.showSpeaker = true,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isError ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isError ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.2)),
        boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isError ? "Not Found" : (searchedNicobarese ? "English Translation" : "Nicobarese Translation"),
                style: TextStyle(
                  color: isError ? Colors.redAccent : Colors.cyanAccent,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showSpeaker && !isError)
                IconButton(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_rounded, color: Colors.cyanAccent),
                  tooltip: "Pronounce",
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            nicobarese,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          if (!isError && english.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                english,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ]
        ],
      ),
    );
  }
}
