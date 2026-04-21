import 'package:flutter/material.dart';
import 'package:speechmate/services/database_manager.dart';

class DictionaryEditorScreen extends StatefulWidget {
  const DictionaryEditorScreen({super.key});

  @override
  State<DictionaryEditorScreen> createState() => _DictionaryEditorScreenState();
}

class _DictionaryEditorScreenState extends State<DictionaryEditorScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _words = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseManager.instance.database;
      final result = await db.query('words', where: 'category_id = ?', whereArgs: ['words'], orderBy: 'english ASC', limit: 100);
      setState(() {
        _words = List.from(result);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading dictionary: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchDictionary(String query) async {
    if (query.isEmpty) {
      _loadDictionary();
      return;
    }
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });
    try {
      final db = await DatabaseManager.instance.database;
      final result = await db.query(
        'words',
        where: 'category_id = ? AND (english LIKE ? OR nicobarese LIKE ?)',
        whereArgs: ['words', '%$query%', '%$query%'],
        limit: 100,
      );
      setState(() {
        _words = List.from(result);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Search error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWord(int id) async {
    final db = await DatabaseManager.instance.database;
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
    _loadDictionary();
  }

  void _showEditorDialog({Map<String, dynamic>? existingWord}) {
    final TextEditingController engController = TextEditingController(text: existingWord?['english'] ?? '');
    final TextEditingController nicController = TextEditingController(text: existingWord?['nicobarese'] ?? '');
    final TextEditingController posController = TextEditingController(text: existingWord?['pos'] ?? 'Noun');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3D),
        title: Text(existingWord == null ? "Add New Word" : "Edit Word", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: engController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "English Word", labelStyle: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nicController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Nicobarese Translation", labelStyle: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: posController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Part of Speech (e.g. Noun, Verb)", labelStyle: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () async {
              final eng = engController.text.trim();
              final nic = nicController.text.trim();
              final pos = posController.text.trim();
              
              if (eng.isNotEmpty && nic.isNotEmpty) {
                final db = await DatabaseManager.instance.database;
                if (existingWord == null) {
                  // Insert
                  await db.insert('words', {
                    'category_id': 'words',
                    'english': eng,
                    'nicobarese': nic,
                    // Note: 'pos' column is not in the 'words' schema, so we omit it or adapt
                  });
                } else {
                  // Update
                  await db.update(
                    'words',
                    {'english': eng, 'nicobarese': nic},
                    where: 'id = ?',
                    whereArgs: [existingWord['id']],
                  );
                }
                if (context.mounted) {
                   Navigator.pop(context);
                   _loadDictionary();
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text("Dictionary Editor", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        onPressed: () => _showEditorDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search local database...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                filled: true,
                fillColor: const Color(0xFF2A2A3D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchDictionary,
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              : _words.isEmpty
                ? const Center(child: Text("No words found", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: _words.length,
                    itemBuilder: (context, index) {
                      final word = _words[index];
                      return Card(
                        color: const Color(0xFF2A2A3D),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(word['english'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text("${word['nicobarese']} • ${word['pos']}", style: const TextStyle(color: Colors.cyanAccent)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white54),
                                onPressed: () => _showEditorDialog(existingWord: word),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF2A2A3D),
                                      title: const Text("Delete Word", style: TextStyle(color: Colors.white)),
                                      content: Text("Are you sure you want to delete '${word['english']}'?", style: const TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteWord(word['id']);
                                          }, 
                                          child: const Text("Delete", style: TextStyle(color: Colors.redAccent))
                                        ),
                                      ],
                                    )
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
