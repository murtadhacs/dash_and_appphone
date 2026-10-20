import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// عمود في جدول Figma: عنوان ونسبة عرض وأقل عرض قبل التمرير الأفقي.
class UiCol {
  final String label;
  final int flex;
  final double minWidth;
  const UiCol(this.label, {this.flex = 2, this.minWidth = 120});
}

/// سطر جدول.
class UiRow {
  final Key? key;
  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool selected;
  const UiRow({
    this.key,
    required this.cells,
    this.onTap,
    this.selected = false,
  });
}

/// جدول Figma: ترويسة رمادية مدوّرة، أسطر بحد سفلي خفيف، وتظليل عند المرور.
class UiTable extends StatelessWidget {
  final List<UiCol> columns;
  final List<UiRow> rows;
  final double rowMinHeight;

  const UiTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowMinHeight = 64,
  });

  @override
  Widget build(BuildContext context) {
    final minTotal = columns.fold<double>(0, (s, c) => s + c.minWidth);
    return LayoutBuilder(
      builder: (context, c) {
        final scroll = c.maxWidth < minTotal;
        final table = SizedBox(
          width: scroll ? minTotal : c.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    for (final col in columns)
                      Expanded(
                        flex: col.flex,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            col.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSub,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (var i = 0; i < rows.length; i++)
                _HoverRow(
                  key: rows[i].key,
                  row: rows[i],
                  columns: columns,
                  last: i == rows.length - 1,
                  minHeight: rowMinHeight,
                ),
            ],
          ),
        );
        return scroll
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              )
            : table;
      },
    );
  }
}

class _HoverRow extends StatefulWidget {
  final UiRow row;
  final List<UiCol> columns;
  final bool last;
  final double minHeight;

  const _HoverRow({
    super.key,
    required this.row,
    required this.columns,
    required this.last,
    required this.minHeight,
  });

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final highlighted = row.selected || _hover;
    return MouseRegion(
      cursor: row.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: row.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: row.selected
                ? AppColors.tint.withValues(alpha: .55)
                : (_hover ? AppColors.rowHover : Colors.white),
            borderRadius: BorderRadius.circular(highlighted ? 14 : 0),
            border: widget.last || highlighted
                ? null
                : const Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              for (var j = 0; j < widget.columns.length; j++)
                Expanded(
                  flex: widget.columns[j].flex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: j < row.cells.length
                          ? row.cells[j]
                          : const SizedBox.shrink(),
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

/// خلية «الشخص»: مربع الحرف الأول + اسم + سطر فرعي.
class PersonCell extends StatelessWidget {
  final Widget avatar;
  final String title;
  final String? subtitle;

  const PersonCell({
    super.key,
    required this.avatar,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// نص تقني باتجاه LTR (أوقات، أرقام، معرّفات).
class LtrText extends StatelessWidget {
  final String text;
  final bool mono;
  final Color color;
  final FontWeight weight;
  final double size;

  const LtrText(
    this.text, {
    super.key,
    this.mono = false,
    this.color = AppColors.text,
    this.weight = FontWeight.normal,
    this.size = 13,
  });

  @override
  Widget build(BuildContext context) => Text(
    text,
    textDirection: TextDirection.ltr,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: mono ? size - 1 : size,
      color: color,
      fontWeight: weight,
      fontFamily: mono ? 'monospace' : null,
    ),
  );
}
