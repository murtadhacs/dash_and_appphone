import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

enum AppButtonStyle { primary, amber, soft, outline, danger }

/// الزر الموحّد للتطبيق بأنماطه المختلفة.
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final double height;
  final bool expand;
  final Widget? iconWidget;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.iconWidget,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.height = 44,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    Color? border;
    switch (style) {
      case AppButtonStyle.primary:
        bg = AppColors.primary;
        fg = Colors.white;
      case AppButtonStyle.amber:
        bg = AppColors.amber;
        fg = AppColors.onAmber;
      case AppButtonStyle.soft:
        bg = AppColors.surfaceMuted;
        fg = AppColors.textSub;
      case AppButtonStyle.outline:
        bg = Colors.white;
        fg = AppColors.primary;
        border = AppColors.border;
      case AppButtonStyle.danger:
        bg = AppColors.red;
        fg = Colors.white;
    }

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconWidget != null) ...[iconWidget!, const SizedBox(width: 8)],
        if (icon != null) ...[
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.control),
          boxShadow: style == AppButtonStyle.amber && onPressed != null
              ? AppShadows.amberGlow
              : null,
        ),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.control),
            onTap: onPressed,
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: border == null ? null : Border.all(color: border),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// زر أيقونة مربع صغير (تعديل، حذف، ...).
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color color;
  final Color hoverBackground;
  final double size;

  const IconActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color = AppColors.textMuted,
    this.hoverBackground = AppColors.surfaceMuted,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        hoverColor: hoverBackground,
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
