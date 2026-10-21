import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import 'app_text_field.dart';

class DropdownItem<T> {
  final T value;
  final String label;
  const DropdownItem(this.value, this.label);
}

class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final Color fill;
  final double fontSize;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.fill = Colors.white,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      isDense: true,
      borderRadius: BorderRadius.circular(AppRadius.control),
      icon: const Icon(
        LucideIcons.chevronDown,
        size: 18,
        color: AppColors.textMuted,
      ),
      decoration: appInputDecoration(
        fill: fill,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: AppColors.textSub,
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
      ),
      items: [
        for (final i in items)
          DropdownMenuItem<T>(value: i.value, child: Text(i.label)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
