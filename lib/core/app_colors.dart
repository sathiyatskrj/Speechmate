import 'package:flutter/material.dart';

class AppColors {
  // --- Student Palette (Static Premium) ---
  static const Color studentPrimary = Color(0xFFFF69B4); 
  static const Color studentAccent = Color(0xFF00FFFF); 
  static const Color studentGlass = Color(0x33FFFFFF); 
  static const List<Color> studentStaticGradient = [
    Color(0xFF00C9FF), 
    Color(0xFF92FE9D), 
    Color(0xFF000000), 
  ];

  // --- Teacher Palette (Static Premium) ---
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

  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFFC107);
  static const Color textLight = Colors.white;
  static const Color textDark = Color(0xFF121212);
  
  static const Color auroraGlow = Color(0x66B388FF); 

  static const Color studentDarkAccent = Color(0xFFE94560);
  static const Color teacherDarkAccent = Color(0xFF58A6FF);

  static List<Color> getThemeGradient(bool isTeacher) {
    return isTeacher ? teacherStaticGradient : studentStaticGradient;
  }

  static Color getThemeAccent(bool isTeacher) {
    return (isTeacher) ? teacherAccent : studentAccent;
  }
}
