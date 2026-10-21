import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../common/app_card.dart';

/// بطاقة مؤشر Figma: أيقونة مسطحة بلون العلامة ثم العنوان والقيمة ونسبة اختيارية.
class KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? extra;
  final Color? extraColor;
  final String? note;

  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.extra,
    this.extraColor,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hover: true,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppColors.brand),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.3,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    if (extra != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          extra!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: extraColor ?? AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (note != null)
                  Text(
                    note!,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.warnText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// صف مؤشرات يتوزع بالتساوي ويلتف على الشاشات الضيقة.
class KpiGrid extends StatelessWidget {
  final List<Widget> children;
  const KpiGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 1000
            ? children.length
            : c.maxWidth >= 600
            ? (children.length > 3 ? 2 : children.length)
            : 1;
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += perRow) {
          final slice = children.skip(i).take(perRow).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < perRow; j++) ...[
                    if (j > 0) const SizedBox(width: 16),
                    Expanded(
                      child: j < slice.length ? slice[j] : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          );
          if (i + perRow < children.length) {
            rows.add(const SizedBox(height: 16));
          }
        }
        return Column(children: rows);
      },
    );
  }
}
