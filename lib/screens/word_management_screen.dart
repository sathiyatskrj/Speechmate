import 'package:flutter/material.dart';
import '../services/dictionary_service.dart';
import '../widgets/background.dart';
import '../core/app_colors.dart';

class WordManagementScreen extends StatefulWidget {
  const WordManagementScreen({super.key});

  @override
  State<WordManagementScreen> createState() => _WordManagementScreenState();
}

class _WordManagementScreenState extends State<WordManagementScreen> {
  final DictionaryService _dictionaryService = DictionaryService();
  List<Map<String, dynamic>> _words = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await _dictionaryService.getDictionary(DictionaryType.words);
    setState(() {
      _words = words;
      _isLoading = false;
    });
  }

  void _showAddWordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Word"),
        content: const Text("Word editing and SQLite storage coming in Phase 3 update!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: AppColors.teacherAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Manage Dictionary", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWordDialog,
        backgroundColor: AppColors.teacherAccent,
        child: const Icon(Icons.add, color: AppColors.teacherPrimary),
      ),
      body: Background(
        colors: AppColors.teacherGradient,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.teacherAccent))
              : _words.isEmpty
                  ? const Center(child: Text("No words found.", style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _words.length,
                      itemBuilder: (context, index) {
                        final word = _words[index];
                        return Card(
                          color: AppColors.teacherSurface,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.teacherAccent.withOpacity(0.2),
                              child: const Icon(Icons.book, color: AppColors.teacherAccent),
                            ),
                            title: Text(
                              word['english'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              word['nicobarese'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white54),
                              onPressed: _showAddWordDialog,
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
