import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// أنماط الأزرار كما في Figma:
/// [amber] الإجراء الأساسي، [primary] كحلي، [outline] أبيض بحد،
/// [soft] رمادي هادئ، [danger] أحمر، [dangerSoft] أحمر فاتح.
enum AppButtonStyle { primary, amber, soft, outline, danger, dangerSoft }

/// الزر الموحّد للتطبيق: ارتفاع 44 (أو 36 للصغير)، أنصاف 14، وحركة عند المرور.
class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final double? height;
  final bool expand;
  final bool small;
  final Widget? iconWidget;
  final String? tooltip;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.iconWidget,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.height,
    this.expand = false,
    this.small = false,
    this.tooltip,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (bg, fg, border, hoverBg) = switch (widget.style) {
      AppButtonStyle.amber => (
        AppColors.amber,
        AppColors.text,
        null,
        const Color(0xFFFFB12E),
      ),
      AppButtonStyle.primary => (
        AppColors.primary,
        Colors.white,
        null,
        const Color(0xFF0A2E80),
      ),
      AppButtonStyle.outline => (
        Colors.white,
        AppColors.text,
        AppColors.line,
        AppColors.canvas,
      ),
      AppButtonStyle.soft => (
        AppColors.canvas,
        AppColors.textSub,
        null,
        AppColors.line,
      ),
      AppButtonStyle.danger => (
        AppColors.red,
        Colors.white,
        null,
        AppColors.redDark,
      ),
      AppButtonStyle.dangerSoft => (
        AppColors.badBg,
        AppColors.red,
        null,
        AppColors.redSoft,
      ),
    };
    final height = widget.height ?? (widget.small ? 36.0 : 44.0);
    final radius = widget.small ? 12.0 : AppRadius.control;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final lifted = _hover && enabled && !reduce;

    final shadow = widget.style == AppButtonStyle.amber && enabled
        ? [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: lifted ? .42 : .28),
              blurRadius: lifted ? 22 : 16,
              offset: Offset(0, lifted ? 10 : 6),
            ),
          ]
        : widget.style == AppButtonStyle.primary && lifted
        ? const [
            BoxShadow(
              color: Color(0x3300236F),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ]
        : lifted
        ? const [
            BoxShadow(
              color: Color(0x14142337),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ]
        : null;

    final iconSize = widget.small ? 16.0 : 18.0;
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.iconWidget != null) ...[
          widget.iconWidget!,
          const SizedBox(width: 8),
        ],
        if (widget.icon != null) ...[
          Icon(widget.icon, size: iconSize, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: fg,
              fontSize: widget.small ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    Widget button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          scale: reduce ? 1 : (_down ? .97 : (lifted ? 1.03 : 1)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: height,
            padding: EdgeInsets.symmetric(horizontal: widget.small ? 14 : 20),
            transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
            decoration: BoxDecoration(
              color: lifted ? hoverBg : bg,
              borderRadius: BorderRadius.circular(radius),
              border: border == null ? null : Border.all(color: border),
              boxShadow: shadow,
            ),
            child: content,
          ),
        ),
      ),
    );

    button = Opacity(opacity: enabled ? 1 : .45, child: button);
    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return Semantics(button: true, enabled: enabled, child: button);
  }
}

/// زر أيقونة مربع (34×34 بنصف 11) كما في عمود الإجراءات بجداول Figma.
class IconActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color color;
  final Color hoverBackground;
  final Color background;
  final double size;

  const IconActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color = AppColors.textSub,
    this.hoverBackground = AppColors.line,
    this.background = AppColors.canvas,
    this.size = 34,
  });

  /// نسخة حمراء لإجراءات الحذف والتعطيل.
  const IconActionButton.danger({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 34,
  }) : color = AppColors.red,
       hoverBackground = AppColors.redSoft,
       background = AppColors.badBg;

  @override
  State<IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<IconActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final lifted = _hover && enabled && !reduce;
    Widget child = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: lifted ? 1.1 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: lifted ? widget.hoverBackground : widget.background,
              borderRadius: BorderRadius.circular(widget.size * .32),
            ),
            child: Icon(
              widget.icon,
              size: widget.size * .47,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
    child = Opacity(opacity: enabled ? 1 : .45, child: child);
    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }
    return Semantics(
      button: true,
      label: widget.tooltip,
      enabled: enabled,
      child: child,
    );
  }
}
