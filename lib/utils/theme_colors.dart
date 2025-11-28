import 'package:flutter/material.dart';

class ThemeColors {
  // Light Mode
  static const Color lightBg = Color(0xFFF9FAFB); // Gray-50
  static const Color lightCard = Color(0xFFFFFFFF); // White
  static const Color lightText = Color(0xFF111827); // Gray-900
  static const Color lightSubtitle = Color(0xFF6B7280); // Gray-500

  // Dark Mode
  static const Color darkBg = Color(0xFF111827); // Gray-900
  static const Color darkCard = Color(0xFF1F2937); // Gray-800
  static const Color darkText = Color(0xFFFFFFFF); // White
  static const Color darkSubtitle = Color(0xFF9CA3AF); // Gray-400

  // Accent Colors
  static const Color primaryTeal = Color(0xFF14b8a6); // Teal-500
  static const Color primaryTealDark = Color(0xFF0d9488); // Teal-600
  static const Color tealLight = Color(0xFF99f6e4); // Teal-100
  static const Color yellowStar = Color(0xFFEAB308); // Yellow-500
  static const Color yellowBadge = Color(0xFFF59E0B); // Yellow-500
  static const Color redLogout = Color(0xFFEF4444); // Red-500

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14b8a6), Color(0xFF0f766e)],
  );
}
