import 'package:flutter/material.dart';

class AppColors {
  // --- General Public Palette (Explorer / Travel Theme) ---
  static const Color studentPrimary = Color(0xFF0F766E);   // Teal 700
  static const Color studentAccent = Color(0xFF2DD4BF);     // Teal 400
  static const Color studentGlass = Color(0x33FFFFFF); 
  static const List<Color> studentStaticGradient = [
    Color(0xFF0D9488),  // Teal 600
    Color(0xFF0F766E),  // Teal 700
    Color(0xFF0F172A),  // Slate 900
  ];

  // --- Onboarding Flow ---
  static const Color onboardingStart = Color(0xFF0D9488);   // Teal 600
  static const Color onboardingMid = Color(0xFF2DD4BF);     // Teal 400
  static const Color onboardingDeep = Color(0xFF0F172A);    // Slate 900

  // --- Teacher Palette (Clean & Professional) ---
  static const Color teacherPrimary = Color(0xFF1A237E); 
  static const Color teacherAccent = Color(0xFF00E5FF); 
  static const Color teacherSurface = Color(0xFF243B55); 
  static const List<Color> teacherStaticGradient = [
    Color(0xFF6A11CB), 
    Color(0xFF2575FC), 
    Color(0xFF000000), 
  ];

  static const List<Color> studentGradient = studentStaticGradient;
  static const List<Color> teacherGradient = teacherStaticGradient;

  static const Color success = Color(0xFF10B981);  // Emerald 500
  static const Color error = Color(0xFFEF4444);    // Red 500
  static const Color warning = Color(0xFFF59E0B);  // Amber 500
  static const Color textLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  
  static const Color auroraGlow = Color(0x6614B8A6); // Teal glow

  static const Color studentDarkAccent = Color(0xFF2DD4BF);  // Teal 400
  static const Color teacherDarkAccent = Color(0xFF58A6FF);

  static List<Color> getThemeGradient(bool isTeacher) {
    return isTeacher ? teacherStaticGradient : studentStaticGradient;
  }

  static Color getThemeAccent(bool isTeacher) {
    return (isTeacher) ? teacherAccent : studentAccent;
  }
}
