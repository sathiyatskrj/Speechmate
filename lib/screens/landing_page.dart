import 'package:flutter/material.dart';
import 'package:speechmate/widgets/about.dart';
import 'package:speechmate/widgets/button.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import 'package:speechmate/widgets/voice_reactive_aurora.dart';
import 'package:speechmate/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:speechmate/core/app_colors.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String selectedRole = ""; // student / teacher

  @override
  Widget build(BuildContext context) {
    // Neutral Gradient (Inviting Blue/Purple for Unselected)
    final neutralGradient = [
       const Color(0xFFE0C3FC), 
       const Color(0xFF8EC5FC), 
    ];

    // Get gradients from AppColors
    final teacherGradient = AppColors.teacherGradient;
    final studentGradient = AppColors.studentGradient;

    // Determine current gradient
    List<Color> currentGradient;
    if (selectedRole == 'student') {
      currentGradient = studentGradient;
    } else if (selectedRole == 'teacher') {
      currentGradient = teacherGradient;
    } else {
      currentGradient = neutralGradient;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background with Animated Transition
          AnimatedContainer(
            duration: 800.ms,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: currentGradient,
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                   const SizedBox(height: 20),
                   // Top Bar: Logo & Info
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SpeechMate",
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                  shadows: [
                                    Shadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                                  ]
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Where Language Barriers End",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          // Restored Info Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const InfoButton(),
                          )
                      ],
                   ),

                   // Centered Content
                   Expanded(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                          // User focused prompt
                          Text(
                            "Who is learning today?",
                            style: GoogleFonts.outfit(
                               fontSize: 24, 
                               fontWeight: FontWeight.w600, 
                               color: Colors.white,
                               shadows: [Shadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0,2))]
                            ),
                          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                          
                          const SizedBox(height: 40),

                          // Profile Cards
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                   _buildRoleCard(
                                       title: "Student",
                                       emoji: "🙋🏻‍♂️",
                                       id: "student",
                                       color: Colors.pinkAccent,
                                   ),
                                   const SizedBox(width: 20),
                                   _buildRoleCard(
                                       title: "Teacher",
                                       emoji: "👨🏻‍🏫",
                                       id: "teacher",
                                       color: Colors.blueAccent,
                                   ),
                              ],
                          ),
                       ],
                     ),
                   ),

                   // Bottom Action Area
                   AnimatedOpacity(
                       opacity: selectedRole.isNotEmpty ? 1.0 : 0.0,
                       duration: 300.ms,
                       child: Padding(
                         padding: const EdgeInsets.only(bottom: 40),
                         child: NextButton(selectedRole: selectedRole),
                       )
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
      required String title, 
      required String emoji, 
      required String id, 
      required Color color
  }) {
      final isSelected = selectedRole == id;
      
      return TapScale(
          onTap: () {
              setState(() => selectedRole = id);
          },
          child: AnimatedContainer(
              duration: 300.ms,
              width: 150, // Slightly wider for comfort
              height: 190,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.2), // Glass effect
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isSelected 
                      ? [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 8))]
                      : [],
                  border: Border.all(
                      color: Colors.white.withOpacity(isSelected ? 0.8 : 0.4),
                      width: 2
                  )
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      // Icon Circle
                      AnimatedContainer(
                          duration: 300.ms,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                          ),
                          child: Text(
                            emoji, 
                            style: const TextStyle(fontSize: 40), // Large Emoji
                          ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                          title,
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black87 : Colors.white
                          ),
                      ),
                  ],
              ),
          ),
      );
  }
}
