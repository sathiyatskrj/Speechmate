import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/widgets/background.dart';
import 'package:speechmate/core/app_colors.dart';

class DynamicCategoryScreen extends StatefulWidget {
  final String categoryId;
  final String title;
  final List<Color> bgColors;
  
  const DynamicCategoryScreen({
    super.key,
    required this.categoryId,
    required this.title,
    this.bgColors = const [Color(0xFFff9a9e), Color(0xFFfad0c4)],
  });

  @override
  State<DynamicCategoryScreen> createState() => _DynamicCategoryScreenState();
}

class _DynamicCategoryScreenState extends State<DynamicCategoryScreen> {
  final TtsService _ttsService = TtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
     final data = await DatabaseManager.instance.getWordsByCategory(widget.categoryId);
     if (mounted) {
       setState(() {
         _items = data;
         _isLoading = false;
       });
     }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String audioPath, String fallbackWord, String nicobareseWord) async {
    try {
        if (audioPath.isNotEmpty) {
           if (audioPath.startsWith('http') || audioPath.startsWith('/')) {
              await _audioPlayer.play(DeviceFileSource(audioPath));
           } else {
              // Usually the filename in JSON
              await _audioPlayer.play(AssetSource('audio/${widget.categoryId}/$audioPath'));
           }
        } else {
           _ttsService.speakNicobarese(nicobareseWord.isNotEmpty ? nicobareseWord : fallbackWord); 
        }
    } catch (e) {
        _ttsService.speakNicobarese(nicobareseWord.isNotEmpty ? nicobareseWord : fallbackWord); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.studentAccent.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
              ? const Center(child: Text("No items found in this category."))
              : GridView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.8,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return _buildCard(item, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    return GestureDetector(
      onTap: () => _playAudio(item['audio'] ?? '', item['english'], item['nicobarese']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: AppColors.studentAccent.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Center(
                  child: item['emoji'] != null && item['emoji'].toString().isNotEmpty
                    ? Text(
                        item['emoji'],
                        style: const TextStyle(fontSize: 50),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 2.seconds)
                    : Icon(Icons.star_rounded, size: 50, color: AppColors.studentAccent),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['english'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                     Text(
                      item['nicobarese'],
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontStyle: FontStyle.italic
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().slideY(
            begin: 0.5,
            duration: 500.ms,
            delay: Duration(milliseconds: (index % 10) * 100),
            curve: Curves.easeOutBack,
          ).fade(),
    );
  }
}
