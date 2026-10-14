import 'package:flutter/material.dart';

/// كبسولة نصية صغيرة (حالة، عدّاد، شارة...).
class Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final IconData? icon;
  final Widget? leading;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double radius;

  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.icon,
    this.leading,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    this.radius = 999,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
