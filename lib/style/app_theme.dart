import 'package:flutter/material.dart';
import 'app_color.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColor.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColor.primary,
      secondary: AppColor.accent,
      surface: AppColor.backgroundCard,
      error: AppColor.shortRed,
    ),
    fontFamily: 'SF',
    cardTheme: CardThemeData(
      color: AppColor.glassBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColor.glassBorder, width: 1),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColor.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColor.glassBorder, width: 1),
      ),
    ),
  );
}
