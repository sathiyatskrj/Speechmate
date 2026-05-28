import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/linguistics_service.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import 'package:speechmate/core/app_colors.dart';

class DynamicCategoryScreen extends StatefulWidget {
  final String categoryId;
  final String title;
  final List<Color> bgColors;
  
  const DynamicCategoryScreen({
    super.key,
    required this.categoryId,
    required this.title,
    this.bgColors = const [Color(0xFFff9a9e), Color(0xFFfad0c4)],
  });

  @override
  State<DynamicCategoryScreen> createState() => _DynamicCategoryScreenState();
}

class _DynamicCategoryScreenState extends State<DynamicCategoryScreen> {
  final TtsService _ttsService = TtsService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadData();
    LinguisticsService.instance.loadCorpus(); // Prepare linguistic engine
  }

  Future<void> _loadData() async {
     try {
       final data = await DatabaseManager.instance.getWordsByCategory(widget.categoryId);
       if (mounted) {
         setState(() {
           _items = data;
           _isLoading = false;
         });
       }
     } catch (e) {
       debugPrint("Error loading category ${widget.categoryId}: $e");
       if (mounted) {
         setState(() => _isLoading = false);
       }
     }
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _playAudio(Map<String, dynamic> item) async {
    final english = item['english']?.toString() ?? '';
    final nicobarese = item['nicobarese']?.toString() ?? '';
    final audioField = item['audio']?.toString() ?? '';

    if (audioField.isNotEmpty) {
      if (audioField.contains('/')) {
        final parts = audioField.split('/');
        if (parts.length >= 2) {
          final success = await _ttsService.playFromCategory(parts[0], parts[1]);
          if (success) return;
        }
      } else {
        final success = await _ttsService.playFromCategory(widget.categoryId, audioField);
        if (success) return;
      }
    }

    await _ttsService.speakNicobarese(
      nicobarese.isNotEmpty ? nicobarese : english,
      englishWord: english,
    );
  }

  void _showLinguisticAnalysis(Map<String, dynamic> item) {
    _playAudio(item); // Play audio immediately when tapped
    
    final english = item['english']?.toString() ?? '';
    final nicobarese = item['nicobarese']?.toString() ?? '';
    if (nicobarese.isEmpty) return;

    final analysis = LinguisticsService.instance.analyzeWord(english, nicobarese);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AndamanPalette.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: AndamanPalette.shadow, blurRadius: 20, offset: Offset(0, -5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AndamanPalette.borderStrong, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nicobarese,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AndamanPalette.stone,
                      ),
                    ),
                    Text(
                      english,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: AndamanPalette.oceanTeal,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: AndamanPalette.oceanTealSoft,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: AndamanPalette.oceanTeal, size: 28),
                    onPressed: () => _playAudio(item),
                  ),
                ).animate().scale(delay: 300.ms, duration: 400.ms),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AndamanPalette.border, thickness: 1.5, height: 30),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildAnalysisSection(
                    '1. Phonology (Sounds)', 
                    Icons.graphic_eq_rounded,
                    'Syllables: ${analysis.phonology.syllableCount}\n'
                    'Breakdown: ${analysis.phonology.syllables.join(" - ")}\n'
                    'Difficulty: ${List.filled(analysis.phonology.difficulty, "★").join()}${List.filled(5 - analysis.phonology.difficulty, "☆").join()}'
                  ),
                  _buildAnalysisSection(
                    '2. Morphology (Structure)', 
                    Icons.account_tree_rounded,
                    'Root: ${analysis.morphology.root}\n'
                    '${analysis.morphology.isCompound ? "Compound word: ${analysis.morphology.compoundParts.join(' + ')}" : "Simple word structure"}\n'
                    '${analysis.morphology.prefixes.isNotEmpty ? "Prefixes: ${analysis.morphology.prefixes.join(', ')} (${analysis.morphology.prefixMeanings.join(', ')})" : ""}'
                  ),
                  _buildAnalysisSection(
                    '3. Semantics (Meaning)', 
                    Icons.bubble_chart_rounded,
                    'Semantic Field: ${analysis.semanticField ?? "General"}\n'
                    '${analysis.pragmatics?.note ?? ""}'
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(String title, IconData icon, String content) {
    if (content.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AndamanPalette.mangrove,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AndamanPalette.borderTeal.withOpacity(0.5), width: 1.5),
          boxShadow: const [
            BoxShadow(color: AndamanPalette.shadow, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AndamanPalette.oceanTeal, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AndamanPalette.stone,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.inter(
                color: AndamanPalette.stoneLight,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
    );
  }

  String? _getImagePath(Map<String, dynamic> item) {
    final image = item['image']?.toString();
    if (image != null && image.isNotEmpty && image != 'null') {
      return image;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AndamanPalette.sandWhite,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AndamanPalette.stone,
          ),
        ),
        centerTitle: true,
        backgroundColor: AndamanPalette.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AndamanPalette.border, width: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AndamanPalette.stone),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AndamanPalette.oceanTeal))
          : _items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox_rounded, size: 64, color: AndamanPalette.mist),
                    const SizedBox(height: 16),
                    Text(
                      "No items found in ${widget.title}.\nPlease restart the app.",
                      style: GoogleFonts.inter(
                        color: AndamanPalette.mist,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : GridView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return _buildCard(item, index);
          },
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final english = item['english']?.toString() ?? '';
    final nicobarese = item['nicobarese']?.toString() ?? '';
    final emoji = item['emoji']?.toString() ?? '';
    final imagePath = _getImagePath(item);
    final hasAudio = (item['audio']?.toString() ?? '').isNotEmpty;

    return TapScale(
      onTap: () => _showLinguisticAnalysis(item),
      child: Container(
        decoration: BoxDecoration(
          color: AndamanPalette.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AndamanPalette.border, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AndamanPalette.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: AndamanPalette.mangrove,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: imagePath != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Text(
                            emoji.isNotEmpty ? emoji : '📝',
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      )
                    : Text(
                        emoji.isNotEmpty ? emoji : '📝',
                        style: const TextStyle(fontSize: 50),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(1, 1), 
                        end: const Offset(1.1, 1.1), 
                        duration: 2.seconds,
                      ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      english,
                      style: GoogleFonts.inter(
                        color: AndamanPalette.stone,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nicobarese,
                      style: GoogleFonts.inter(
                        color: AndamanPalette.oceanTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontStyle: FontStyle.italic
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasAudio)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.volume_up_rounded, color: AndamanPalette.oceanTeal, size: 16),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().slideY(
            begin: 0.5,
            duration: 500.ms,
            delay: Duration(milliseconds: (index % 10) * 100),
            curve: Curves.easeOutBack,
          ).fade(),
    );
  }
}
