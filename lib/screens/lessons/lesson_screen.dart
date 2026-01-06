import 'package:flutter/material.dart';
import '../../models/lesson_models.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.8,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    
    _configureTts();
    // Auto-play first slide audio after a slight delay
    Future.delayed(const Duration(milliseconds: 800), () {
      _playAudioForSlide(widget.lesson.slides[0]);
    });
  }

  void _configureTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.2); // Higher pitch for kid-friendliness
    await _flutterTts.setSpeechRate(0.8); // Slower rate
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _playAudioForSlide(LessonSlide slide) async {
    // If we had real audio files, we'd play them here.
    // For now, use TTS for English and Nicobarese (approximation)
    await _flutterTts.speak(slide.englishText);
    await Future.delayed(const Duration(milliseconds: 1000));
    await _flutterTts.speak(slide.nicobareseText);
  }

  void _handleTap() {
    _animController.forward(from: 0.0);
    _playAudioForSlide(widget.lesson.slides[_currentIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.lesson.color.withOpacity(0.1),
      appBar: AppBar(
        title: Text(widget.lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.lesson.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.lesson.slides.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _handleTap(); // Auto-play on slide change
        },
        itemBuilder: (context, index) {
          final slide = widget.lesson.slides[index];
          return GestureDetector(
            onTap: _handleTap,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image / Animation Area
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: widget.lesson.color.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getEmojiForSlide(slide.englishText), // Placeholder for image
                          style: const TextStyle(fontSize: 100),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Text Area
                  Text(
                    slide.englishText,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: widget.lesson.color.withOpacity(0.9),
                      letterSpacing: 1.5,
                      fontFamily: 'Comic Sans MS', // Or generic rounded sans
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.lesson.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      slide.nicobareseText,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 30),
              color: widget.lesson.color,
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            // Progress Dots
            Row(
              children: List.generate(
                widget.lesson.slides.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? widget.lesson.color
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 30),
              color: widget.lesson.color,
              onPressed: () {
                 if (_currentIndex < widget.lesson.slides.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                 } else {
                   // Finish Lesson
                   Navigator.pop(context);
                 }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Temporary helper to get emojis since we don't have the explicit asset files yet
  String _getEmojiForSlide(String word) {
    switch (word.toLowerCase()) {
      case 'goat': return '🐐';
      case 'lizard': return '🦎';
      case 'monkey': return '🐒';
      case 'tree': return '🌳';
      case 'sea': return '🌊';
      default: return '✨';
    }
  }
}
