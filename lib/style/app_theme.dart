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
      color: AppColor.cardSurface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none, // 아웃라인 제거
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColor.cardSurface,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none, // 아웃라인 제거
      ),
    ),
  );
}
