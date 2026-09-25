import 'package:flutter/material.dart';

class AppTypography {
  static const String fontSans = 'SF';
  static const String fontMono = 'monospace';

  // Display & Headers
  static TextStyle displayLarge(Color color) => TextStyle(
        fontFamily: fontSans,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.8,
      );

  static TextStyle displayMedium(Color color) => TextStyle(
        fontFamily: fontSans,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle titleLarge(Color color) => TextStyle(
        fontFamily: fontSans,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle titleMedium(Color color) => TextStyle(
        fontFamily: fontSans,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleSmall(Color color) => TextStyle(
        fontFamily: fontSans,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Body
  static TextStyle bodyLarge(Color color) => TextStyle(
        fontFamily: fontSans,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontFamily: fontSans,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle bodySmall(Color color) => TextStyle(
        fontFamily: fontSans,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontFamily: fontSans,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.1,
      );

  // Monospace (Numbers, Prices, Calculations)
  static TextStyle mono(Color color, {double fontSize = 13, FontWeight fontWeight = FontWeight.w600}) => TextStyle(
        fontFamily: fontMono,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle monoLarge(Color color) => TextStyle(
        fontFamily: fontMono,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      );
}
