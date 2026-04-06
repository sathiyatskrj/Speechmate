import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/dictionary_service.dart';
import 'package:speechmate/core/app_colors.dart';

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
    if (text == null || text.isEmpty || text == '-') return;
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Dialect Radar - βeta",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
               _seasonService.themeColor.withOpacity(0.8),
               Colors.black
            ]
          )
        ),
        child: SafeArea(
          child: _isLoading
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
        ),
      ),
    );
  }

  // --- Student UI (Colorful, Card-based) ---
  Widget _buildStudentCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white24)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        title: Text(
          item['english'] ?? 'Unknown',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: _seasonService.themeColor.withOpacity(0.5),
          child: Text(
            (item['english'] ?? "?")[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              style: const TextStyle(
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(Icons.volume_up_rounded, size: 20, color: _seasonService.themeColor),
            onPressed: () => _speak(value),
          ),
        ],
      ),
    );
  }

  // --- Teacher UI (Professional, Dense) ---
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
