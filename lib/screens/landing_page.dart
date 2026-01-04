import 'package:flutter/material.dart';
import 'package:speechmate/widgets/about.dart';
import 'package:speechmate/widgets/button.dart';
import 'package:speechmate/widgets/tap_scale.dart';
import 'package:speechmate/widgets/voice_reactive_aurora.dart';
import 'package:speechmate/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String selectedRole = ""; // student / teacher

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enterprise Background: 
          // Default to Teacher mode (Dark) for initial premium look, 
          // or dynamic based on selection? Let's use Dark for that "Tech/Enterprise" feel initially.
          VoiceReactiveAurora(
            isDark: selectedRole != 'student', 
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Header Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                  "SpeechMate",
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1.0,
                                  ),
                                ).animate().fadeIn().slideX(begin: -0.2),
                                Text(
                                  "Enterprise Edition",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.cyanAccent,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w600
                                  ),
                                ).animate().fadeIn(delay: 300.ms),
                            ],
                        ),
                        // Using the new theme's icon style if possible, or manual clear override
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle
                          ),
                          child: const InfoButton(),
                        )
                      ],
                    ),

                    const Spacer(flex: 1),

                    // Main Title
                    Text(
                      "Break Barriers.\nConnect Worlds.",
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        height: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 16),
                    Text(
                      "The premier bilingual assistant for Nicobarese education and translation.",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 500.ms),

                    const Spacer(flex: 2),
                    
                    Text(
                      "SELECT PREFERENCE",
                      style: GoogleFonts.inter(
                         fontSize: 12, 
                         fontWeight: FontWeight.bold, 
                         color: Colors.white54,
                         letterSpacing: 1.5
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Role Selection Cards
                    Row(
                        children: [
                             Expanded(
                                 child: _buildRoleCard(
                                     title: "Student",
                                     subtitle: "Learn & Play",
                                     icon: Icons.school_rounded,
                                     id: "student",
                                     color: Colors.pinkAccent,
                                 ),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                                 child: _buildRoleCard(
                                     title: "Teacher",
                                     subtitle: "Manage & Guide",
                                     icon: Icons.cast_for_education_rounded,
                                     id: "teacher",
                                     color: Colors.cyanAccent,
                                 ),
                             ),
                        ],
                    ),

                    const Spacer(flex: 1),

                    // Continue Button
                    AnimatedOpacity(
                        opacity: selectedRole.isNotEmpty ? 1.0 : 0.0,
                        duration: 300.ms,
                        child: Center(
                            child: NextButton(selectedRole: selectedRole)
                        ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
      required String title, 
      required String subtitle, 
      required IconData icon, 
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  border: Border.all(
                      color: isSelected ? color : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1
                  ),
                  borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: isSelected ? color : Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle
                          ),
                          child: Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 24),
                      ),
                      const SizedBox(height: 16),
                      Text(
                          title,
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          ),
                      ),
                      const SizedBox(height: 4),
                       Text(
                          subtitle,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white60
                          ),
                      ),
                  ],
              ),
          ),
      );
  }
}
