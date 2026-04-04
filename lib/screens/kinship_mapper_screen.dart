import 'package:flutter/material.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speechmate/widgets/background.dart';

class KinshipMapperScreen extends StatefulWidget {
  const KinshipMapperScreen({super.key});

  @override
  State<KinshipMapperScreen> createState() => _KinshipMapperScreenState();
}

class _KinshipMapperScreenState extends State<KinshipMapperScreen> {
  final DatabaseManager _db = DatabaseManager.instance;
  final FlutterTts _tts = FlutterTts();
  List<Map<String, dynamic>> _terms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    final results = await _db.queryAll('kinship');
    setState(() {
      _terms = results;
      _isLoading = false;
    });
  }

  Future<void> _playTerm(String term) async {
    await _tts.speak(term);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Kinship Mapper (Tuhet) 🌳", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Background(colors: [Color(0xFF3E2723), Color(0xFF1B5E20)]),
          SafeArea(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        _buildNode('Elder (Mem)', 'Grandparents / Older Siblings', 'mem'),
                        _buildLine(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNode('Parent (Yom)', 'Father / Mother', 'parent'),
                            _buildNode('Spouse (Piha)', 'Partner', 'spouse'),
                          ],
                        ),
                        _buildLine(),
                        _buildNode('Self', 'You', null, isSelf: true),
                        _buildLine(),
                        _buildNode('Younger (Kahem)', 'Siblings / Cousins', 'younger_sibling'),
                        _buildLine(),
                        _buildNode('Child (Kun)', 'The Next Generation', 'child'),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(String title, String subtitle, String? relKey, {bool isSelf = false}) {
    final termData = relKey != null 
        ? _terms.firstWhere((t) => t['rel_key'] == relKey, orElse: () => {})
        : null;
    
    return GestureDetector(
      onTap: () {
        if (termData != null && termData['native_term'] != null) {
          _playTerm(termData['native_term']);
          _showTermDetail(termData);
        }
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelf ? Colors.amberAccent : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelf ? Colors.orange : Colors.white24, width: 2),
          boxShadow: [
            if (isSelf) BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 15)
          ],
        ),
        child: Column(
          children: [
            Icon(
              isSelf ? Icons.person : Icons.people_outline,
              color: isSelf ? Colors.black : Colors.amberAccent,
            ),
            const SizedBox(height: 8),
            Text(
              termData?['native_term'] ?? title,
              style: TextStyle(
                color: isSelf ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              termData?['english_label'] ?? subtitle,
              style: TextStyle(
                color: isSelf ? Colors.black54 : Colors.white54,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().scale(delay: 200.ms),
    );
  }

  Widget _buildLine() {
    return Container(
      width: 2,
      height: 40,
      color: Colors.white24,
    );
  }

  void _showTermDetail(Map<String, dynamic> term) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: Text(term['native_term'], style: const TextStyle(color: Colors.amberAccent, fontSize: 24, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("In English: ${term['english_label']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(term['description'], style: const TextStyle(color: Colors.white70, height: 1.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.amberAccent),
            onPressed: () => _playTerm(term['native_term']),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it", style: TextStyle(color: Colors.cyanAccent)),
          )
        ],
      ),
    );
  }
}
