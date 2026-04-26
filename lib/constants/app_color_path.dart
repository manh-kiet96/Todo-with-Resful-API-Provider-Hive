import 'package:flutter/material.dart';

class AppColorsPath {
  // Moderated warm palette (muted red -> orange -> amber)
  // These are slightly desaturated compared to the originals for a more professional look.
  static const Color primaryRed = Color(0xFFB23B2B); // muted deep red
  static const Color primaryOrange = Color(0xFFF57C00); // material orange-700
  static const Color primaryYellow = Color(0xFFFFC107); // amber 500 (moderate yellow)
  static const Color backgroundDark = Color(0xFF2B2B2B);
  static const Color backgroundLight = Color(0xFFFFF8F3); // very pale warm background
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color brownlight = Color(0xFF8B8787);
  static const Color grey = Color(0xFF757575);
  static const Color sunburn = Color(0xFFDD6B4A); // toned deep orange
  static const Color sunburnLight = Color(0xFFFFF8F3); // very pale warm background

  // Status colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFB00020);
  static const Color warningOrange = Color(0xFFFFA000);
  static const Color infoblue = Color(0xFF1976D2);

  // Connectivity status colors
  static const Color onlineGreen = Color(0xFF4CAF50);
  static const Color offlineRed = Color(0xFFB00020);
  static const Color syncingBlue = Color(0xFF1976D2);
  static const Color pendingOrange = Color(0xFFFFA000);

  // UI colors
  static const Color shadowGrey = Color(0x1A000000);
  static const Color borderGrey = Color(0xFFBDBDBD); // subtle neutral border
}
