import 'package:flutter/material.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/widgets/background.dart';

class FloraFaunaScreen extends StatefulWidget {
  const FloraFaunaScreen({super.key});

  @override
  State<FloraFaunaScreen> createState() => _FloraFaunaScreenState();
}

class _FloraFaunaScreenState extends State<FloraFaunaScreen> {
  final DatabaseManager _db = DatabaseManager.instance;
  final FlutterTts _tts = FlutterTts();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final results = await _db.queryAll('flora_fauna');
    setState(() {
      _items = results;
      _isLoading = false;
    });
  }

  Future<void> _playNativeName(String nativeName) async {
    // In production, this would play 'audio_asset'
    await _tts.speak(nativeName);
  }

  @override
  Widget build(BuildContext context) {
    // Group items by category
    final Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in _items) {
      final String category = item['category'] ?? 'Other';
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Flora & Fauna 🌿", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Background(colors: [Color(0xFF1B5E20), Color(0xFF004D40)]),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                : _items.isEmpty
                    ? const Center(child: Text("No entries found yet.", style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedItems.keys.length,
                        itemBuilder: (context, index) {
                          final category = groupedItems.keys.elementAt(index);
                          final items = groupedItems[category]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  category.toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5),
                                ),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, itemIndex) {
                                  final item = items[itemIndex];
                                  return _buildNatureCard(item);
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNatureCard(Map<String, dynamic> item) {
    return Card(
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _showDetailsDialog(item);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.eco, size: 40, color: Colors.greenAccent)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .shimmer(duration: const Duration(seconds: 2)),
              ),
              const SizedBox(height: 12),
              Text(
                item['native_name'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                item['english_name'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.amberAccent),
                onPressed: () => _playNativeName(item['native_name'] ?? ''),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  void _showDetailsDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF003322),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(item['native_name'] ?? '', style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Common: ${item['english_name']}", style: const TextStyle(color: Colors.white)),
              Text("Scientific: ${item['scientific_name']}", style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              const Text("Traditional Use:", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(item['traditional_use'] ?? '', style: const TextStyle(color: Colors.white, height: 1.5)),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () => _playNativeName(item['native_name'] ?? ''),
              icon: const Icon(Icons.volume_up),
              label: const Text("Listen"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.white54)),
            )
          ],
        );
      },
    );
  }
}
