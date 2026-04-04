import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/database_manager.dart';
import '../widgets/background.dart';

class DialectComparisonScreen extends StatefulWidget {
  const DialectComparisonScreen({super.key});

  @override
  State<DialectComparisonScreen> createState() => _DialectComparisonScreenState();
}

class _DialectComparisonScreenState extends State<DialectComparisonScreen> {
  List<Map<String, dynamic>> allDialects = [];
  List<Map<String, dynamic>> filteredDialects = [];
  bool isLoading = true;
  String searchQuery = '';

  // Which dialect columns to show
  final List<String> dialectNames = ['car', 'central', 'coast', 'teressa', 'chowra'];
  final Map<String, String> dialectLabels = {
    'car': '🏝️ Car',
    'central': '🌴 Central',
    'coast': '🌊 Coast',
    'teressa': '⛰️ Teressa',
    'chowra': '🐚 Chowra',
  };

  @override
  void initState() {
    super.initState();
    _loadDialects();
  }

  Future<void> _loadDialects() async {
    final data = await DatabaseManager.instance.getAllDialects();
    setState(() {
      allDialects = data;
      filteredDialects = data;
      isLoading = false;
    });
  }

  void _filterDialects(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredDialects = allDialects;
      } else {
        filteredDialects = allDialects.where((d) {
          final english = (d['english'] ?? '').toString().toLowerCase();
          return english.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌏 Dialect Comparison'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: Background(
        colors: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: TextField(
                onChanged: _filterDialects,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search English word...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.white54),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : filteredDialects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language, size: 64, color: Colors.white30),
                              const SizedBox(height: 12),
                              Text(
                                searchQuery.isEmpty
                                    ? 'No dialect data available yet.\nDialect entries will appear here.'
                                    : 'No results for "$searchQuery"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredDialects.length,
                          itemBuilder: (context, index) {
                            final entry = filteredDialects[index];
                            return _buildDialectCard(entry, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialectCard(Map<String, dynamic> entry, int index) {
    final english = entry['english']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // English word header
          Text(
            english,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Dialect translations in a grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dialectNames.map((dialect) {
              final translation = entry[dialect]?.toString() ?? '—';
              final label = dialectLabels[dialect] ?? dialect;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      translation,
                      style: TextStyle(
                        fontSize: 14,
                        color: translation == '—' ? Colors.white24 : Colors.greenAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate(delay: (50 * index).ms).fadeIn(duration: 300.ms).slideX(begin: 0.1);
  }
}
