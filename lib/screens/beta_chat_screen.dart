
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/dictionary_service.dart';

class BetaChatScreen extends StatefulWidget {
  final bool isStudent;

  const BetaChatScreen({super.key, required this.isStudent});

  @override
  State<BetaChatScreen> createState() => _BetaChatScreenState();
}

class _BetaChatScreenState extends State<BetaChatScreen> {
  final DictionaryService _dictionaryService = DictionaryService();
  final FlutterTts _flutterTts = FlutterTts();
  List<Map<String, dynamic>> _allDialects = [];
  List<Map<String, dynamic>> _filteredDialects = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US"); // Default context for TTS
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadData() async {
    final data = await _dictionaryService.getDialectItems();
    setState(() {
      _allDialects = data;
      _filteredDialects = data;
      _isLoading = false;
    });
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredDialects = _allDialects);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredDialects = _allDialects.where((item) {
        return (item['english']?.toString().toLowerCase() ?? '').contains(q);
      }).toList();
    });
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty || text == '-') return;
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.isStudent ? _studentTheme : _teacherTheme;
    final bgColor = widget.isStudent ? const Color(0xFFF0F4F8) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Beta Chat: Nicobar Dialects",
          style: TextStyle(
            color: widget.isStudent ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: widget.isStudent ? const Color(0xFFFF6B6B) : Colors.white,
        elevation: widget.isStudent ? 4 : 1,
        iconTheme: IconThemeData(
          color: widget.isStudent ? Colors.white : Colors.black87,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filter,
                    decoration: InputDecoration(
                      hintText: "Search English word...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(widget.isStudent ? 30 : 8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                
                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredDialects.length,
                    itemBuilder: (context, index) {
                      final item = _filteredDialects[index];
                      return widget.isStudent
                          ? _buildStudentCard(item)
                          : _buildTeacherRow(item);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // --- Student UI (Colorful, Card-based) ---
  final _studentTheme = ThemeData(
    primaryColor: const Color(0xFFFF6B6B),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
    ),
  );

  Widget _buildStudentCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          item['english'] ?? 'Unknown',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFEAA7),
          child: Text(
            (item['english'] ?? "?")[0],
            style: const TextStyle(color: Color(0xFFD63031), fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          _buildDialectRow("Primary (Car)", item['car'], const Color(0xFF55EFC4)),
          _buildDialectRow("Central", item['central'], const Color(0xFF81ECEC)),
          _buildDialectRow("Coast", item['coast'], const Color(0xFF74B9FF)),
          _buildDialectRow("Teressa", item['teressa'], const Color(0xFFA29BFE)),
          _buildDialectRow("Chowra", item['chowra'], const Color(0xFFFF7675)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDialectRow(String label, String? value, Color color) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, size: 20, color: Colors.grey),
            onPressed: () => _speak(value),
          ),
        ],
      ),
    );
  }

  // --- Teacher UI (Professional, Dense) ---
  final _teacherTheme = ThemeData(
    primaryColor: Colors.blueGrey,
    cardTheme: const CardTheme(elevation: 1),
  );

  Widget _buildTeacherRow(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(
          item['english'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        subtitle: Text("Car: ${item['car'] ?? '-'}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {0: FixedColumnWidth(100)},
              children: [
                _buildTableCell("Central", item['central']),
                _buildTableCell("Coast", item['coast']),
                _buildTableCell("Teressa", item['teressa']),
                _buildTableCell("Chowra", item['chowra']),
                _buildTableCell("Car Nicobar", item['car']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableCell(String label, String? value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(value ?? '-')),
              if (value != null && value.isNotEmpty && value != '-')
                InkWell(
                   onTap: () => _speak(value),
                   child: const Icon(Icons.volume_up, size: 16, color: Colors.blueGrey),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
