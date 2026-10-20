import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// زر صفحة (36×36) في شريط الترقيم بأسلوب Figma، مع حركة عند المرور.
class PageButton extends StatefulWidget {
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
  State<PageButton> createState() => _PageButtonState();
}

class _PageButtonState extends State<PageButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final on = _hover && enabled && !widget.active;
    final fg = widget.active
        ? Colors.white
        : (enabled ? AppColors.text : AppColors.outline);
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: on ? 1.08 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minWidth: 36),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.active
                  ? AppColors.primary
                  : (on ? AppColors.canvas : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.active ? AppColors.primary : AppColors.line,
              ),
            ),
            child: widget.icon != null
                ? Icon(widget.icon, size: 16, color: fg)
                : Text(
                    widget.label ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
