import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_shadows.dart';
import 'theme_service.dart';

class AppColor {
  // Brand Primary & Accent
  static const Color primary = Color(0xFF7C4DFF); // Deep Purple Accent
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color accent = Color(0xFF00E5FF); // Electric Cyan
  static const Color secondary = Color(0xFF818CF8); // Soft Indigo

  // Trading specific colors
  static const Color longGreen = Color(0xFF00E676); // Buy / Long / Profit
  static const Color shortRed = Color(0xFFFF5252); // Sell / Short / Loss
  static const Color upColor = longGreen;
  static const Color downColor = shortRed;
  static const Color warning = Color(0xFFFFB300); // Amber warning
  static const Color neutral = Color(0xFF94A3B8); // Slate grey

  // Borders & Static Gradients
  static const Color glassBorder = Colors.transparent;
  static const Color glassBorderHighlight = Colors.transparent;
  static const Color cardBorder = Colors.transparent;

  static const LinearGradient primaryGradient = AppGradients.brand;
  static const LinearGradient greenGradient = AppGradients.profit;
  static const LinearGradient redGradient = AppGradients.loss;

  // Dynamic Theme State
  static bool get isDark => ThemeService.instance.isDark;

  // Dynamic Theme Colors
  static Color get background =>
      isDark ? DarkPalette.background : LightPalette.background;
  static Color get backgroundCard =>
      isDark ? DarkPalette.backgroundCard : LightPalette.backgroundCard;
  static Color get backgroundSurface =>
      isDark ? DarkPalette.backgroundSurface : LightPalette.backgroundSurface;
  static Color get cardSurface =>
      isDark ? DarkPalette.cardSurface : LightPalette.cardSurface;
  static Color get elevatedSurface =>
      isDark ? DarkPalette.elevatedSurface : LightPalette.elevatedSurface;
  static Color get inputSurface =>
      isDark ? DarkPalette.inputSurface : LightPalette.inputSurface;

  static Color get textPrimary =>
      isDark ? DarkPalette.textPrimary : LightPalette.textPrimary;
  static Color get textSecondary =>
      isDark ? DarkPalette.textSecondary : LightPalette.textSecondary;
  static Color get textDisabled =>
      isDark ? DarkPalette.textDisabled : LightPalette.textDisabled;
  static Color get divider =>
      isDark ? DarkPalette.divider : LightPalette.divider;

  // Glassmorphism tokens
  static Color get glassBackground =>
      isDark ? DarkPalette.glass : LightPalette.glass;
  static Color get glassBackgroundActive =>
      isDark ? DarkPalette.glassActive : LightPalette.glassActive;

  // Dynamic Shadow tokens
  static List<BoxShadow> get subtleShadow =>
      isDark ? AppShadows.darkSubtle : AppShadows.lightSubtle;
  static List<BoxShadow> get elevationShadow =>
      isDark ? AppShadows.darkElevation : AppShadows.lightElevation;

  // Dynamic Background Gradient
  static LinearGradient get backgroundGradient =>
      isDark ? AppGradients.darkBackground : AppGradients.lightBackground;

  // Context-aware dynamic helpers
  static Color dynamicBackground([BuildContext? context]) => background;
  static Color dynamicCard([BuildContext? context]) => cardSurface;
  static Color dynamicInput([BuildContext? context]) => inputSurface;
  static Color dynamicText([BuildContext? context]) => textPrimary;
  static Color dynamicTextSecondary([BuildContext? context]) => textSecondary;
  static List<BoxShadow> dynamicSubtleShadow([BuildContext? context]) => subtleShadow;
  static List<BoxShadow> dynamicElevationShadow([BuildContext? context]) => elevationShadow;
}
