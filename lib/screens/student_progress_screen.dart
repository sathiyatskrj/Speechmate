import 'package:flutter/material.dart';
import 'package:speechmate/services/dictionary_service.dart';
import '../widgets/background.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> with SingleTickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  
  int _searchCount = 0;
  int _wordsLearned = 0;
  int _streak = 0;
  List<String> _quizScores = [];
  
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final searchCount = await _progressService.getSearchCount();
    final wordsLearned = await _progressService.getWordsLearnedCount();
    final streak = await _progressService.getStreak();
    final quizScores = await _progressService.getQuizScores();
    
    if (mounted) {
      setState(() {
        _searchCount = searchCount;
        _wordsLearned = wordsLearned;
        _streak = streak;
        _quizScores = quizScores;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalProgress = (_wordsLearned / 100).clamp(0.0, 1.0);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My Progress", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Background(
        colors: const [Color(0xFFFFDEE9), Color(0xFFB5FFFC)],
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // Main Progress Card
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
                          const SizedBox(height: 15),
                          Text(
                            "$_wordsLearned",
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            "Words Learned",
                            style: TextStyle(fontSize: 18, color: Colors.white70, letterSpacing: 1),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: totalProgress * _progressAnimation.value,
                              minHeight: 8,
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${(totalProgress * 100).toInt()}% to Language Master",
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 25),
                
                // Stats Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(
                      icon: Icons.search,
                      label: "Searches",
                      value: "$_searchCount",
                      color: Colors.blueAccent,
                    ),
                    _buildStatCard(
                      icon: Icons.local_fire_department,
                      label: "Day Streak",
                      value: "$_streak",
                      color: Colors.orangeAccent,
                    ),
                    _buildStatCard(
                      icon: Icons.quiz,
                      label: "Quizzes",
                      value: "${_quizScores.length}",
                      color: Colors.purpleAccent,
                    ),
                    _buildStatCard(
                      icon: Icons.star,
                      label: "Achievements",
                      value: "${_getAchievementCount()}",
                      color: Colors.amber,
                    ),
                  ],
                ),
                
                const SizedBox(height: 25),
                
                // Achievements Section
                const Text(
                  "ACHIEVEMENTS",
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildAchievement(
                        icon: Icons.celebration,
                        title: "First Steps",
                        description: "Learned your first word",
                        unlocked: _wordsLearned > 0,
                      ),
                      _buildAchievement(
                        icon: Icons.local_fire_department,
                        title: "Dedicated Learner",
                        description: "Maintain a 7-day streak",
                        unlocked: _streak >= 7,
                      ),
                      _buildAchievement(
                        icon: Icons.school,
                        title: "Scholar",
                        description: "Learn 50 words",
                        unlocked: _wordsLearned >= 50,
                      ),
                      _buildAchievement(
                        icon: Icons.emoji_events,
                        title: "Language Master",
                        description: "Learn 100 words",
                        unlocked: _wordsLearned >= 100,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement({
    required IconData icon,
    required String title,
    required String description,
    required bool unlocked,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: unlocked ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: unlocked ? Colors.amber : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: unlocked ? Colors.black87 : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: unlocked ? Colors.black54 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  int _getAchievementCount() {
    int count = 0;
    if (_wordsLearned > 0) count++;
    if (_streak >= 7) count++;
    if (_wordsLearned >= 50) count++;
    if (_wordsLearned >= 100) count++;
    return count;
  }
}
