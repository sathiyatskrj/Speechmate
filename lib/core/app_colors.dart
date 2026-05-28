import 'package:flutter/material.dart';

// ────────────────────────────────────────────────────────────────────────────
// ANDAMAN COASTAL — Design Token System
// Culturally grounded in the A&N island landscape.
// Outdoor-first: every foreground/background pair meets WCAG AA (4.5:1).
// ────────────────────────────────────────────────────────────────────────────

/// Primary design tokens for the Explorer Edition (general public branch).
/// Use these instead of hardcoded Color() values in screen files.
class AndamanPalette {
  AndamanPalette._();

  // ── Brand ──
  static const Color oceanTeal      = Color(0xFF0C6E5A);  // Primary brand, buttons, active
  static const Color oceanTealLight = Color(0xFF10896F);  // Hover / pressed variant
  static const Color oceanTealSoft  = Color(0xFFE0F5EF);  // Teal tinted surface (chips, badges)

  // ── Surfaces ──
  static const Color sandWhite      = Color(0xFFFAFAF8);  // App background (day)
  static const Color mangrove       = Color(0xFFEDF4F0);  // Card surface, secondary bg
  static const Color mangroveDeep   = Color(0xFFD8E8E0);  // Pressed / deeper card variant
  static const Color white          = Color(0xFFFFFFFF);  // Pure white for elevated cards

  // ── Text ──
  static const Color stone          = Color(0xFF1C1917);  // Primary text
  static const Color stoneLight     = Color(0xFF44403C);  // Secondary text
  static const Color mist           = Color(0xFF78716C);  // Muted / caption text
  static const Color mistLight      = Color(0xFFA8A29E);  // Disabled text, placeholders

  // ── Semantic ──
  static const Color reefCoral      = Color(0xFFC0392B);  // Danger, emergency, SOS
  static const Color reefCoralSoft  = Color(0xFFFDE8E8);  // Danger background
  static const Color amber          = Color(0xFFD97706);  // Warning, cultural alerts
  static const Color amberSoft      = Color(0xFFFEF3C7);  // Warning background
  static const Color emerald        = Color(0xFF059669);  // Success, online, correct
  static const Color emeraldSoft    = Color(0xFFD1FAE5);  // Success background
  static const Color skyBlue        = Color(0xFF0284C7);  // Info, links
  static const Color skyBlueSoft    = Color(0xFFE0F2FE);  // Info background

  // ── Borders & Dividers ──
  static const Color border         = Color(0xFFE7E5E4);  // Default card border
  static const Color borderStrong   = Color(0xFFD6D3D1);  // Stronger dividers
  static const Color borderTeal     = Color(0xFF99D5C9);  // Teal-tinted border for active cards

  // ── Shadows (use with BoxShadow) ──
  static const Color shadow         = Color(0x0A000000);  // Subtle elevation shadow
  static const Color shadowMedium   = Color(0x14000000);  // Card shadow

  // ── Dark Mode Variants (for future system-auto switch) ──
  static const Color darkBackground = Color(0xFF0C1A18);  // Deep reef — not pure black
  static const Color darkSurface    = Color(0xFF132820);  // Dark card surface
  static const Color darkBorder     = Color(0xFF1E3A30);  // Dark border
  static const Color darkText       = Color(0xFFF5F5F4);  // Light text on dark
  static const Color darkMuted      = Color(0xFFA8A29E);  // Muted text on dark
  static const Color darkTealAccent = Color(0xFF2DD4BF);  // Teal accent on dark bg

  // ── Bento Card Accent Colors (for the asymmetric grid) ──
  static const Color bentoTeal      = Color(0xFF0D9488);
  static const Color bentoCoral     = Color(0xFFE11D48);
  static const Color bentoAmber     = Color(0xFFEA580C);
  static const Color bentoPurple    = Color(0xFF7C3AED);
  static const Color bentoSky       = Color(0xFF0EA5E9);
  static const Color bentoEmerald   = Color(0xFF059669);
}

// ────────────────────────────────────────────────────────────────────────────
// LEGACY AppColors — kept for backward compatibility with existing screens
// that haven't migrated yet. New code should use AndamanPalette.
// ────────────────────────────────────────────────────────────────────────────

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
