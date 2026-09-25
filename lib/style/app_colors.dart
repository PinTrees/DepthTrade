import 'package:flutter/material.dart';

class DarkPalette {
  static const Color background = Color(0xFF0B0E17);
  static const Color backgroundCard = Color(0xFF131722);
  static const Color backgroundSurface = Color(0xFF1A2030);
  static const Color cardSurface = Color(0xFF161C2C);
  static const Color elevatedSurface = Color(0xFF1E263B);
  static const Color inputSurface = Color(0xFF111523);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);

  static final Color glass = Colors.white.withValues(alpha: 0.05);
  static final Color glassActive = Colors.white.withValues(alpha: 0.10);
  static final Color divider = Colors.white.withValues(alpha: 0.08);
}

class LightPalette {
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundSurface = Color(0xFFF1F5F9); // Slate 100
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFF8FAFC);
  static const Color inputSurface = Color(0xFFF1F5F9); // Slate 100

  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textDisabled = Color(0xFF94A3B8); // Slate 400

  static final Color glass = Colors.black.withValues(alpha: 0.03);
  static final Color glassActive = Colors.black.withValues(alpha: 0.06);
  static final Color divider = const Color(0xFF0F172A).withValues(alpha: 0.08);
}
