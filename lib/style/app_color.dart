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

  // Layered Surfaces (아웃라인 없는 자연스러운 깊이감 계층)
  static const Color background = Color(0xFF0B0E17);
  static const Color backgroundCard = Color(0xFF131722);
  static const Color backgroundSurface = Color(0xFF1A2030);
  static const Color cardSurface = Color(0xFF161C2C);
  static const Color elevatedSurface = Color(0xFF1E263B);
  static const Color inputSurface = Color(0xFF111523);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF080B14),
      Color(0xFF0D1222),
      Color(0xFF12182B),
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

  // Glassmorphism styling (아웃라인 제거, 은은한 배경과 소프트 섀도우)
  static Color glassBackground = Colors.white.withValues(alpha: 0.05);
  static Color glassBackgroundActive = Colors.white.withValues(alpha: 0.10);
  static Color glassBorder = Colors.transparent; // 아웃라인 제거
  static Color glassBorderHighlight = Colors.transparent; // 아웃라인 제거
  static Color cardBorder = Colors.transparent; // 아웃라인 제거

  // Soft depth shadows for borderless elevation
  static List<BoxShadow> elevationShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 18,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);
}
