import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// M1-02: Quiz Analytics Dashboard (inspired by EduAI stats page).
/// Shows class averages, weak word identification, and performance trends.
class QuizAnalyticsScreen extends StatefulWidget {
  const QuizAnalyticsScreen({super.key});

  @override
  State<QuizAnalyticsScreen> createState() => _QuizAnalyticsScreenState();
}

class _QuizAnalyticsScreenState extends State<QuizAnalyticsScreen> {
  // Demo stats — in production these pull from quiz_results table
  final List<Map<String, dynamic>> _classStats = [
    {'class': 'Class 5', 'avg': 78, 'trend': '+5%', 'students': 12, 'topWord': 'Mak (Water)', 'weakWord': 'Kanyaw (Fish)'},
    {'class': 'Class 6', 'avg': 65, 'trend': '-3%', 'students': 15, 'topWord': 'Hīn (House)', 'weakWord': 'Takanam (Help)'},
    {'class': 'Class 7', 'avg': 82, 'trend': '+8%', 'students': 10, 'topWord': 'Musté (Hello)', 'weakWord': 'Inta (Where)'},
    {'class': 'Class 8', 'avg': 71, 'trend': '+2%', 'students': 8, 'topWord': 'Asé (Thanks)', 'weakWord': 'Isol (Sun)'},
  ];

  final List<Map<String, dynamic>> _alerts = [
    {'priority': 92, 'type': 'danger', 'msg': 'Class 6 average dropped below 70% — review "Directions" category'},
    {'priority': 78, 'type': 'warning', 'msg': '3 students in Class 5 scored below 50% on last quiz'},
    {'priority': 55, 'type': 'info', 'msg': 'Class 7 has the highest improvement rate this month (+8%)'},
  ];

  @override
  Widget build(BuildContext context) {
    final overallAvg = _classStats.map((s) => s['avg'] as int).reduce((a, b) => a + b) ~/ _classStats.length;
    final totalStudents = _classStats.map((s) => s['students'] as int).reduce((a, b) => a + b);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Quiz Analytics', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards row
            Row(
              children: [
                _buildStatCard('Overall Avg', '$overallAvg%', const Color(0xFF10B981), Icons.trending_up_rounded),
                const SizedBox(width: 12),
                _buildStatCard('Students', '$totalStudents', const Color(0xFF3B82F6), Icons.people_rounded),
                const SizedBox(width: 12),
                _buildStatCard('Quizzes', '${_classStats.length * 3}', const Color(0xFF8B5CF6), Icons.quiz_rounded),
              ],
            ).animate().fadeIn().slideY(begin: -0.1),
            const SizedBox(height: 24),

            // Priority alerts (from EduAI pattern)
            Text('PRIORITY ALERTS', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 2,
            )),
            const SizedBox(height: 10),
            ..._alerts.asMap().entries.map((e) => _buildAlertCard(e.value, e.key)),
            const SizedBox(height: 24),

            // Per-class breakdown
            Text('CLASS BREAKDOWN', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 2,
            )),
            const SizedBox(height: 10),
            ..._classStats.asMap().entries.map((e) => _buildClassCard(e.value, e.key)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, int index) {
    final Color borderColor;
    final Color bgColor;
    final String badge;
    switch (alert['type']) {
      case 'danger':
        borderColor = const Color(0xFFEF4444); bgColor = const Color(0xFFEF4444).withOpacity(0.08); badge = 'URGENT';
      case 'warning':
        borderColor = const Color(0xFFF59E0B); bgColor = const Color(0xFFF59E0B).withOpacity(0.08); badge = 'MEDIUM';
      default:
        borderColor = const Color(0xFF0D9488); bgColor = const Color(0xFF0D9488).withOpacity(0.08); badge = 'INFO';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge, style: TextStyle(fontSize: 9, color: borderColor, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(alert['msg'], style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.4))),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.05);
  }

  Widget _buildClassCard(Map<String, dynamic> cls, int index) {
    final avg = cls['avg'] as int;
    final barColor = avg >= 75 ? const Color(0xFF10B981) : avg >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cls['class'], style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cls['trend'].toString().startsWith('+') ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(cls['trend'], style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: cls['trend'].toString().startsWith('+') ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: avg / 100, minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Avg: $avg%', style: TextStyle(fontSize: 12, color: barColor, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${cls['students']} students', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniTag('✅ ${cls['topWord']}', const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _miniTag('⚠️ ${cls['weakWord']}', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 120).ms).slideY(begin: 0.05);
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
