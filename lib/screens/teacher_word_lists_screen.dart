import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M1-05: Teacher-curated custom word lists for classroom use.
/// Teachers create named lists, add words, and push them to students.
class TeacherWordListsScreen extends StatefulWidget {
  const TeacherWordListsScreen({super.key});

  @override
  State<TeacherWordListsScreen> createState() => _TeacherWordListsScreenState();
}

class _TeacherWordListsScreenState extends State<TeacherWordListsScreen> {
  List<Map<String, dynamic>> _wordLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('teacher_word_lists') ?? '[]';
    try {
      final parsed = (json.decode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) setState(() { _wordLists = parsed; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('teacher_word_lists', json.encode(_wordLists));
  }

  void _createNewList() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Word List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Week 3 — Animals',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _wordLists.add({
                    'name': controller.text.trim(),
                    'created': DateTime.now().toIso8601String(),
                    'words': <Map<String, dynamic>>[],
                    'assigned': false,
                  });
                });
                _saveLists();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _addWordToList(int listIndex) {
    final engController = TextEditingController();
    final nicController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Word', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: engController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'English',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nicController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nicobarese',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              if (engController.text.trim().isNotEmpty) {
                setState(() {
                  (_wordLists[listIndex]['words'] as List).add({
                    'english': engController.text.trim(),
                    'nicobarese': nicController.text.trim(),
                  });
                });
                _saveLists();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleAssign(int index) {
    setState(() {
      _wordLists[index]['assigned'] = !(_wordLists[index]['assigned'] ?? false);
    });
    _saveLists();
    final status = _wordLists[index]['assigned'] ? 'Assigned' : 'Unassigned';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$status: ${_wordLists[index]['name']}'), behavior: SnackBarBehavior.floating),
    );
  }

  void _deleteList(int index) {
    setState(() => _wordLists.removeAt(index));
    _saveLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Custom Word Lists', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewList,
        backgroundColor: const Color(0xFF0D9488),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New List', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _wordLists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.playlist_add_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('No word lists yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Tap + to create a custom vocabulary list', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _wordLists.length,
                  itemBuilder: (context, index) {
                    final list = _wordLists[index];
                    final words = (list['words'] as List?) ?? [];
                    final isAssigned = list['assigned'] == true;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isAssigned ? const Color(0xFF0D9488).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.playlist_play_rounded, color: isAssigned ? const Color(0xFF0D9488) : Colors.white54, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(list['name'] ?? 'Untitled', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                        Text('${words.length} words', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (isAssigned)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('ASSIGNED', style: TextStyle(color: Color(0xFF0D9488), fontSize: 10, fontWeight: FontWeight.w800)),
                                    ),
                                ],
                              ),
                              if (words.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: words.take(6).map((w) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(w['english'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                  )).toList(),
                                ),
                                if (words.length > 6)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('+${words.length - 6} more', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                                  ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _addWordToList(index),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add Word'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.cyanAccent,
                                        side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _toggleAssign(index),
                                    icon: Icon(isAssigned ? Icons.send_rounded : Icons.send_outlined, color: const Color(0xFF0D9488), size: 20),
                                    tooltip: isAssigned ? 'Unassign' : 'Assign to students',
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteList(index),
                                    icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.6), size: 20),
                                    tooltip: 'Delete list',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).slideY(begin: 0.1);
                  },
                ),
    );
  }
}
