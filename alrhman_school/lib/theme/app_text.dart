import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tailwind → Flutter typography mapping.
///
/// Named Tailwind sizes carry their own line-height (text-xs = 12/16,
/// text-sm = 14/20 …); arbitrary sizes like `text-[10px]` inherit the
/// document line-height of 1.5.
class AppText {
  AppText._();

  static const String fontFamily = 'Cairo';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extrabold = FontWeight.w800;

  static double _defaultHeight(double size) {
    switch (size) {
      case 12:
        return 16 / 12; // text-xs
      case 14:
        return 20 / 14; // text-sm
      case 16:
        return 24 / 16; // text-base
      case 18:
        return 28 / 18; // text-lg
      case 24:
        return 32 / 24; // text-2xl
      default:
        return 1.5;
    }
  }

  static TextStyle style({
    required double size,
    FontWeight weight = regular,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height ?? _defaultHeight(size),
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: color,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }
}
