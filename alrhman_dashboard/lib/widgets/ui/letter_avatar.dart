import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// مربع الحرف الأول من الاسم بلون ثابت لكل اسم (كما في جداول Figma).
class LetterAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double? radius;

  const LetterAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '؟' : trimmed.characters.first;
    const palette = AppColors.avatarPalette;
    final (bg, fg) = palette[trimmed.hashCode.abs() % palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius ?? size * .35),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * .38,
          fontWeight: FontWeight.bold,
          color: fg,
          height: 1.2,
        ),
      ),
    );
  }
}
