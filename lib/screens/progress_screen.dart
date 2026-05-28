import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/progress_service.dart';
import 'package:speechmate/core/app_colors.dart';
import 'package:speechmate/core/app_strings.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService progressService = ProgressService();
  
  int searchCount = 0;
  int streak = 0;
  int wordsLearned = 0;
  List<String> quizScores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => isLoading = true);
    
    final searches = await progressService.getSearchCount();
    final currentStreak = await progressService.getStreak();
    final learned = await progressService.getWordsLearnedCount();
    final scores = await progressService.getQuizScores();

    setState(() {
      searchCount = searches;
      streak = currentStreak;
      wordsLearned = learned;
      quizScores = scores;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              AppStrings.get('yourProgress'),
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
                  _buildStatCard(
                    icon: Icons.search_rounded,
                    title: AppStrings.get('totalSearches'),
                    value: searchCount.toString(),
                    iconColor: AndamanPalette.oceanTeal,
                    bgColor: AndamanPalette.oceanTealSoft,
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                  
                  _buildStatCard(
                    icon: Icons.local_fire_department_rounded,
                    title: AppStrings.get('currentStreak'),
                    value: "$streak ${AppStrings.get('days')}",
                    iconColor: AndamanPalette.amber,
                    bgColor: AndamanPalette.amberSoft,
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                  
                  Hero(
                    tag: 'flashcard_hero',
                    child: Material(
                      color: Colors.transparent,
                      child: _buildStatCard(
                        icon: Icons.school_rounded,
                        title: AppStrings.get('wordsLearned'),
                        value: wordsLearned.toString(),
                        iconColor: AndamanPalette.emerald,
                        bgColor: AndamanPalette.emeraldSoft,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      const Text("📈", style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        "Recent Quiz Performance",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AndamanPalette.stone,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                  const SizedBox(height: 16),
                  
                  if (quizScores.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AndamanPalette.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AndamanPalette.border, width: 2),
                      ),
                      child: Text(
                        "No quizzes completed yet. Start learning!",
                        style: GoogleFonts.inter(
                          color: AndamanPalette.mist,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 300.ms)
                  else
                    Container(
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Quiz Accuracy",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AndamanPalette.stone,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceEvenly,
                                maxY: 1.0,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) => AndamanPalette.oceanTeal,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${(rod.toY * 100).round()}%',
                                        GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Q${value.toInt() + 1}',
                                            style: GoogleFonts.inter(
                                              color: AndamanPalette.mist,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                                barGroups: quizScores.reversed.take(6).toList().reversed.toList().asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  String scoreStr = entry.value;
                                  double percentage = 0.0;
                                  try {
                                    final parts = scoreStr.split('/');
                                    if (parts.length == 2 && double.parse(parts[1]) > 0) {
                                      percentage = double.parse(parts[0]) / double.parse(parts[1]);
                                    }
                                  } catch (e) { debugPrint('Silent error caught: $e'); }

                                  return BarChartGroupData(
                                    x: idx,
                                    barRods: [
                                      BarChartRodData(
                                        toY: percentage,
                                        color: AndamanPalette.oceanTeal,
                                        width: 22,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          topRight: Radius.circular(6),
                                        ),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: 1.0,
                                          color: AndamanPalette.oceanTealSoft,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 300.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AndamanPalette.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AndamanPalette.border, width: 2),
        boxShadow: const [
          BoxShadow(color: AndamanPalette.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AndamanPalette.stoneLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AndamanPalette.stone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
