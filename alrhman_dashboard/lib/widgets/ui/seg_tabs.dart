import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// مفتاح تبويبات Figma: إطار أبيض وعنصر نشط كحلي، مع انتقال لوني ناعم.
class SegTabs<T> extends StatelessWidget {
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  final List<IconData?>? icons;
  final List<String>? tooltips;

  const SegTabs({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.icons,
    this.tooltips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          for (var i = 0; i < items.length; i++)
            _SegItem(
              label: items[i].$2,
              icon: icons == null ? null : icons![i],
              tooltip: tooltips == null ? null : tooltips![i],
              selected: items[i].$1 == value,
              onTap: () => onChanged(items[i].$1),
            ),
        ],
      ),
    );
  }
}

class _SegItem extends StatefulWidget {
  final String label;
  final IconData? icon;
  final String? tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _SegItem({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SegItem> createState() => _SegItemState();
}

class _SegItemState extends State<_SegItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.selected ? Colors.white : AppColors.textSub;
    Widget item = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.label.isEmpty ? 12 : 18,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primary
                : (_hover ? AppColors.canvas : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) Icon(widget.icon, size: 16, color: fg),
              if (widget.icon != null && widget.label.isNotEmpty)
                const SizedBox(width: 6),
              if (widget.label.isNotEmpty)
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      item = Tooltip(message: widget.tooltip!, child: item);
    }
    return item;
  }
}
