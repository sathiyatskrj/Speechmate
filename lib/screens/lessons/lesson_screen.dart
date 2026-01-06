import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/lesson_models.dart';
import '../../widgets/anim/floating_widget.dart';
import '../../widgets/anim/confetti_overlay.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();
  
  // Animation for the main character (Bounce)
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // Animation for text (Pulse)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _currentIndex = 0;
  bool _isPlayingAudio = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    
    // Setup Bounce (triggered on tap)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.0,
      upperBound: 1.0, 
    );
    _bounceAnimation = CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut);

    // Setup Pulse (Continuous gentle breathing for text)
    _pulseController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    _configureTts();
    
    // Auto-play first slide audio after a slight delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _playAudioForSlide(widget.lesson.slides[0]);
    });
  }

  void _configureTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.3); // Higher pitch for kid-friendliness
    await _flutterTts.setSpeechRate(0.85); // Slower rate
    
    _flutterTts.setStartHandler(() {
      setState(() => _isPlayingAudio = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isPlayingAudio = false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _playAudioForSlide(LessonSlide slide) async {
    if (_isPlayingAudio) return;

    // Trigger bounce
    _bounceController.forward(from: 0.0);

    // Speak
    await _flutterTts.speak(slide.englishText);
    await Future.delayed(const Duration(milliseconds: 800));
    await _flutterTts.speak(slide.nicobareseText);
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      isPlaying: _showConfetti,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.close_rounded, color: widget.lesson.color),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Sound wave indicator
            if (_isPlayingAudio)
               Padding(
                 padding: const EdgeInsets.only(right: 20),
                 child: FloatingWidget(
                   duration: const Duration(milliseconds: 500),
                   distance: 5,
                   child: Icon(Icons.volume_up_rounded, color: widget.lesson.color, size: 30),
                 ),
               )
          ],
        ),
        body: Stack(
          children: [
            // 1. Alive Background (Floating Blobs)
            _buildBackgroundBlobs(),
            
            // 2. Main Content
            PageView.builder(
              controller: _pageController,
              itemCount: widget.lesson.slides.length + 1, // +1 for Completion Page
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                
                if (index < widget.lesson.slides.length) {
                   _playAudioForSlide(widget.lesson.slides[index]);
                } else {
                   // Completion Page Logic
                   setState(() => _showConfetti = true);
                   Future.delayed(const Duration(seconds: 4), () => setState(() => _showConfetti = false));
                   _flutterTts.speak("Great Job! You did it!");
                }
              },
              itemBuilder: (context, index) {
                if (index == widget.lesson.slides.length) {
                  return _buildCompletionPage();
                }
                return _buildSlidePage(widget.lesson.slides[index]);
              },
            ),

            // 3. Bottom controls
             if (_currentIndex < widget.lesson.slides.length)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       // Progress Dots
                       Row(
                        children: List.generate(
                          widget.lesson.slides.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentIndex == i ? 20 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: _currentIndex == i ? widget.lesson.color : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                      
                      FloatingActionButton(
                        onPressed: () {
                           _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutBack);
                        },
                        elevation: 0,
                        backgroundColor: widget.lesson.color,
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      )
                    ],
                  ),
                )
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -50,
          child: FloatingWidget(
            duration: const Duration(seconds: 6),
            distance: 30,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.lesson.color.withOpacity(0.1),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -100,
          child: FloatingWidget(
             duration: const Duration(seconds: 8),
             distance: 50,
             child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.lesson.color.withOpacity(0.05),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlidePage(LessonSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image / Animation Area
          GestureDetector(
            onTap: () => _playAudioForSlide(slide),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.2).animate(_bounceAnimation),
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: widget.lesson.color.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    _getEmojiForSlide(slide.englishText), // Placeholder until assets
                    style: const TextStyle(fontSize: 140),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
          
          // Text Area
          ScaleTransition(
            scale: _pulseAnimation,
            child: Text(
              slide.englishText,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: widget.lesson.color,
                letterSpacing: 2,
                fontFamily: 'Comic Sans MS', 
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.1), offset: const Offset(2, 2), blurRadius: 4)
                ]
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: widget.lesson.color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                  BoxShadow(color: widget.lesson.color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Text(
              slide.nicobareseText,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingWidget(
            child: const Icon(Icons.star_rounded, size: 150, color: Colors.amber),
          ),
          const SizedBox(height: 30),
          Text(
            "Great Job!",
            style: TextStyle(
              fontSize: 48, 
              fontWeight: FontWeight.w900, 
              color: widget.lesson.color
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.lesson.color,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("Finish Lesson", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // Temporary helper to get emojis
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
