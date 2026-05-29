import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF080810);
  static const surface = Color(0xFF101018);
  static const surfaceElevated = Color(0xFF14141F);
  static const border = Color(0x14FFFFFF);
  static const borderStrong = Color(0x24FFFFFF);

  static const textPrimary = Color(0xFFF4F4F5);
  static const textSecondary = Color(0x8CF4F4F5);
  static const textMuted = Color(0x47F4F4F5);

  static const accentLike = Color(0xFF4ade80);
  static const accentDislike = Color(0xFFf87171);
  static const accentNeutral = Color(0x61FFFFFF);

  static const cardPalette = [
    Color(0xFF2D1B69),
    Color(0xFF0F4C5C),
    Color(0xFF1B4332),
    Color(0xFF6A040F),
    Color(0xFF3A0CA3),
    Color(0xFF005F73),
    Color(0xFF9D0208),
    Color(0xFF3D348B),
  ];

  static Color cardColorForId(String id) {
    return cardPalette[id.hashCode.abs() % cardPalette.length];
  }
}
