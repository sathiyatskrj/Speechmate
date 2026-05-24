import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/widgets/tap_scale.dart';

// ────── DUOLINGO-STYLE VIBRANT LIGHT PALETTE ──────
class _DuoColors {
  static const bg = Color(0xFFF7F7F7);
  static const white = Color(0xFFFFFFFF);
  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF4CAD00);
  static const blue = Color(0xFF1CB0F6);
  static const orange = Color(0xFFFF9600);
  static const textDark = Color(0xFF3C3C3C);
  static const textMuted = Color(0xFF777777);
  static const border = Color(0xFFE5E5E5);
  static const cardShadow = Color(0x0A000000);
}

class DialectComparisonScreen extends StatefulWidget {
  const DialectComparisonScreen({super.key});

  @override
  State<DialectComparisonScreen> createState() => _DialectComparisonScreenState();
}

class _DialectComparisonScreenState extends State<DialectComparisonScreen> {
  final TtsService _ttsService = TtsService();
  List<Map<String, dynamic>> allDialects = [];
  List<Map<String, dynamic>> filteredDialects = [];
  bool isLoading = true;
  String searchQuery = '';

  // Which dialect columns to show
  final List<String> dialectNames = ['car', 'central', 'coast', 'teressa', 'chowra'];
  final Map<String, String> dialectLabels = {
    'car': '🏝️ Car',
    'central': '🌴 Central',
    'coast': '🌊 Coast',
    'teressa': '⛰️ Teressa',
    'chowra': '🐚 Chowra',
  };

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadDialects();
  }

  Future<void> _loadDialects() async {
    final data = await DatabaseManager.instance.getAllDialects();
    setState(() {
      allDialects = data;
      filteredDialects = data;
      isLoading = false;
    });
  }

  void _filterDialects(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredDialects = allDialects;
      } else {
        filteredDialects = allDialects.where((d) {
          final english = (d['english'] ?? '').toString().toLowerCase();
          return english.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DuoColors.bg,
      appBar: AppBar(
        backgroundColor: _DuoColors.white,
        foregroundColor: _DuoColors.textDark,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: _DuoColors.border, width: 2)),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌏', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text('Dialect Comparison', style: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w800, color: _DuoColors.textDark,
            )),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _DuoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _DuoColors.border, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: _DuoColors.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: TextField(
                  onChanged: _filterDialects,
                  style: GoogleFonts.inter(
                    color: _DuoColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search English words...',
                    hintStyle: GoogleFonts.inter(
                      color: _DuoColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search_rounded, color: _DuoColors.textMuted),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: _DuoColors.green))
                    : filteredDialects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.language_rounded, size: 64, color: _DuoColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'No dialect data available yet.'
                                      : 'No results found for "$searchQuery"',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: _DuoColors.textMuted,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredDialects.length,
                            itemBuilder: (context, index) {
                              final entry = filteredDialects[index];
                              return _buildDialectCard(entry, index);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialectCard(Map<String, dynamic> entry, int index) {
    final english = entry['english']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DuoColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DuoColors.border, width: 2),
        boxShadow: const [
          BoxShadow(color: _DuoColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // English word header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _DuoColors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ENGLISH',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _DuoColors.blue,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                english,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _DuoColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _DuoColors.border, height: 1, thickness: 1.5),
          const SizedBox(height: 16),

          // Dialect translations in a grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: dialectNames.map((dialect) {
              final translation = entry[dialect]?.toString() ?? '—';
              final label = dialectLabels[dialect] ?? dialect;
              final hasTranslation = translation != '—' && translation.isNotEmpty;

              return TapScale(
                onTap: hasTranslation
                    ? () {
                        _ttsService.speakNicobarese(translation, englishWord: english);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: hasTranslation ? _DuoColors.white : _DuoColors.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasTranslation ? _DuoColors.green.withOpacity(0.3) : _DuoColors.border,
                      width: 2,
                    ),
                    boxShadow: hasTranslation
                        ? [
                            BoxShadow(
                              color: _DuoColors.green.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _DuoColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            translation,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: hasTranslation ? _DuoColors.greenDark : _DuoColors.textMuted.withOpacity(0.5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (hasTranslation) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.volume_up_rounded,
                          size: 16,
                          color: _DuoColors.green,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate(delay: (50 * index).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }
}
