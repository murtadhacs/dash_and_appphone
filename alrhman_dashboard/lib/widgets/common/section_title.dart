import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'icon_tile.dart';

/// عنوان قسم بأيقونة (يُستخدم في بطاقات لوحة التحكم والإعدادات).
class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final double tileSize;

  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.tileSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconTile(
          icon: icon,
          background: AppColors.accentSoft,
          foreground: AppColors.brand,
          size: tileSize,
          iconSize: tileSize * 0.55,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
