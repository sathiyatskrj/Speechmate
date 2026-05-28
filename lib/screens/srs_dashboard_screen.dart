import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_manager.dart';
import 'package:speechmate/core/app_colors.dart';

class SRSDashboardScreen extends StatefulWidget {
  const SRSDashboardScreen({super.key});

  @override
  State<SRSDashboardScreen> createState() => _SRSDashboardScreenState();
}

class _SRSDashboardScreenState extends State<SRSDashboardScreen> {
  bool isLoading = true;
  int dueCount = 0;
  int totalCards = 0;
  double avgEase = 2.5;
  Map<String, int> distribution = {'new': 0, 'learning': 0, 'mature': 0};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = DatabaseManager.instance;
    final due = await db.getDueFlashcardCount();
    final total = await db.getTotalFlashcardCount();
    final ease = await db.getAverageEaseFactor();
    final dist = await db.getFlashcardDistribution();

    setState(() {
      dueCount = due;
      totalCards = total;
      avgEase = ease;
      distribution = dist;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final retentionPercent = avgEase >= 2.5
        ? 90 + ((avgEase - 2.5) * 4).clamp(0, 10).toInt()
        : (60 + (avgEase - 1.3) / (2.5 - 1.3) * 30).toInt().clamp(0, 89);

    return Scaffold(
      backgroundColor: AndamanPalette.sandWhite,
      appBar: AppBar(
        backgroundColor: AndamanPalette.white,
        foregroundColor: AndamanPalette.stone,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AndamanPalette.border, width: 2)),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'SRS Dashboard',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AndamanPalette.stone,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AndamanPalette.oceanTeal))
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  // === Stats Row ===
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat(
                          '🔥 Due Now',
                          dueCount.toString(),
                          AndamanPalette.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniStat(
                          '📚 Total Cards',
                          totalCards.toString(),
                          AndamanPalette.oceanTeal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniStat(
                          '🧠 Retention',
                          '$retentionPercent%',
                          AndamanPalette.emerald,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  // === Distribution Pie Chart ===
                  _buildSection(
                    title: 'Card Distribution',
                    child: SizedBox(
                      height: 200,
                      child: totalCards == 0
                          ? Center(
                              child: Text(
                                'No flashcards yet.\nSave words to start learning!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: AndamanPalette.mist,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(
                                    value: distribution['new']!.toDouble(),
                                    title: 'New\n${distribution['new']}',
                                    color: AndamanPalette.reefCoral,
                                    radius: 50,
                                    titleStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: distribution['learning']!.toDouble(),
                                    title: 'Learning\n${distribution['learning']}',
                                    color: AndamanPalette.amber,
                                    radius: 50,
                                    titleStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: distribution['mature']!.toDouble(),
                                    title: 'Mature\n${distribution['mature']}',
                                    color: AndamanPalette.emerald,
                                    radius: 50,
                                    titleStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 32),

                  // === Review CTA Button ===
                  if (dueCount > 0)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('Review $dueCount Cards Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AndamanPalette.oceanTeal,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AndamanPalette.oceanTeal.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .shimmer(delay: 800.ms, duration: 1500.ms),

                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AndamanPalette.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AndamanPalette.border, width: 2),
        boxShadow: const [
          BoxShadow(color: AndamanPalette.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AndamanPalette.stoneLight,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AndamanPalette.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AndamanPalette.border, width: 2),
        boxShadow: const [
          BoxShadow(color: AndamanPalette.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AndamanPalette.stone,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
