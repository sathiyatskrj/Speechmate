import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';
import '../widgets/background.dart';

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
      appBar: AppBar(
        title: const Text("Your Progress"),
        backgroundColor: const Color(0xFF38BDF8),
        elevation: 0,
      ),
      body: Background(
        colors: const [Color(0xFF38BDF8), Color(0xFF94FFF8)],
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView(
                children: [
                  _buildStatCard(
                    icon: Icons.search,
                    title: "Total Searches",
                    value: searchCount.toString(),
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildStatCard(
                    icon: Icons.local_fire_department,
                    title: "Current Streak",
                    value: "$streak days",
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildStatCard(
                    icon: Icons.school,
                    title: "Words Learned",
                    value: wordsLearned.toString(),
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    "📊 Quiz History",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  
                  if (quizScores.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "No quizzes completed yet. Start learning!",
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...quizScores.reversed.take(5).map((score) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Quiz Score:", style: TextStyle(fontWeight: FontWeight.w500)),
                            Text(score, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
