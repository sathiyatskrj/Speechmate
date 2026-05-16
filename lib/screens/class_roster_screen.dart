import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// M1-01: Class Roster Management (inspired by EduAI students module).
/// Teachers create student profiles, assign classes, and track progress.
/// Data persisted locally in SharedPreferences for offline-first operation.
class ClassRosterScreen extends StatefulWidget {
  const ClassRosterScreen({super.key});

  @override
  State<ClassRosterScreen> createState() => _ClassRosterScreenState();
}

class _ClassRosterScreenState extends State<ClassRosterScreen> {
  List<Map<String, dynamic>> _students = [];
  String _selectedClass = 'All';
  final List<String> _classes = ['All', 'Class 5', 'Class 6', 'Class 7', 'Class 8'];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('class_roster') ?? '[]';
    try {
      final list = jsonDecode(raw) as List;
      if (mounted) setState(() => _students = list.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _saveStudents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('class_roster', jsonEncode(_students));
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_selectedClass == 'All') return _students;
    return _students.where((s) => s['class'] == _selectedClass).toList();
  }

  void _addStudent() {
    final nameCtrl = TextEditingController();
    String cls = 'Class 5';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Student', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Student name',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true, fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: cls,
                dropdownColor: const Color(0xFF1E293B),
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _classes.where((c) => c != 'All').map((c) => DropdownMenuItem(
                  value: c, child: Text(c, style: const TextStyle(color: Colors.white)),
                )).toList(),
                onChanged: (v) => setDialogState(() => cls = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _students.add({
                    'name': nameCtrl.text.trim(),
                    'class': cls,
                    'wordsLearned': 0,
                    'quizScore': 0,
                    'streak': 0,
                    'status': 'New',
                    'addedAt': DateTime.now().toIso8601String(),
                  });
                });
                _saveStudents();
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Excellent': return const Color(0xFF10B981);
      case 'Good': return const Color(0xFF3B82F6);
      case 'Needs Attention': return const Color(0xFFEF4444);
      case 'Average': return const Color(0xFFF59E0B);
      default: return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStudents;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Class Roster', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22)),
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.person_add_rounded, color: Color(0xFF2DD4BF)), onPressed: _addStudent),
        ],
      ),
      body: Column(
        children: [
          // Class filter chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _classes.length,
              itemBuilder: (_, i) {
                final isActive = _classes[i] == _selectedClass;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_classes[i]),
                    selected: isActive,
                    selectedColor: const Color(0xFF0D9488),
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w600, fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedClass = _classes[i]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Summary bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildMiniStat('Total', '${filtered.length}', const Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                _buildMiniStat('Active', '${filtered.where((s) => s['status'] != 'New').length}', const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _buildMiniStat('At Risk', '${filtered.where((s) => s['status'] == 'Needs Attention').length}', const Color(0xFFEF4444)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Student list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, color: Colors.white.withOpacity(0.2), size: 64),
                        const SizedBox(height: 16),
                        Text('No students yet', style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Tap + to add your first student', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildStudentCard(filtered[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    final statusColor = _statusColor(student['status'] ?? 'New');
    final isDanger = student['status'] == 'Needs Attention';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDanger ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Text(
                    (student['name'] ?? '?')[0].toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student['name'] ?? '', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(student['class'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(student['status'] ?? 'New', style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 4),
                    Text('${student['wordsLearned'] ?? 0} words', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideX(begin: 0.08, delay: (index * 80).ms, duration: 350.ms).fadeIn();
  }
}
