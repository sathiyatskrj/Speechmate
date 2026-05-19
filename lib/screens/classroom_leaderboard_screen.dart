import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline classroom leaderboard using SharedPreferences.
/// Teachers can view class-wide rankings based on quiz scores, words learned,
/// and streak data — all stored locally for island school environments.
class ClassroomLeaderboardScreen extends StatefulWidget {
  const ClassroomLeaderboardScreen({super.key});

  @override
  State<ClassroomLeaderboardScreen> createState() => _ClassroomLeaderboardScreenState();
}

class _ClassroomLeaderboardScreenState extends State<ClassroomLeaderboardScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _sortBy = 'score'; // 'score', 'words', 'streak'

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('classroom_leaderboard') ?? '[]';
    try {
      final List<dynamic> parsed = json.decode(raw);
      final students = parsed.map((e) => Map<String, dynamic>.from(e)).toList();
      
      // If empty, seed with demo data for first launch
      if (students.isEmpty) {
        final demo = _generateDemoData();
        await prefs.setString('classroom_leaderboard', json.encode(demo));
        if (mounted) setState(() { _students = demo; _isLoading = false; });
      } else {
        if (mounted) setState(() { _students = students; _isLoading = false; });
      }
    } catch (e) {
      debugPrint('[Leaderboard] Parse error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
    _sortStudents();
  }

  List<Map<String, dynamic>> _generateDemoData() {
    return [
      {'name': 'Asha K.', 'score': 920, 'words': 87, 'streak': 12, 'avatar': '🌺'},
      {'name': 'Ravi M.', 'score': 850, 'words': 73, 'streak': 8, 'avatar': '🐬'},
      {'name': 'Priya S.', 'score': 810, 'words': 65, 'streak': 15, 'avatar': '🦋'},
      {'name': 'Ajay T.', 'score': 780, 'words': 60, 'streak': 5, 'avatar': '🐢'},
      {'name': 'Meena R.', 'score': 720, 'words': 55, 'streak': 9, 'avatar': '🌴'},
      {'name': 'Kiran D.', 'score': 680, 'words': 48, 'streak': 3, 'avatar': '🐠'},
      {'name': 'Lakshmi V.', 'score': 640, 'words': 42, 'streak': 7, 'avatar': '🌸'},
      {'name': 'Suresh N.', 'score': 580, 'words': 38, 'streak': 2, 'avatar': '🦜'},
    ];
  }

  void _sortStudents() {
    setState(() {
      _students.sort((a, b) {
        final va = a[_sortBy] ?? 0;
        final vb = b[_sortBy] ?? 0;
        return (vb as int).compareTo(va as int);
      });
    });
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0: return const Color(0xFFFFD700); // Gold
      case 1: return const Color(0xFFC0C0C0); // Silver
      case 2: return const Color(0xFFCD7F32); // Bronze
      default: return const Color(0xFF4ECDC4);
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 0: return '🥇';
      case 1: return '🥈';
      case 2: return '🥉';
      default: return '${rank + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1628),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Classroom Leaderboard',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1628), Color(0xFF132742), Color(0xFF1B3A5C)],
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : Column(
                    children: [
                      const SizedBox(height: 8),

                      // Sort toggle
                      _buildSortToggle(),

                      const SizedBox(height: 16),

                      // Top 3 podium
                      if (_students.length >= 3) _buildPodium(),

                      const SizedBox(height: 16),

                      // Full list
                      Expanded(child: _buildList()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _sortChip('Score', 'score', Icons.star_rounded),
          const SizedBox(width: 8),
          _sortChip('Words', 'words', Icons.abc_rounded),
          const SizedBox(width: 8),
          _sortChip('Streak', 'streak', Icons.local_fire_department_rounded),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _sortChip(String label, String key, IconData icon) {
    final isSelected = _sortBy == key;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = key);
        _sortStudents();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.cyanAccent : Colors.white54),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: isSelected ? Colors.cyanAccent : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          _buildPodiumItem(_students[1], 1, 90),
          const SizedBox(width: 8),
          // 1st place
          _buildPodiumItem(_students[0], 0, 120),
          const SizedBox(width: 8),
          // 3rd place
          _buildPodiumItem(_students[2], 2, 70),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildPodiumItem(Map<String, dynamic> student, int rank, double height) {
    final color = _getRankColor(rank);
    return Expanded(
      child: Column(
        children: [
          Text(student['avatar'] ?? '👤', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            student['name'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${student[_sortBy] ?? 0}',
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.15)],
                ),
                border: Border(top: BorderSide(color: color, width: 3)),
              ),
              child: Center(
                child: Text(_getRankEmoji(rank), style: const TextStyle(fontSize: 28)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final rankColor = _getRankColor(index);

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: index < 3 ? rankColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 36,
                    child: Text(
                      _getRankEmoji(index),
                      style: TextStyle(fontSize: index < 3 ? 22 : 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Avatar
                  Text(student['avatar'] ?? '👤', style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),

                  // Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'] ?? 'Student',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${student['words'] ?? 0} words · ${student['streak'] ?? 0}🔥 streak',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: rankColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${student[_sortBy] ?? 0}',
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
      },
    );
  }
}
