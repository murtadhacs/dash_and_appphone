import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/app_colors.dart';
import '../../core/iraqi_phone.dart';
import '../../models/student.dart';
import '../common/app_avatar.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';
import '../common/app_data_table.dart';
import '../common/async_states.dart';
import '../common/clipped_text.dart';

/// بطاقة جدول الطلاب: ترويسة + جدول + عدّاد.
class StudentsTableCard extends StatelessWidget {
  final List<Student> students;
  final int total;
  final ValueChanged<Student> onEdit;
  final ValueChanged<Student> onDelete;
  final VoidCallback onExport;

  const StudentsTableCard({
    super.key,
    required this.students,
    required this.total,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
  });

  static final _dateFmt = DateFormat('yyyy-MM-dd', 'en');

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          if (students.isEmpty)
            const EmptyView(message: 'لا يوجد طلاب مطابقون')
          else
            AppDataTable(
              headingColor: AppColors.surfaceMuted.withValues(alpha: 0.5),
              columns: [
                tableColumn('كود الطالب'),
                tableColumn('اسم الطالب'),
                tableColumn('الصف / الشعبة'),
                tableColumn('ولي الأمر'),
                tableColumn('رقم الهاتف'),
                tableColumn('الإجراءات'),
              ],
              rows: [for (final s in students) _row(s)],
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.list_alt_outlined, size: 16, color: AppColors.brand),
          const SizedBox(width: 6),
          const Text(
            'سجلات الطلاب',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'عرض ${students.length} من أصل $total طالب',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSub,
                ),
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onExport,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSub,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.table_chart_outlined, size: 16),
            label: const Text('تصدير كشف الطلاب'),
          ),
        ],
      ),
    );
  }

  DataRow _row(Student s) {
    return DataRow(
      key: ValueKey(s.id),
      cells: [
        DataCell(
          Text(
            s.rfidTag,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: s.hasRealRfid ? AppColors.textSub : AppColors.warnDark,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppAvatar(size: 36),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClippedText(
                    s.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  if (s.createdAt != null)
                    Text(
                      'تاريخ الانضمام: ${_dateFmt.format(s.createdAt!)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              s.gradeSection,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        DataCell(
          ClippedText(
            s.parentName.isEmpty ? 'لا يوجد ولي أمر' : s.parentName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          s.parentPhone.isEmpty
              ? const Text('—')
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.ltr,
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      IraqiPhone.display(s.parentPhone),
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconActionButton(
                icon: Icons.edit_outlined,
                tooltip: 'تعديل بيانات الطالب',
                color: AppColors.brand,
                hoverBackground: AppColors.accentSoft,
                size: 28,
                onPressed: () => onEdit(s),
              ),
              const SizedBox(width: 4),
              IconActionButton(
                icon: Icons.person_off_outlined,
                tooltip: 'تعطيل الطالب',
                color: AppColors.red,
                hoverBackground: AppColors.redSoft,
                size: 28,
                onPressed: () => onDelete(s),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
