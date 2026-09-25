import 'package:flutter/material.dart';

class AppShadows {
  // --- Dark Mode Shadows ---
  static final List<BoxShadow> darkSubtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.18),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static final List<BoxShadow> darkElevation = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.28),
      blurRadius: 18,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  static final List<BoxShadow> darkCard = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.22),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  // --- Light Mode Shadows ---
  static final List<BoxShadow> lightSubtle = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> lightElevation = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 18,
      spreadRadius: 0,
      offset: const Offset(0, 5),
    ),
  ];

  static final List<BoxShadow> lightCard = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];

  // --- Ambient Glows ---
  static List<BoxShadow> glow(Color color, {double opacity = 0.35, double blur = 14}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];
}
