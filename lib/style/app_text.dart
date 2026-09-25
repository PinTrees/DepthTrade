import 'package:flutter/material.dart';
import 'app_color.dart';

class AppText {
  static TextStyle get titleLarge => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColor.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColor.textPrimary,
      );

  static TextStyle get titleSmall => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColor.textPrimary,
      );

  static TextStyle get body => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColor.textPrimary,
      );

  static TextStyle get bodySecondary => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColor.textSecondary,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColor.textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle get mono => TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColor.textPrimary,
      );

  static TextStyle get monoLarge => TextStyle(
        fontFamily: 'monospace',
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColor.textPrimary,
      );
}
