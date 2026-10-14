import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// جدول بياني بتنسيق التصميم، يتمدد لعرض الحاوية ويمرّر أفقياً عند الضيق.
class AppDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Color headingColor;
  final double dataRowHeight;
  final double? dataRowMaxHeight;
  final double columnSpacing;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.headingColor = AppColors.surfaceMuted,
    this.dataRowHeight = 60,
    this.dataRowMaxHeight,
    this.columnSpacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(headingColor),
              headingRowHeight: 44,
              dataRowMinHeight: dataRowHeight,
              dataRowMaxHeight: dataRowMaxHeight ?? dataRowHeight,
              columnSpacing: columnSpacing,
              horizontalMargin: 20,
              dividerThickness: 1,
              border: const TableBorder(
                horizontalInside: BorderSide(color: AppColors.surfaceMuted),
              ),
              headingTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSub,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.text,
              ),
              columns: columns,
              rows: rows,
            ),
          ),
        );
      },
    );
  }
}

DataColumn tableColumn(String label, {bool numeric = false}) =>
    DataColumn(label: Text(label), numeric: numeric);
