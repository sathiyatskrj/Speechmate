import 'package:flutter/material.dart';
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/screens/quiz_screen.dart';
import 'package:speechmate/screens/progress_screen.dart';
import 'package:speechmate/screens/chat_translate_screen.dart';
import 'package:speechmate/screens/teacher_levels_screen.dart';
import 'package:speechmate/screens/beta_chat_screen.dart';
import 'package:speechmate/screens/common_phrases_screen.dart';
import 'package:speechmate/screens/voice_vault_screen.dart';
import 'package:speechmate/screens/culture_screen.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/report_generator.dart';
import 'package:speechmate/services/p2p_sync_service.dart';
import 'package:speechmate/widgets/smart_dashboard_header.dart';
import 'package:speechmate/widgets/voice_reactive_aurora.dart';
import 'package:speechmate/core/app_theme.dart';
import 'package:speechmate/mixins/searchable_dashboard_mixin.dart';
import 'package:speechmate/screens/feedback_screen.dart';
import 'package:speechmate/screens/camera_translation_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/core/app_colors.dart';

class TeacherDash extends StatefulWidget {
  const TeacherDash({super.key});

  @override
  State<TeacherDash> createState() => _TeacherDashState();
}

class _TeacherDashState extends State<TeacherDash>
    with SearchableDashboardMixin {
  final TextEditingController _searchController = TextEditingController();
  final TtsService _ttsService = TtsService();
  
  Map<String, dynamic>? _dailyWord;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    initSearch();
    _loadDailyWord();
  }

  Future<void> _loadDailyWord() async {
    final daily = await dashSearchDictService.getDailyWord();
    if (mounted) setState(() => _dailyWord = daily);
  }

  Future<void> _onSearch(String query) async {
    FocusScope.of(context).unfocus();
    await performMixinSearch(query);
  }

  void _clearSearch() => clearMixinSearch(_searchController);

  void _showWhisperUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Whisper Pro"),
        content: const Text("Upgrade to unlock advanced speech-to-text capabilities."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    disposeMixinSearch();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.teacherTheme,
      child: Scaffold(
        body: Stack(
          children: [
            VoiceReactiveAurora(
              isDark: true,
              child: Column(
                children: [
                  SmartDashboardHeader(
                    isTeacher: true,
                    searchController: _searchController,
                    onSearch: _onSearch,
                    onClear: _clearSearch,
                    seasonName: "Curriculum",
                    featuredWord: "Focus on learning",
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
                            if (isSearchLoading)
                               const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                            
                            if (!isSearchLoading && hasSearched)
                               Padding(
                                 padding: const EdgeInsets.only(bottom: 25),
                                 child: TranslationCard(
                                    nicobarese: searchResult != null ? searchResult!['nicobarese'] : "No match found",
                                    english: searchResult != null ? (searchResult!['english'] ?? searchResult!['text'] ?? "") : "",
                                    searchedNicobarese: searchedNicobarese,
                                    isError: searchResult == null,
                                    showSpeaker: searchResult != null, 
                                    onSpeak: () {
                                        if (searchResult == null) return;
                                        if (searchedNicobarese) {
                                            _ttsService.speakEnglish(searchResult!['english'] ?? searchResult!['text'] ?? "");
                                        } else {
                                            _ttsService.speakNicobarese(
                                              searchResult!['nicobarese'] ?? "",
                                              englishWord: searchResult!['english'] ?? searchResult!['text']
                                            );
                                        }
                                    },
                                 ),
                               ),

                      // ────── LEARNING TOOLS SECTION ──────
                      _buildSectionHeader("LEARNING TOOLS", Icons.school_rounded, Colors.purpleAccent),
                      const SizedBox(height: 12),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          mainAxisExtent: 110,
                        ),
                        children: [
                          _buildFeatureCard(context,
                            title: "Certification",
                            icon: Icons.verified,
                            color: Colors.amberAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLevelsScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Quiz Mode",
                            icon: Icons.quiz,
                            color: Colors.purpleAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Progress",
                            icon: Icons.bar_chart,
                            color: Colors.greenAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Common Phrases",
                            icon: Icons.chat_bubble_outline,
                            color: Colors.pinkAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommonPhrasesScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Great Andamanese",
                            icon: Icons.language_rounded,
                            color: Colors.deepPurpleAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GreatAndamaneseScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Nature Hub",
                            icon: Icons.eco_rounded,
                            color: Colors.green,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FloraFaunaScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Oral History",
                            icon: Icons.radio_rounded,
                            color: Colors.brown,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryRadioScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Tuhet Mapper",
                            icon: Icons.account_tree_rounded,
                            color: Colors.deepOrange,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KinshipMapperScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Island GIS",
                            icon: Icons.explore_rounded,
                            color: Colors.blueGrey,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DialectHeatmapScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Village Hub",
                            icon: Icons.map_rounded,
                            color: Colors.teal,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryPalaceScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Whisper Pro",
                            icon: Icons.auto_awesome_rounded,
                            color: Colors.cyan,
                            onTap: () => _showWhisperUpgradeDialog(context),
                          ),
                          _buildFeatureCard(context,
                            title: "Dialect Comparison",
                            icon: Icons.compare_arrows_rounded,
                            color: Colors.green,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DialectComparisonScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "SRS Analytics",
                            icon: Icons.bar_chart_rounded,
                            color: Colors.deepPurple,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SRSDashboardScreen())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ────── CLASSROOM TOOLS SECTION ──────
                      _buildSectionHeader("CLASSROOM TOOLS", Icons.class_rounded, Colors.orangeAccent),
                      const SizedBox(height: 12),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          mainAxisExtent: 110,
                        ),
                        children: [
                          _buildFeatureCard(context,
                            title: "Translator",
                            icon: Icons.translate,
                            color: Colors.orangeAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatTranslateScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Voice Vault",
                            icon: Icons.mic,
                            color: Colors.redAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceVaultScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Culture",
                            icon: Icons.account_balance,
                            color: Colors.tealAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CultureScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Generate Report",
                            icon: Icons.picture_as_pdf_outlined,
                            color: Colors.deepOrangeAccent,
                            onTap: () async => await ReportGenerator.generateAndPrintReport("Student"),
                          ),
                          _buildFeatureCard(context,
                            title: "Import Vocab",
                            icon: Icons.download_rounded,
                            color: Colors.cyan,
                            onTap: () => _showImportDialog(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ────── COMMUNITY & SETTINGS SECTION ──────
                      _buildSectionHeader("COMMUNITY & SETTINGS", Icons.people_alt_rounded, Colors.blueAccent),
                      const SizedBox(height: 12),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          mainAxisExtent: 110,
                        ),
                        children: [
                          _buildFeatureCard(context,
                            title: "Community",
                            icon: Icons.public,
                            color: Colors.blueAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())),
                          ),
                          _buildFeatureCard(context,
                            title: "Beta Chat",
                            icon: Icons.forum,
                            color: Colors.indigoAccent,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BetaChatScreen(isStudent: false))),
                          ),
                          _buildFeatureCard(context,
                            title: "Export Vocab",
                            icon: Icons.share_rounded,
                            color: Colors.lightGreenAccent,
                            onTap: () async {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating ZIP Payload...')));
                               await P2PSyncService.exportAndShare();
                            },
                          ),
                          _buildFeatureCard(context,
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
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
        ),
      ],
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

  void _showImportDialog() {
    final TextEditingController pathController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Import Vocabulary 📥"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter the path to the SpeechMate dictionary update (.zip) file:",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                hintText: "/storage/emulated/0/Download/speechmate_update.zip",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_open),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final path = pathController.text.trim();
              if (path.isEmpty) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Importing vocabulary...")),
              );
              try {
                await P2PSyncService.importDictionaryPayload(path);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Vocabulary imported successfully!")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Import failed: $e")),
                  );
                }
              }
            },
            icon: const Icon(Icons.download_done),
            label: const Text("Import"),
          ),
        ],
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
