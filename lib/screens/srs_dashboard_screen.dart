import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/database_manager.dart';
import '../widgets/background.dart';
import 'package:speechmate/core/app_strings.dart';

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
      appBar: AppBar(
        title: const Text('📊 SRS Dashboard'),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
      ),
      body: Background(
        colors: const [Color(0xFF6C63FF), Color(0xFF3F3D56)],
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView(
                children: [
                  // === Stats Row ===
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat(
                          '🔥 Due Now',
                          dueCount.toString(),
                          Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniStat(
                          '📚 Total Cards',
                          totalCards.toString(),
                          Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniStat(
                          '🧠 Retention',
                          '$retentionPercent%',
                          Colors.greenAccent,
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
                          ? const Center(
                              child: Text(
                                'No flashcards yet.\nSave words to start learning!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 16),
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
                                    color: Colors.redAccent,
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: distribution['learning']!.toDouble(),
                                    title: 'Learning\n${distribution['learning']}',
                                    color: Colors.amberAccent,
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: distribution['mature']!.toDouble(),
                                    title: 'Mature\n${distribution['mature']}',
                                    color: Colors.greenAccent,
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // === Review CTA Button ===
                  if (dueCount > 0)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('Review $dueCount Cards Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
