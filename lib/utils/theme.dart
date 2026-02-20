// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class T {
  // Core palette
  static const bg         = Color(0xFF080C14);
  static const surface    = Color(0xFF0F1623);
  static const card       = Color(0xFF141B2D);
  static const cardAlt    = Color(0xFF1A2238);
  static const border     = Color(0xFF1E2D4A);
  static const borderBright = Color(0xFF2A3F60);

  // Accent
  static const primary    = Color(0xFF4F8EF7);
  static const primaryGlow= Color(0xFF1A3A7A);
  static const secondary  = Color(0xFFA78BFA);
  static const gold       = Color(0xFFFFCC00);
  static const rose       = Color(0xFFFF6B8A);
  static const teal       = Color(0xFF2DD4BF);
  static const amber      = Color(0xFFFFA940);

  // Semantic
  static const success    = Color(0xFF4ADE80);
  static const error      = Color(0xFFFF5A5A);
  static const warning    = Color(0xFFFFC44D);

  // Text
  static const textPrimary   = Color(0xFFE8EEF8);
  static const textSecondary = Color(0xFF6B7FA3);
  static const textDim       = Color(0xFF3A4A6A);

  // Gender
  static const maleColor    = Color(0xFF4F8EF7);
  static const femaleColor  = Color(0xFFFF6B8A);
  static const neutralColor = Color(0xFF6B7FA3);

  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: const ColorScheme.dark(
      background: bg, surface: surface,
      primary: primary, secondary: secondary,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.8)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1.8)),
      hintStyle: const TextStyle(color: textDim, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith(
        (s) => s.contains(MaterialState.selected) ? primary : Colors.transparent),
      side: const BorderSide(color: border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}

// Shared decorations
BoxDecoration glassBox({Color? border, double r = 16, Color? bg}) => BoxDecoration(
  color: bg ?? T.card,
  borderRadius: BorderRadius.circular(r),
  border: Border.all(color: border ?? T.border, width: 1),
  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))],
);
