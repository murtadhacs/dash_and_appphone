import 'package:flutter/material.dart';

/// ألوان التصميم المستخرجة من لوحة الإدارة الأصلية.
class AppColors {
  AppColors._();

  // Surfaces
  static const background = Color(0xFFF0F1F3);
  static const viewport = Color(0xFFE1E3E7);
  static const navyDeep = Color(0xFF001142);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF0F1F3);
  static const border = Color(0xFFE2E8F0);
  static const accentSoft = Color(0xFFE7EEFE);

  // Brand
  static const primary = Color(0xFF00236F);
  static const brand = Color(0xFF1E3A8A);
  static const amber = Color(0xFFFEA619);
  static const onAmber = Color(0xFF151C27);

  // Text
  static const text = Color(0xFF151C27);
  static const textSub = Color(0xFF444651);
  static const textMuted = Color(0xFF757682);
  static const outline = Color(0xFFC5C5D3);

  // Status
  static const green = Color(0xFF10B981);
  static const greenDark = Color(0xFF059669);
  static const greenDeep = Color(0xFF004A31);
  static const greenSoft = Color(0xFFECFDF5);
  static const greenBorder = Color(0xFFBBF7D0);
  static const greenMint = Color(0xFF27C38A);

  static const red = Color(0xFFEF4444);
  static const redDark = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFEE2E2);
  static const redBorder = Color(0xFFFECACA);

  static const warn = Color(0xFFF59E0B);
  static const warnDark = Color(0xFFD97706);
  static const warnDeep = Color(0xFFB45309);
  static const warnSoft = Color(0xFFFEF3C7);

  static const toastDark = Color(0xFF2A313D);

  // Figma tokens (Al-Rahman Soft Institutional)
  static const canvas = Color(0xFFF0F1F3);
  static const line = Color(0xFFE2E8F0);
  static const tint = Color(0xFFE7EEFE);
  static const warnText = Color(0xFFD98600);
  static const warnBg = Color(0xFFFFFBEB);
  static const okBg = Color(0xFFECFDF5);
  static const badBg = Color(0xFFFEF2F2);
  static const rowHover = Color(0xFFF8FAFC);
  static const slate = Color(0xFF425AA6);

  /// ألوان مربعات الحرف الأول (خلفية، نص) بالتناوب.
  static const avatarPalette = [
    (Color(0xFFE7EEFE), Color(0xFF1E3A8A)),
    (Color(0xFFECFDF5), Color(0xFF0B8F63)),
    (Color(0xFFFFF1D6), Color(0xFFB26B00)),
    (Color(0xFFFDE8E8), Color(0xFFC23030)),
    (Color(0xFFEDE9FE), Color(0xFF5B3FC2)),
    (Color(0xFFE0F2FE), Color(0xFF0B6FA4)),
  ];
}

/// الظلال والأنصاف الموحّدة للتصميم الجديد (بطاقات عائمة بلا حدود قاسية).
class AppShadows {
  AppShadows._();

  /// ظل البطاقات: 0 16 36 rgba(20,35,55,.08).
  static const card = [
    BoxShadow(color: Color(0x14142337), blurRadius: 36, offset: Offset(0, 16)),
  ];

  /// ظل النوافذ المنبثقة: 0 24 48 rgba(15,23,42,.16).
  static const dialog = [
    BoxShadow(color: Color(0x290F172A), blurRadius: 48, offset: Offset(0, 24)),
  ];

  /// توهج العنصر النشط وزر الإجراء الأساسي.
  static const amberGlow = [
    BoxShadow(color: Color(0x40FEA619), blurRadius: 12, offset: Offset(0, 4)),
  ];
}

class AppRadius {
  AppRadius._();

  static const shell = 40.0;
  static const canvas = 32.0;
  static const card = 24.0;
  static const control = 14.0;
}
