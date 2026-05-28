import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'class_roster_screen.dart';

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
  bool _hasRoster = true;

  final List<String> _assessments = ['Weekly Quiz', 'Monthly Test', 'Unit Test 1', 'Midterm', 'Final Exam'];
  final List<String> _classes = ['Class 5', 'Class 6', 'Class 7', 'Class 8'];

  // Student marks data
  List<Map<String, dynamic>> _studentMarks = [];
  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _loadStudentsAndMarks();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudentsAndMarks() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Load full roster of students
    final rosterRaw = prefs.getString('class_roster') ?? '[]';
    List<Map<String, dynamic>> roster = [];
    try {
      final decoded = jsonDecode(rosterRaw) as List;
      roster = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {}

    // Filter students by selected class
    final classStudents = roster.where((s) => s['class'] == _selectedClass).toList();

    if (classStudents.isEmpty) {
      setState(() {
        _hasRoster = false;
        _studentMarks = [];
        for (var c in _controllers) {
          c.dispose();
        }
        _controllers = [];
      });
      return;
    }

    // 2. Load existing marks if any exist for this class & assessment
    final key = 'marks_${_selectedClass}_${_selectedAssessment}';
    final savedMarksRaw = prefs.getString(key);
    Map<String, String> savedScores = {};
    if (savedMarksRaw != null) {
      try {
        final decodedSaved = jsonDecode(savedMarksRaw) as List;
        for (var s in decodedSaved) {
          if (s['name'] != null) {
            savedScores[s['name'].toString()] = s['score']?.toString() ?? '';
          }
        }
      } catch (_) {}
    }

    // Dispose old controllers
    for (var c in _controllers) {
      c.dispose();
    }

    // 3. Build merged student marks list and initialize new controllers
    final List<Map<String, dynamic>> merged = [];
    final List<TextEditingController> newControllers = [];

    for (var student in classStudents) {
      final name = student['name'] ?? 'Unknown';
      final score = savedScores[name] ?? '';
      merged.add({
        'name': name,
        'score': score,
        'maxScore': '100',
      });
      newControllers.add(TextEditingController(text: score));
    }

    if (mounted) {
      setState(() {
        _hasRoster = true;
        _studentMarks = merged;
        _controllers = newControllers;
        _saved = savedMarksRaw != null; // mark as saved if loaded from disk
      });
    }
  }

  Future<void> _saveMarks() async {
    if (!_hasRoster) return;
    setState(() => _isSaving = true);
    
    // Update score map from controllers
    for (int i = 0; i < _studentMarks.length; i++) {
      if (i < _controllers.length) {
        _studentMarks[i]['score'] = _controllers[i].text.trim();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final key = 'marks_${_selectedClass}_${_selectedAssessment}';
    await prefs.setString(key, jsonEncode(_studentMarks));

    // Also update average in Class Roster for that student if relevant (Optional advanced feature)
    // To make it complete, let's keep roster stats in sync!
    final rosterRaw = prefs.getString('class_roster') ?? '[]';
    try {
      final rosterList = (jsonDecode(rosterRaw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
      for (var sm in _studentMarks) {
        final double? sc = double.tryParse(sm['score'] ?? '');
        if (sc != null) {
          for (int idx = 0; idx < rosterList.length; idx++) {
            if (rosterList[idx]['name'] == sm['name'] && rosterList[idx]['class'] == _selectedClass) {
              rosterList[idx]['quizScore'] = sc.round();
              // Update status based on score
              if (sc >= 85) {
                rosterList[idx]['status'] = 'Excellent';
              } else if (sc >= 70) {
                rosterList[idx]['status'] = 'Good';
              } else if (sc >= 50) {
                rosterList[idx]['status'] = 'Average';
              } else {
                rosterList[idx]['status'] = 'Needs Attention';
              }
            }
          }
        }
      }
      await prefs.setString('class_roster', jsonEncode(rosterList));
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isSaving = false;
        _saved = true;
      });
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          if (_hasRoster)
            IconButton(
              icon: Icon(
                _saved ? Icons.check_circle : Icons.save_rounded,
                color: _saved ? const Color(0xFF10B981) : const Color(0xFF2DD4BF),
              ),
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
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: _assessments.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedAssessment = v!;
                            _saved = false;
                          });
                          _loadStudentsAndMarks();
                        },
                      ),
                      const SizedBox(height: 14),
                      Text('Class', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedClass,
                        dropdownColor: const Color(0xFF1E293B),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedClass = v!;
                            _saved = false;
                          });
                          _loadStudentsAndMarks();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().slideY(begin: -0.1, duration: 400.ms).fadeIn(),
            const SizedBox(height: 20),

            // Main student score section
            if (!_hasRoster)
              _buildTutorialBanner()
            else ...[
              ...List.generate(
                _studentMarks.length,
                (index) => _buildMarkEntry(index, _studentMarks[index]),
              ),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF2DD4BF)),
                ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.people_outline_rounded, size: 64, color: Colors.orangeAccent),
          const SizedBox(height: 16),
          Text(
            'No Roster Registered 👥',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'To enter marks for $_selectedClass, you first need to add students to this class in the Class Roster management tool.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClassRosterScreen()),
              ).then((_) => _loadStudentsAndMarks());
            },
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Students in Class Roster'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildMarkEntry(int index, Map<String, dynamic> student) {
    if (index >= _controllers.length) return const SizedBox.shrink();
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
                  child: Text(student['name'] ?? '', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _controllers[index],
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                    onChanged: (val) {
                      setState(() => _saved = false);
                    },
                    decoration: InputDecoration(
                      hintText: '—',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
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
