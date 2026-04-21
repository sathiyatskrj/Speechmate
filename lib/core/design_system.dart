import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DSSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class DSRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const card = 20.0;
  static const button = 14.0;
  static const sheet = 24.0;
}

class DSTypography {
  static final headline = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );
  
  static final title = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final body = GoogleFonts.inter(
    fontSize: 16,
    height: 1.4,
  );

  static final caption = GoogleFonts.inter(
    fontSize: 12,
    color: Colors.white54,
  );
}

class DSColors {
  static const surfaceDark = Color(0xFF1E1E2C);
  static const backgroundDark = Color(0xFF121212);
  
  static final glassLight = Colors.white.withOpacity(0.1);
  static final glassBorderLight = Colors.white.withOpacity(0.2);
  
  static final glassDark = Colors.black.withOpacity(0.2);
  static final glassBorderDark = Colors.black.withOpacity(0.3);
}

class DSShadows {
  static final soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static final glow = [
    BoxShadow(
      color: Colors.cyanAccent.withOpacity(0.3),
      blurRadius: 15,
      spreadRadius: 2,
    ),
  ];
}
