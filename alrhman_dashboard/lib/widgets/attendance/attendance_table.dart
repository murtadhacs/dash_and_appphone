import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/attendance_entry.dart';
import '../../models/student.dart';
import '../common/app_avatar.dart';
import '../common/app_data_table.dart';
import '../common/app_text_field.dart';
import '../common/async_states.dart';
import '../common/clipped_text.dart';
import '../common/pulse_dot.dart';

/// شريط البحث + جدول حضور اليوم.
class AttendanceTable extends StatelessWidget {
  final List<AttendanceEntry> entries;

  /// الطلاب مفهرسين بالمعرّف لعرض الصف والشعبة.
  final Map<int, Student> students;
  final bool live;
  final bool weekend;
  final bool awaitingArrival;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AttendanceEntry> onRegisterExcuse;
  final ValueChanged<AttendanceEntry> onCancelLeave;
  final ValueChanged<AttendanceEntry>? onManualAttendance;

  const AttendanceTable({
    super.key,
    required this.entries,
    required this.students,
    required this.live,
    this.weekend = false,
    this.awaitingArrival = false,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRegisterExcuse,
    required this.onCancelLeave,
    this.onManualAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _searchBar(),
        if (entries.isEmpty)
          const EmptyView(message: 'لا توجد سجلات مطابقة')
        else
          AppDataTable(
            dataRowHeight: 64,
            columns: [
              tableColumn('الطالب والصف'),
              tableColumn('حالة الحضور'),
              tableColumn('وقت الدخول'),
              tableColumn('وقت الخروج'),
              tableColumn('إجراءات'),
            ],
            rows: [for (final e in entries) _row(e)],
          ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.5),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: AppTextField(
                controller: searchController,
                onChanged: onSearchChanged,
                fill: Colors.white,
                hint: 'بحث باسم الطالب أو الصف...',
                prefixIcon: Icons.search,
              ),
            ),
          ),
          const Spacer(),
          if (live)
            const Row(
              children: [
                PulseDot(color: AppColors.green, ping: true),
                SizedBox(width: 8),
                Text(
                  'يتحدّث تلقائياً',
                  style: TextStyle(fontSize: 12, color: AppColors.textSub),
                ),
              ],
            ),
        ],
      ),
    );
  }

  DataRow _row(AttendanceEntry e) {
    final student = students[e.studentId];
    return DataRow(
      key: ValueKey(e.studentId),
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppAvatar(size: 40, radius: 12),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClippedText(
                    e.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  if (student != null)
                    Text(
                      student.gradeSection,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          e.status == PresenceStatus.absent && weekend
              ? const Text('—')
              : e.status == PresenceStatus.absent && awaitingArrival
              ? const Chip(
                  label: Text('لم يصل بعد'),
                  avatar: Icon(Icons.schedule, size: 16),
                )
              : _StatusCapsule(status: e.status),
        ),
        DataCell(_sourcedTime(e.checkInTime, e.checkInSource)),
        DataCell(_sourcedTime(e.checkOutTime, e.checkOutSource)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onManualAttendance != null)
                _actionButton(
                  'تسجيل حضور يدوي',
                  AppColors.brand,
                  () => onManualAttendance!(e),
                ),
              _action(e),
            ],
          ),
        ),
      ],
    );
  }

  Widget _time(String? t) => Text(
    t ?? '—',
    textDirection: TextDirection.ltr,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: t == null ? AppColors.textMuted : AppColors.text,
      fontFamily: 'monospace',
    ),
  );

  Widget _sourcedTime(String? time, String? source) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _time(time),
      if (source == 'manual') ...[
        const SizedBox(width: 6),
        const Chip(
          label: Text('يدوي'),
          avatar: Icon(Icons.edit_outlined, size: 14),
        ),
      ],
    ],
  );

  Widget _action(AttendanceEntry e) {
    switch (e.status) {
      case PresenceStatus.absent:
        return _actionButton(
          'تسجيل عذر',
          AppColors.primary,
          () => onRegisterExcuse(e),
        );
      case PresenceStatus.excused:
        return _actionButton(
          'إلغاء الإجازة',
          AppColors.redDark,
          () => onCancelLeave(e),
        );
      case PresenceStatus.present:
        return const SizedBox.shrink();
    }
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.surfaceMuted,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 30),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}

class _StatusCapsule extends StatelessWidget {
  final PresenceStatus status;
  const _StatusCapsule({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      PresenceStatus.present => (const Color(0xFF10B981), Icons.check),
      PresenceStatus.absent => (const Color(0xFFEF4444), Icons.close),
      PresenceStatus.excused => (const Color(0xFFF59E0B), Icons.schedule),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
