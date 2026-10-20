import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/attendance_entry.dart';
import '../../models/student.dart';
import '../common/app_button.dart';
import '../common/async_states.dart';
import '../common/pill.dart';
import '../ui/letter_avatar.dart';
import '../ui/ui_table.dart';

/// جدول حضور اليوم كما في Figma: الطالب والصف، الحالة، وقت الدخول ومصدره،
/// وقت الخروج، والعمليات (منح إجازة للغائب أو إلغاء إجازة المجاز).
class AttendanceTable extends StatelessWidget {
  final List<AttendanceEntry> entries;

  /// الطلاب مفهرسين بالمعرّف لعرض الصف والشعبة.
  final Map<int, Student> students;
  final bool weekend;
  final bool awaitingArrival;
  final ValueChanged<AttendanceEntry> onRegisterExcuse;
  final ValueChanged<AttendanceEntry> onCancelLeave;

  const AttendanceTable({
    super.key,
    required this.entries,
    required this.students,
    this.weekend = false,
    this.awaitingArrival = false,
    required this.onRegisterExcuse,
    required this.onCancelLeave,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyView(message: 'لا توجد سجلات مطابقة');
    }
    return UiTable(
      columns: const [
        UiCol('الطالب والصف', flex: 4, minWidth: 240),
        UiCol('الحالة', flex: 2, minWidth: 130),
        UiCol('وقت الدخول', flex: 2, minWidth: 110),
        UiCol('مصدر التسجيل', flex: 2, minWidth: 130),
        UiCol('وقت الخروج', flex: 2, minWidth: 110),
        UiCol('العمليات', flex: 2, minWidth: 150),
      ],
      rows: [for (final e in entries) _row(e)],
    );
  }

  UiRow _row(AttendanceEntry e) {
    final student = students[e.studentId];
    return UiRow(
      key: ValueKey(e.studentId),
      cells: [
        PersonCell(
          avatar: LetterAvatar(name: e.fullName),
          title: e.fullName,
          subtitle: student?.gradeSection,
        ),
        _status(e),
        LtrText(
          e.checkInTime ?? '—',
          color: e.checkInTime == null ? AppColors.textMuted : AppColors.text,
        ),
        _source(e),
        LtrText(
          e.checkOutTime ?? '—',
          color: e.checkOutTime == null ? AppColors.textMuted : AppColors.text,
        ),
        _action(e),
      ],
    );
  }

  Widget _status(AttendanceEntry e) {
    if (e.status == PresenceStatus.absent && weekend) {
      return const Text('—', style: TextStyle(color: AppColors.textMuted));
    }
    if (e.status == PresenceStatus.absent && awaitingArrival) {
      return Pill.tone('بانتظار الوصول', BadgeTone.tint);
    }
    return switch (e.status) {
      PresenceStatus.present => Pill.tone('حاضر', BadgeTone.ok),
      PresenceStatus.absent => Pill.tone('غائب', BadgeTone.bad),
      PresenceStatus.excused => Pill.tone('مجاز', BadgeTone.warn),
    };
  }

  Widget _source(AttendanceEntry e) {
    final source = e.checkInSource;
    if (e.status == PresenceStatus.excused) {
      return const Text(
        'إجازة رسمية',
        style: TextStyle(fontSize: 13, color: AppColors.text),
      );
    }
    if (e.checkInTime == null) {
      return const Text('—', style: TextStyle(color: AppColors.textMuted));
    }
    if (source == 'manual') return Pill.tone('يدوي', BadgeTone.gray);
    return Text(
      source == null || source.isEmpty ? 'جهاز البصمة' : source,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, color: AppColors.text),
    );
  }

  Widget _action(AttendanceEntry e) {
    switch (e.status) {
      case PresenceStatus.absent:
        return AppButton(
          label: 'منح إجازة',
          icon: Icons.event_busy_outlined,
          style: AppButtonStyle.outline,
          small: true,
          onPressed: () => onRegisterExcuse(e),
        );
      case PresenceStatus.excused:
        return AppButton(
          label: 'إلغاء الإجازة',
          icon: Icons.delete_outline_rounded,
          style: AppButtonStyle.dangerSoft,
          small: true,
          onPressed: () => onCancelLeave(e),
        );
      case PresenceStatus.present:
        return const Text('—', style: TextStyle(color: AppColors.textMuted));
    }
  }
}
