import 'package:flutter/material.dart';
import 'app_color.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DarkPalette.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColor.primary,
      secondary: AppColor.accent,
      surface: DarkPalette.backgroundCard,
      error: AppColor.shortRed,
    ),
    fontFamily: 'SF',
    cardTheme: CardThemeData(
      color: DarkPalette.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DarkPalette.cardSurface,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: DarkPalette.divider,
      thickness: 1,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: LightPalette.background,
    colorScheme: const ColorScheme.light(
      primary: AppColor.primary,
      secondary: AppColor.primaryDark,
      surface: LightPalette.backgroundCard,
      error: AppColor.shortRed,
    ),
    fontFamily: 'SF',
    cardTheme: CardThemeData(
      color: LightPalette.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: LightPalette.cardSurface,
      elevation: 12,
      shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: LightPalette.divider,
      thickness: 1,
    ),
  );
}
