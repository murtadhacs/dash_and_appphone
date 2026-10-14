import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// صورة طالب ثابتة الشكل (لا يوجد رفع صور في النظام): دائرة بأيقونة شخص.
class AppAvatar extends StatelessWidget {
  final double size;
  final double? radius;

  const AppAvatar({super.key, this.size = 36, this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(radius ?? size / 2),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(
        Icons.person_outline,
        size: size * 0.55,
        color: AppColors.brand,
      ),
    );
  }
}
