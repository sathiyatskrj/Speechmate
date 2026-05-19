import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // --- General Public Theme (Explorer / Travel-Focused) ---
  static ThemeData get studentTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF0F766E), // Teal 700
      scaffoldBackgroundColor: Colors.transparent, // For gradients
      
      // Typography: Clean, modern, adult-appropriate
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          color: const Color(0xFF334155),
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          color: const Color(0xFF475569),
        ),
      ),
      
      iconTheme: const IconThemeData(color: Color(0xFF0D9488), size: 24),
      
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
      primaryColor: const Color(0xFF2DD4BF), // Teal 400
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF2DD4BF),
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 18, color: Colors.white70),
        bodyMedium: GoogleFonts.inter(fontSize: 16, color: Colors.white60),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF2DD4BF), size: 24),
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
}
