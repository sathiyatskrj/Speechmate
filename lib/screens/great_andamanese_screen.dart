import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/database_manager.dart';
import '../widgets/background.dart';
import 'package:speechmate/core/app_colors.dart';

class GreatAndamaneseScreen extends StatefulWidget {
  const GreatAndamaneseScreen({super.key});

  @override
  State<GreatAndamaneseScreen> createState() => _GreatAndamaneseScreenState();
}

class _GreatAndamaneseScreenState extends State<GreatAndamaneseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> allWords = [];
  List<Map<String, dynamic>> filteredWords = [];
  List<Map<String, dynamic>> phrases = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedPOS;

  final List<String> posFilters = [
    'All', 'Noun', 'Verb', 'Adjective', 'Adverb', 'Deixis', 'Postposition'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseManager.instance;
    final words = await db.getGADictionary();
    final ph = await db.getGAPhrases();
    setState(() {
      allWords = words;
      filteredWords = words;
      phrases = ph;
      isLoading = false;
    });
  }

  void _filterWords(String query) {
    setState(() {
      searchQuery = query;
      _applyFilters();
    });
  }

  void _filterByPOS(String? pos) {
    setState(() {
      selectedPOS = (pos == 'All') ? null : pos;
      _applyFilters();
    });
  }

  void _applyFilters() {
    filteredWords = allWords.where((w) {
      final english = (w['english'] ?? '').toString().toLowerCase();
      final ga = (w['great_andamanese'] ?? '').toString().toLowerCase();
      final pos = (w['pos'] ?? '').toString();
      final matchesSearch = searchQuery.isEmpty ||
          english.contains(searchQuery.toLowerCase()) ||
          ga.contains(searchQuery.toLowerCase());
      final matchesPOS = selectedPOS == null || pos == selectedPOS;
      return matchesSearch && matchesPOS;
    }).toList();
  }

  Future<void> _addToFlashcards(String english, String ga) async {
    await DatabaseManager.instance.saveGAFlashcard(english, ga);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "$english" added to flashcards!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏝️ Great Andamanese'),
        backgroundColor: const Color(0xFF4A148C),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          tabs: [
            Tab(text: '📖 Dictionary (${filteredWords.length})'),
            Tab(text: '💬 Phrases (${phrases.length})'),
          ],
        ),
      ),
      body: Background(
        colors: const [Color(0xFF4A148C), Color(0xFF1A237E)],
        padding: EdgeInsets.zero,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDictionaryTab(),
                  _buildPhrasesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildDictionaryTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: TextField(
              onChanged: _filterWords,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search English or Great Andamanese...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white54),
              ),
            ),
          ),
        ),

        // POS Filter chips
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: posFilters.length,
            itemBuilder: (context, index) {
              final pos = posFilters[index];
              final isSelected = (selectedPOS == null && pos == 'All') ||
                  selectedPOS == pos;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(pos, style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12,
                  )),
                  selected: isSelected,
                  onSelected: (_) => _filterByPOS(pos),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  selectedColor: Colors.deepPurpleAccent,
                  checkmarkColor: Colors.white,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Word list
        Expanded(
          child: filteredWords.isEmpty
              ? const Center(
                  child: Text('No results found',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredWords.length,
                  itemBuilder: (context, index) {
                    return _buildWordCard(filteredWords[index], index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWordCard(Map<String, dynamic> word, int index) {
    final english = word['english']?.toString() ?? '';
    final ga = word['great_andamanese']?.toString() ?? '';
    final pos = word['pos']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(english,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Text(ga,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    )),
                if (pos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(pos,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          )),
                    ),
                  ),
              ],
            ),
          ),
          // Add to flashcards button
          IconButton(
            onPressed: () => _addToFlashcards(english, ga),
            icon: const Icon(Icons.bookmark_add_outlined,
                color: Colors.amberAccent),
            tooltip: 'Add to Flashcards',
          ),
        ],
      ),
    ).animate(delay: (30 * (index % 20)).ms).fadeIn(duration: 250.ms);
  }

  Widget _buildPhrasesTab() {
    if (phrases.isEmpty) {
      return const Center(
        child: Text('No phrases available',
            style: TextStyle(color: Colors.white54, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: phrases.length,
      itemBuilder: (context, index) {
        final phrase = phrases[index];
        final english = phrase['english']?.toString() ?? '';
        final ga = phrase['great_andamanese']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.withOpacity(0.3),
                Colors.indigo.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ga,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    Text(english,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        )),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _addToFlashcards(english, ga),
                icon: const Icon(Icons.bookmark_add_outlined,
                    color: Colors.amberAccent, size: 28),
              ),
            ],
          ),
        ).animate(delay: (80 * index).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1);
      },
    );
  }
}
