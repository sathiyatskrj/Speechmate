import 'package:flutter/material.dart';

class AppColors {
  // --- Student Palette (Fairyland) ---
  static const Color studentPrimary = Color(0xFFFF69B4); // Hot Pink
  static const Color studentAccent = Color(0xFF00FFFF); // Cyan Accent
  static const Color studentGlass = Color(0x33FFFFFF); // White at 20%
  static const List<Color> studentGradient = [
    Color(0xFFFF9A9E), // Warm Pink
    Color(0xFFFECFEF), // Soft Pink
    Color(0xFFF6D365), // Sunny Yellow
    Color(0xFFFDA085), // Peach Orange
    Color(0xFF84FAB0), // Mint Green
    Color(0xFF8FD3F4), // Sky Blue
  ];

  // --- Teacher Palette (Professional) ---
  static const Color teacherPrimary = Color(0xFF1A237E); // Deep Indigo
  static const Color teacherAccent = Color(0xFF00E5FF); // Cyber Blue
  static const Color teacherSurface = Color(0xFF243B55); // Dark Blue Grey
  static const List<Color> teacherGradient = [
    Color(0xFF141E30), // Dark Metal
    Color(0xFF243B55), // Deep Sea
  ];

  // --- Common Semantics ---
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFFC107);
  static const Color textLight = Colors.white;
  static const Color textDark = Color(0xFF121212);
  
  // --- Magic Wow Factors ---
  static const Color auroraGlow = Color(0x66B388FF); // Deep Purple Glow
}
