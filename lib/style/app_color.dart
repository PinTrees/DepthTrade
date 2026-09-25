import 'package:flutter/material.dart';

class AppColor {
  // Brand Primary & Accent
  static const Color primary = Color(0xFF7C4DFF); // Deep Purple Accent
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color accent = Color(0xFF00E5FF); // Electric Cyan
  static const Color secondary = Color(0xFF818CF8); // Soft Indigo

  // Trading specific colors
  static const Color longGreen = Color(0xFF00E676); // Buy / Long / Profit
  static const Color shortRed = Color(0xFFFF5252); // Sell / Short / Loss
  static const Color warning = Color(0xFFFFB300); // Amber warning
  static const Color neutral = Color(0xFF94A3B8); // Slate grey

  // Dark Cyber Backgrounds
  static const Color background = Color(0xFF0B0E17);
  static const Color backgroundCard = Color(0xFF131722);
  static const Color backgroundSurface = Color(0xFF1E2230);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF0A0D18),
      Color(0xFF0F172A),
      Color(0xFF131A2E),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism styling
  static Color glassBackground = Colors.white.withValues(alpha: 0.06);
  static Color glassBackgroundActive = Colors.white.withValues(alpha: 0.12);
  static Color glassBorder = Colors.white.withValues(alpha: 0.12);
  static Color glassBorderHighlight = const Color(0xFF7C4DFF).withValues(alpha: 0.4);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);

  // Card Borders
  static Color cardBorder = Colors.white.withValues(alpha: 0.08);
}
