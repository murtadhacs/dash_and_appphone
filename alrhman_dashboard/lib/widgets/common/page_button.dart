import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// زر صفحة صغير (28×28) في شريط الترقيم.
class PageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool active;
  final bool bordered;
  final VoidCallback? onTap;

  const PageButton({
    super.key,
    this.label,
    this.icon,
    this.active = false,
    this.bordered = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? AppColors.brand
        : (bordered ? Colors.white : Colors.transparent);
    final fg = active
        ? Colors.white
        : (icon != null ? AppColors.textMuted : AppColors.text);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: bordered ? Border.all(color: AppColors.border) : null,
        ),
        child: icon != null
            ? Icon(icon, size: 16, color: fg)
            : Text(
                label ?? '',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: fg,
                ),
              ),
      ),
    );
  }
}
