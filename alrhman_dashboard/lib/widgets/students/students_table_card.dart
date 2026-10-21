import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../../core/iraqi_phone.dart';
import '../../models/student.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';
import '../common/async_states.dart';
import '../common/pill.dart';
import '../ui/letter_avatar.dart';
import '../ui/ui_table.dart';

/// جدول الطلاب كما في Figma: RFID، الطالب، الصف والشعبة، ولي الأمر، الهاتف، الإجراءات.
class StudentsTableCard extends StatelessWidget {
  final List<Student> students;
  final ValueChanged<Student> onEdit;
  final ValueChanged<Student> onDelete;

  const StudentsTableCard({
    super.key,
    required this.students,
    required this.onEdit,
    required this.onDelete,
  });

  static final _dateFmt = DateFormat('d MMMM y', 'ar');

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: students.isEmpty
          ? const EmptyView(message: 'لا يوجد طلاب مطابقون')
          : UiTable(
              columns: const [
                UiCol('RFID', flex: 2, minWidth: 140),
                UiCol('الطالب', flex: 4, minWidth: 230),
                UiCol('الصف والشعبة', flex: 3, minWidth: 170),
                UiCol('ولي الأمر', flex: 3, minWidth: 160),
                UiCol('الهاتف', flex: 2, minWidth: 140),
                UiCol('الإجراءات', flex: 2, minWidth: 110),
              ],
              rows: [for (final s in students) _row(s)],
            ),
    );
  }

  UiRow _row(Student s) {
    return UiRow(
      key: ValueKey(s.id),
      cells: [
        s.hasRealRfid
            ? Pill.tone(s.rfidTag, BadgeTone.tint, ltr: true, mono: true)
            : Pill.tone('بانتظار بطاقة', BadgeTone.warn),
        PersonCell(
          avatar: LetterAvatar(name: s.name),
          title: s.name,
          subtitle: s.createdAt == null
              ? null
              : 'سُجّل ${_dateFmt.format(s.createdAt!)}',
        ),
        Text(
          s.gradeSection,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.text),
        ),
        Text(
          s.parentName.isEmpty ? 'لا يوجد ولي أمر' : s.parentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: s.parentName.isEmpty ? AppColors.textMuted : AppColors.text,
          ),
        ),
        s.parentPhone.isEmpty
            ? const Text('—', style: TextStyle(color: AppColors.textMuted))
            : LtrText(IraqiPhone.display(s.parentPhone)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconActionButton(
              icon: LucideIcons.pencil,
              tooltip: 'تعديل بيانات الطالب',
              onPressed: () => onEdit(s),
            ),
            const SizedBox(width: 8),
            IconActionButton.danger(
              icon: LucideIcons.userX,
              tooltip: 'تعطيل الطالب',
              onPressed: () => onDelete(s),
            ),
          ],
        ),
      ],
    );
  }
}
