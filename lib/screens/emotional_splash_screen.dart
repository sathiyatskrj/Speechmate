import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:speechmate/screens/app_language_select.dart';
import 'package:speechmate/screens/languages.dart';

class EmotionalSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const EmotionalSplashScreen({super.key, required this.nextScreen});

  @override
  State<EmotionalSplashScreen> createState() => _EmotionalSplashScreenState();
}

class _EmotionalSplashScreenState extends State<EmotionalSplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  
  // Staggered Animations
  late Animation<double> _teacherOpacity;
  late Animation<double> _studentOpacity;
  late Animation<double> _wordsPosition;
  late Animation<double> _wordsOpacity;
  late Animation<double> _studentGlow;
  late Animation<double> _finalFadeOut;
  late Animation<double> _logoFadeIn;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // 1. Scene Entering (0-1s)
    _teacherOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.15, curve: Curves.easeOut)),
    );
    _studentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.25, curve: Curves.easeOut)),
    );

    // 2. Words Floating (1s - 3.5s)
    _wordsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.3, curve: Curves.easeIn)),
    );
    _wordsPosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.25, 0.6, curve: Curves.easeInOutSlowMiddle)),
    );

    // 3. Student Enlightened (3.5s - 4.5s)
    _studentGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.6, 0.75, curve: Curves.easeOut)),
    );

    // 4. Transition to Logo (4.5s - 5.0s)
    _finalFadeOut = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.75, 0.85, curve: Curves.easeIn)),
    );

    // 5. Logo Reveal (5.0s - 6.0s)
    _logoFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.85, 1.0, curve: Curves.easeOut)),
    );

    _mainController.forward();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Navigate to next screen
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Creamy background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // MAIN SCENE
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              // If we are in the final fade out stage
              if (_finalFadeOut.value > 0.0 && _logoFadeIn.value == 0.0) {
                 return Opacity(
                   opacity: 1.0 - _finalFadeOut.value,
                   child: _buildClassroomScene(),
                 );
              }
              // If we are showing logo
              if (_logoFadeIn.value > 0.0) {
                return Opacity(opacity: _logoFadeIn.value, child: _buildLogoScene());
              }
              // Normal scene
              return _buildClassroomScene();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomScene() {
    return Stack(
      children: [
        // Teacher (Left)
        Positioned(
          left: 40,
          bottom: 200,
          child: FadeTransition(
            opacity: _teacherOpacity,
            child: Column(
              children: [
                const Icon(Icons.face_3_rounded, size: 80, color: Color(0xFF8D6E63)), // Warm brown text
                const SizedBox(height: 10),
                Text("Teacher", style: TextStyle(color: Colors.brown.shade300, fontSize: 14)),
              ],
            ),
          ),
        ),

        // Student (Right)
        Positioned(
          right: 40,
          bottom: 200,
          child: FadeTransition(
            opacity: _studentOpacity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow Effect
                Transform.scale(
                  scale: 1.0 + (_studentGlow.value * 0.5),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withOpacity(_studentGlow.value * 0.4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber,
                          blurRadius: 40 * _studentGlow.value,
                          spreadRadius: 10 * _studentGlow.value,
                        )
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      Icons.face_6_rounded, 
                      size: 80, 
                      color: Color.lerp(const Color(0xFF8D6E63), Colors.amber.shade800, _studentGlow.value)
                    ),
                    const SizedBox(height: 10),
                    Text("Student", style: TextStyle(color: Colors.brown.shade300, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Floating Words (Middle)
        Positioned(
          left: 120 + (MediaQuery.of(context).size.width - 240) * _wordsPosition.value,
          bottom: 240, // Aligned with heads
          child: FadeTransition(
            opacity: _wordsOpacity,
            child: Opacity(
              opacity: 1.0 - _studentGlow.value, // Hide words when they reach/absorb
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFloatingSymbol("अ", Colors.orange),
                  const SizedBox(width: 5),
                  _buildFloatingSymbol("A", Colors.blue),
                  const SizedBox(width: 5),
                  _buildFloatingSymbol("Ka", Colors.green),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingSymbol(String char, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        char, 
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)
      ),
    );
  }

  Widget _buildLogoScene() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.white,
               shape: BoxShape.circle,
               boxShadow: [
                 BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 30, spreadRadius: 10)
               ]
             ),
             child: Image.asset('assets/icons/logo_main.png', width: 100, height: 100),
           ),
           const SizedBox(height: 30),
           const Text(
             "SpeechMate",
             style: TextStyle(
               fontFamily: 'Arial', // Or your custom font
               fontSize: 32,
               fontWeight: FontWeight.bold,
               color: Color(0xFFFF6F61),
               letterSpacing: 1.2,
             ),
           ),
           const SizedBox(height: 16),
           const Text(
             "Preserving ancestral voices\nthrough technology.",
             textAlign: TextAlign.center,
             style: TextStyle(
               fontSize: 16,
               color: Colors.grey,
               fontStyle: FontStyle.italic,
               height: 1.5,
             ),
           ),
        ],
      ),
    );
  }
}
