import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';
import '../services/progress_service.dart';
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
                  const SizedBox(height: 32),
                  
                  const Text(
                    "📊 Recent Quiz Performance",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 150,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: quizScores.reversed.take(6).map((scoreString) {
                                // Parse e.g., "4/5" string
                                double percentage = 0.0;
                                try {
                                  final parts = scoreString.split('/');
                                  if (parts.length == 2) {
                                    percentage = double.parse(parts[0]) / double.parse(parts[1]);
                                  }
                                } catch (_) {}
                                
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(scoreString, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutQuart,
                                      width: 30,
                                      height: percentage * 100 + 10, // min height 10
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.blue.shade400,
                                            Colors.blue.shade300.withOpacity(percentage),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList().reversed.toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int i = 0; i < (quizScores.length > 6 ? 6 : quizScores.length); i++)
                                Text("Q${i+1}", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
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
