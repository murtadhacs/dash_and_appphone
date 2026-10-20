import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// ألوان الشارات في Figma.
enum BadgeTone { ok, warn, bad, tint, gray, solidRed, amber }

/// كبسولة نصية صغيرة (حالة، عدّاد، شارة...) تكبر قليلاً عند مرور الفأرة.
class Pill extends StatefulWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final IconData? icon;
  final Widget? leading;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool ltr;
  final bool mono;

  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.icon,
    this.leading,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    this.radius = 999,
    this.ltr = false,
    this.mono = false,
  });

  /// شارة بنغمة من نغمات التصميم.
  factory Pill.tone(
    String label,
    BadgeTone tone, {
    Key? key,
    IconData? icon,
    Widget? leading,
    bool ltr = false,
    bool mono = false,
  }) {
    final (bg, fg) = switch (tone) {
      BadgeTone.ok => (AppColors.okBg, AppColors.green),
      BadgeTone.warn => (AppColors.warnBg, AppColors.warnText),
      BadgeTone.bad => (AppColors.badBg, AppColors.red),
      BadgeTone.tint => (AppColors.tint, AppColors.brand),
      BadgeTone.gray => (const Color(0xFFEDEEF0), AppColors.textSub),
      BadgeTone.solidRed => (const Color(0xFFFF5A47), Colors.white),
      BadgeTone.amber => (AppColors.amber, AppColors.text),
    };
    return Pill(
      key: key,
      label: label,
      background: bg,
      foreground: fg,
      icon: icon,
      leading: leading,
      ltr: ltr,
      mono: mono,
    );
  }

  @override
  State<Pill> createState() => _PillState();
}

class _PillState extends State<Pill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        scale: _hover && !reduce ? 1.06 : 1,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(widget.radius),
            border: widget.borderColor == null
                ? null
                : Border.all(color: widget.borderColor!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 6),
              ],
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: widget.foreground),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: widget.ltr ? TextDirection.ltr : null,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    height: 1.65,
                    fontWeight: FontWeight.w600,
                    color: widget.foreground,
                    fontFamily: widget.mono ? 'monospace' : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
