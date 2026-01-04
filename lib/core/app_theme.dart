import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // --- Student Theme (Playful & Rounded) ---
  static ThemeData get studentTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.studentPrimary,
      scaffoldBackgroundColor: Colors.transparent, // For gradients
      
      // Typography: Bubblegum Sans / Fredoka
      textTheme: TextTheme(
        displayLarge: GoogleFonts.bubblegumSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.teacherPrimary, // Contrast
          letterSpacing: 1.5,
        ),
        headlineMedium: GoogleFonts.fredoka(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.purple.shade900,
        ),
        bodyLarge: GoogleFonts.fredoka(
          fontSize: 18,
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.fredoka(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      
      iconTheme: const IconThemeData(color: Colors.purpleAccent, size: 28),
      
      useMaterial3: true,
    );
  }

  // --- Teacher Theme (Clean & Professional) ---
  static ThemeData get teacherTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.teacherPrimary,
      scaffoldBackgroundColor: Colors.transparent, // For gradients
      
      // Typography: Outfit / Poppins
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: AppColors.textLight,
          letterSpacing: -1.0,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.teacherAccent,
          letterSpacing: 0.5,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.white70,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white60,
        ),
      ),
      
      iconTheme: const IconThemeData(color: AppColors.teacherAccent, size: 24),
      
      useMaterial3: true,
    );
  }
}
