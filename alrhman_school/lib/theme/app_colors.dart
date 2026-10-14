import 'package:flutter/material.dart';

/// Brand palette + the Tailwind utility colors used by the original design.
class AppColors {
  AppColors._();

  // Brand
  static const Color brandPurple = Color(0xFFA91FAF);
  static const Color brandPurpleHover = Color(0xFF921897);
  static const Color brandBlue = Color(0xFF4F5CF5);
  static const Color background = Color(0xFFF8F9FC);
  static const Color textPrimary = Color(0xFF3F3F46);
  static const Color textMuted = Color(0xFF969AB8);

  // Status
  static const Color present = Color(0xFF10B981);
  static const Color presentBg = Color(0xFFECFDF5);
  static const Color presentDark = Color(0xFF065F46);
  static const Color absent = Color(0xFFEF4444);
  static const Color holiday = Color(0xFFF59E0B);
  static const Color holidayBg = Color(0xFFFFFBEB);
  static const Color holidayDark = Color(0xFF92400E);
  static const Color circularBg = Color(0xFFEEF4FD);
  static const Color eventYellow = Color(0xFFF5C928);
  static const Color orange = Color(0xFFF07818);

  // Tailwind palette
  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple100 = Color(0xFFF3E8FF);
  static const Color purple200 = Color(0xFFE9D5FF);
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber900 = Color(0xFF78350F);
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose700 = Color(0xFFBE123C);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
}

/// Tailwind-like shadow presets used across the cards.
class AppShadows {
  AppShadows._();

  /// `shadow-sm`
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// `shadow-md`
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  /// `shadow-lg`
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 15,
      offset: Offset(0, 10),
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ];
}
