import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// M1-03: Marks Entry Screen (ported from EduAI marks module).
/// Teachers can enter Nicobarese vocabulary quiz scores per student.
/// Saved locally for offline-first operation.
class MarksEntryScreen extends StatefulWidget {
  const MarksEntryScreen({super.key});

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  String _selectedAssessment = 'Weekly Quiz';
  String _selectedClass = 'Class 5';
  bool _isSaving = false;
  bool _saved = false;

  final List<String> _assessments = ['Weekly Quiz', 'Monthly Test', 'Unit Test 1', 'Midterm', 'Final Exam'];
  final List<String> _classes = ['Class 5', 'Class 6', 'Class 7', 'Class 8'];

  // Student marks data
  List<Map<String, dynamic>> _studentMarks = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('class_roster') ?? '[]';
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final filtered = list.where((s) => s['class'] == _selectedClass).toList();
      if (filtered.isEmpty) {
        // Fallback demo students if no roster exists
        setState(() => _studentMarks = [
          {'name': 'Student 1', 'score': '', 'maxScore': '100'},
          {'name': 'Student 2', 'score': '', 'maxScore': '100'},
          {'name': 'Student 3', 'score': '', 'maxScore': '100'},
        ]);
      } else {
        setState(() => _studentMarks = filtered.map((s) => {
          'name': s['name'] ?? 'Unknown',
          'score': '',
          'maxScore': '100',
        }).toList());
      }
    } catch (_) {}
  }

  Future<void> _saveMarks() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate save
    final prefs = await SharedPreferences.getInstance();
    final key = 'marks_${_selectedClass}_${_selectedAssessment}';
    await prefs.setString(key, jsonEncode(_studentMarks));
    if (mounted) {
      setState(() { _isSaving = false; _saved = true; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Marks saved for $_selectedClass — $_selectedAssessment'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Marks Entry', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22)),
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_saved ? Icons.check_circle : Icons.save_rounded,
              color: _saved ? const Color(0xFF10B981) : const Color(0xFF2DD4BF)),
            onPressed: _isSaving ? null : _saveMarks,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Assessment & Class selectors
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assessment', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedAssessment,
                        dropdownColor: const Color(0xFF1E293B),
                        decoration: InputDecoration(
                          filled: true, fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: _assessments.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (v) => setState(() { _selectedAssessment = v!; _saved = false; }),
                      ),
                      const SizedBox(height: 14),
                      Text('Class', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedClass,
                        dropdownColor: const Color(0xFF1E293B),
                        decoration: InputDecoration(
                          filled: true, fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (v) { setState(() { _selectedClass = v!; _saved = false; }); _loadStudents(); },
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().slideY(begin: -0.1, duration: 400.ms).fadeIn(),
            const SizedBox(height: 20),

            // Student mark entries
            ..._studentMarks.asMap().entries.map((e) => _buildMarkEntry(e.key, e.value)),

            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF2DD4BF)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkEntry(int index, Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF0D9488).withOpacity(0.2),
                  child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(student['name'], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                    onChanged: (val) {
                      _studentMarks[index]['score'] = val;
                      setState(() => _saved = false);
                    },
                    decoration: InputDecoration(
                      hintText: '—',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
                      filled: true, fillColor: Colors.white.withOpacity(0.06),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text('/100', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms, duration: 350.ms);
  }
}
