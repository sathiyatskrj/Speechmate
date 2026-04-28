import 'package:flutter/material.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:speechmate/screens/community_screen.dart';
import 'package:speechmate/screens/quiz_screen.dart';
import 'package:speechmate/screens/progress_screen.dart';
import 'package:speechmate/screens/chat_translate_screen.dart';
import 'package:speechmate/screens/teacher_levels_screen.dart';
import 'package:speechmate/screens/beta_chat_screen.dart';
import 'package:speechmate/screens/common_phrases_screen.dart';
import 'package:speechmate/screens/voice_vault_screen.dart';
import 'package:speechmate/screens/culture_screen.dart';
import 'package:speechmate/widgets/translation_card.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/report_generator.dart';
import 'package:speechmate/services/p2p_sync_service.dart';
import 'dart:ui';
import 'package:speechmate/widgets/smart_dashboard_header.dart';
import 'package:speechmate/widgets/voice_assistant_dialog.dart';
import 'package:speechmate/core/app_theme.dart';
import 'package:speechmate/mixins/searchable_dashboard_mixin.dart';
import 'package:speechmate/screens/feedback_screen.dart';
import 'package:speechmate/screens/camera_translation_screen.dart';
import 'package:speechmate/screens/voice_translator_screen.dart';
import 'package:speechmate/screens/dictionary_editor_screen.dart';
import 'package:speechmate/screens/great_andamanese_screen.dart';
import 'package:speechmate/screens/flora_fauna_screen.dart';
import 'package:speechmate/screens/story_radio_screen.dart';
import 'package:speechmate/screens/kinship_mapper_screen.dart';
import 'package:speechmate/screens/dialect_heatmap_screen.dart';
import 'package:speechmate/screens/memory_palace_screen.dart';
import 'package:speechmate/screens/dialect_comparison_screen.dart';
import 'package:speechmate/screens/srs_dashboard_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:speechmate/widgets/tap_scale.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    _ttsService.dispose();
    disposeMixinSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.teacherTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // Lighter, clean background
        body: Stack(
          children: [
            // Elegant Light Background Gradients
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blueAccent.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purpleAccent.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Main Content
            SafeArea(
              child: Column(
                children: [
                  SmartDashboardHeader(
                    isTeacher: true,
                    searchController: _searchController,
                    onSearch: _onSearch,
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
                                 ).animate().fadeIn().scale(curve: Curves.easeOutBack),
                               ),

                      // ────── CLASSROOM TOOLS SECTION (Bento Grid) ──────
                      _buildSectionHeader(AppStrings.get('classroomTools'), Icons.class_rounded, Colors.orangeAccent),
                      const SizedBox(height: 12),
                      StaggeredGrid.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        children: [
                          StaggeredGridTile.count(
                            crossAxisCellCount: 4, mainAxisCellCount: 2,
                            child: _buildFeatureCard(context, 0, title: AppStrings.get('generateReport'), icon: Icons.picture_as_pdf_outlined, color: Colors.deepOrangeAccent, onTap: () async => await ReportGenerator.generateAndPrintReport("Student")),
                          ),
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2, mainAxisCellCount: 3,
                            child: _buildFeatureCard(context, 1, title: AppStrings.get('bookScanner'), icon: Icons.document_scanner_rounded, color: Colors.cyanAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraTranslationScreen()))),
                          ),
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2, mainAxisCellCount: 2,
                            child: _buildFeatureCard(context, 2, title: AppStrings.get('dictEditor'), icon: Icons.edit_note_rounded, color: Colors.blueAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DictionaryEditorScreen()))),
                          ),
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2, mainAxisCellCount: 1,
                            child: _buildFeatureCard(context, 3, title: AppStrings.get('importVocab'), icon: Icons.download_rounded, color: Colors.cyan, onTap: () => _showImportDialog()),
                          ),
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2, mainAxisCellCount: 2,
                            child: _buildFeatureCard(context, 4, title: AppStrings.get('voiceTranslate'), icon: Icons.record_voice_over_rounded, color: Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceTranslatorScreen()))),
                          ),
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2, mainAxisCellCount: 2,
                            child: _buildFeatureCard(context, 5, title: AppStrings.get('textTranslator'), icon: Icons.translate, color: Colors.orangeAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatTranslateScreen()))),
                          ),
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2, mainAxisCellCount: 2,
                            child: _buildFeatureCard(context, 6, title: AppStrings.get('voiceVault'), icon: Icons.mic, color: Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceVaultScreen()))),
                          ),
                          StaggeredGridTile.count(
                            crossAxisCellCount: 2, mainAxisCellCount: 2,
                            child: _buildFeatureCard(context, 7, title: AppStrings.get('culture'), icon: Icons.account_balance, color: Colors.tealAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CultureScreen()))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ────── LEARNING TOOLS SECTION (Bento Grid) ──────
                      _buildSectionHeader(AppStrings.get('learningTools'), Icons.school_rounded, Colors.purpleAccent),
                      const SizedBox(height: 12),
                      StaggeredGrid.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        children: [
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 0, title: AppStrings.get('certification'), icon: Icons.verified, color: Colors.amberAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLevelsScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 1, title: AppStrings.get('quizMode'), icon: Icons.quiz, color: Colors.purpleAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 4, mainAxisCellCount: 2, child: _buildFeatureCard(context, 2, title: AppStrings.get('srsAnalytics'), icon: Icons.bar_chart_rounded, color: Colors.deepPurple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SRSDashboardScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 3, title: AppStrings.get('progress'), icon: Icons.bar_chart, color: Colors.greenAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 4, title: AppStrings.get('commonPhrases'), icon: Icons.chat_bubble_outline, color: Colors.pinkAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommonPhrasesScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 4, mainAxisCellCount: 2, child: _buildFeatureCard(context, 5, title: AppStrings.get('andamaneseBeta'), icon: Icons.language_rounded, color: Colors.deepPurpleAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GreatAndamaneseScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 6, title: AppStrings.get('natureHub'), icon: Icons.eco_rounded, color: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FloraFaunaScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 7, title: AppStrings.get('oralHistory'), icon: Icons.radio_rounded, color: Colors.brown, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryRadioScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 8, title: AppStrings.get('dialectComparison'), icon: Icons.compare_arrows_rounded, color: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DialectComparisonScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 9, title: AppStrings.get('islandGis'), icon: Icons.explore_rounded, color: Colors.blueGrey, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DialectHeatmapScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 10, title: AppStrings.get('tuhetMapper'), icon: Icons.account_tree_rounded, color: Colors.deepOrange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KinshipMapperScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 11, title: AppStrings.get('villageHub'), icon: Icons.map_rounded, color: Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryPalaceScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 4, mainAxisCellCount: 2, child: _buildFeatureCard(context, 12, title: AppStrings.get('whisperPro'), icon: Icons.auto_awesome_rounded, color: Colors.cyan, onTap: () async {
                              final result = await VoiceAssistantDialog.show(context);
                              if (result != null && result.isNotEmpty) {
                                  _searchController.text = result;
                                  _onSearch(result);
                              }
                          })),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ────── COMMUNITY & SETTINGS SECTION (Bento Grid) ──────
                      _buildSectionHeader(AppStrings.get('communitySettings'), Icons.people_alt_rounded, Colors.blueAccent),
                      const SizedBox(height: 12),
                      StaggeredGrid.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        children: [
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 0, title: AppStrings.get('community'), icon: Icons.public, color: Colors.blueAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 1, title: AppStrings.get('betaChat'), icon: Icons.forum, color: Colors.indigoAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BetaChatScreen(isStudent: false))))),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 2, title: AppStrings.get('exportVocab'), icon: Icons.share_rounded, color: Colors.lightGreenAccent, onTap: () async { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating ZIP Payload...'))); await P2PSyncService.exportAndShare(); })),
                          StaggeredGridTile.count(crossAxisCellCount: 2, mainAxisCellCount: 2, child: _buildFeatureCard(context, 3, title: AppStrings.get('feedback'), icon: Icons.rate_review, color: Colors.pinkAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen())))),
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
            color: color.withValues(alpha: 0.15),
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
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(AppStrings.get('dailyWord'), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 10),
          Text(word['english'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(word['nicobarese'] ?? '', style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, int index, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return TapScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6), // Frosty white glass
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            ),
            child: Stack(
              children: [
                // Background icon glow
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(icon, size: 80, color: color.withValues(alpha: 0.08)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const Spacer(),
                      Text(
                        title, 
                        style: const TextStyle(
                          color: Colors.black87, // Dark text for light mode
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 40).ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
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
