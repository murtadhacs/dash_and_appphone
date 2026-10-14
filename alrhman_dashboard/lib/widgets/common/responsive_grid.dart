import 'package:flutter/material.dart';

/// شبكة متجاوبة تُحدّد عدد الأعمدة بحسب عرض النافذة، وتوحّد ارتفاع عناصر كل صف.
///
/// [columns] خريطة { أقل عرض : عدد الأعمدة }، مثال: {0: 1, 640: 2, 1280: 5}.
class ResponsiveGrid extends StatelessWidget {
  final Map<int, int> columns;
  final double gap;
  final List<Widget> children;

  const ResponsiveGrid({
    super.key,
    required this.columns,
    required this.children,
    this.gap = 14,
  });

  int _columnsFor(double width) {
    var result = 1;
    final keys = columns.keys.toList()..sort();
    for (final k in keys) {
      if (width >= k) result = columns[k]!;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cols = _columnsFor(MediaQuery.sizeOf(context).width);
    final rows = <Widget>[];

    for (var i = 0; i < children.length; i += cols) {
      final slice = children.skip(i).take(cols).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) SizedBox(width: gap),
                Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
      if (i + cols < children.length) rows.add(SizedBox(height: gap));
    }
    return Column(children: rows);
  }
}
