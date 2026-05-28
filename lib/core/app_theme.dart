import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // --- Explorer Edition Theme (Andaman Coastal — Light) ---
  static ThemeData get studentTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AndamanPalette.oceanTeal,
      scaffoldBackgroundColor: AndamanPalette.sandWhite,
      
      // Color scheme for Material 3 components
      colorScheme: ColorScheme.light(
        primary: AndamanPalette.oceanTeal,
        onPrimary: Colors.white,
        secondary: AndamanPalette.oceanTealLight,
        surface: AndamanPalette.white,
        onSurface: AndamanPalette.stone,
        error: AndamanPalette.reefCoral,
        onError: Colors.white,
      ),

      // Typography — Andaman Coastal type scale
      textTheme: TextTheme(
        // Display: 28/500 — Dashboard greeting, hero cards
        displayLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: AndamanPalette.stone,
          letterSpacing: -0.3,
        ),
        // Headline: 20/500 — Screen titles, Word of Day
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AndamanPalette.stone,
        ),
        // Title: 16/500 — Card titles, section headers
        titleLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AndamanPalette.stone,
        ),
        // Body: 14/400 — All body copy
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AndamanPalette.stoneLight,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AndamanPalette.stoneLight,
        ),
        // Label: 12/500 — Badges, tags, nav labels
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AndamanPalette.mist,
        ),
        // Caption: 11/400 — Timestamps, hints
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AndamanPalette.mistLight,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AndamanPalette.sandWhite,
        foregroundColor: AndamanPalette.stone,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AndamanPalette.stone,
        ),
        iconTheme: const IconThemeData(color: AndamanPalette.mist, size: 22),
      ),
      
      // Bottom Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AndamanPalette.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        height: 64,
        indicatorColor: AndamanPalette.oceanTealSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: AndamanPalette.oceanTeal,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w400, color: AndamanPalette.mist,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AndamanPalette.oceanTeal, size: 24);
          }
          return const IconThemeData(color: AndamanPalette.mist, size: 24);
        }),
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: AndamanPalette.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AndamanPalette.border, width: 1),
        ),
      ),
      
      // Dividers
      dividerTheme: const DividerThemeData(
        color: AndamanPalette.border,
        thickness: 1,
      ),
      
      iconTheme: const IconThemeData(color: AndamanPalette.oceanTeal, size: 24),
      
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
