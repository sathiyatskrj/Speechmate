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

  // --- Student Dark Theme ---
  static ThemeData get studentDarkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.studentDarkAccent,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.bubblegumSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.studentDarkAccent,
          letterSpacing: 1.5,
        ),
        headlineMedium: GoogleFonts.fredoka(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
        bodyLarge: GoogleFonts.fredoka(fontSize: 18, color: Colors.white70),
        bodyMedium: GoogleFonts.fredoka(fontSize: 16, color: Colors.white60),
      ),
      iconTheme: const IconThemeData(color: AppColors.studentDarkAccent, size: 28),
      useMaterial3: true,
    );
  }

  // --- Teacher Dark Theme ---
  static ThemeData get teacherDarkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.teacherDarkAccent,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: AppColors.teacherDarkAccent,
          letterSpacing: -1.0,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          letterSpacing: 0.5,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white70, height: 1.5),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
      ),
      iconTheme: const IconThemeData(color: AppColors.teacherDarkAccent, size: 24),
      useMaterial3: true,
    );
  }

  // --- M5-02: High Contrast Accessibility Theme ---
  static ThemeData get highContrastTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.yellow,
      scaffoldBackgroundColor: Colors.black,
      materialTapTargetSize: MaterialTapTargetSize.padded, // M5-01: ≥48px targets
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.yellow),
        headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
        bodyLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, height: 1.6),
        bodyMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      iconTheme: const IconThemeData(color: Colors.yellow, size: 32),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
          minimumSize: const Size(48, 56), // M5-01: large touch targets
          textStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      useMaterial3: true,
    );
  }
}
