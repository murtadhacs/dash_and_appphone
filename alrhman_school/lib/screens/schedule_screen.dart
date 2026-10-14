import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/baghdad_time.dart';
import '../core/school_days.dart';
import '../data/parent_data.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import '../widgets/empty_state_card.dart';

/// الجدول الأسبوعي للطالب المحدد (`GET /api/mobile/schedule`).
///
/// الخادم يرسل رقم الحصة والمادة والمعلم فقط (بلا أوقات)، لذا لا نعرض
/// أوقات الحصص ولا "الحصة الحالية".
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    required this.data,
    this.onOpenStudentSwitcher,
  });

  final ParentData data;
  final VoidCallback? onOpenStudentSwitcher;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  /// اليوم الدراسي الحالي افتراضياً، أو الأحد في العطلة.
  String _selectedDayKey =
      dayKeyOfWeekday(BaghdadTime.today().weekday) ?? 'sunday';

  @override
  Widget build(BuildContext context) {
    final student = widget.data.currentStudent;

    if (student == null) {
      return TabPageScroll(
        horizontalPadding: 16,
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyStateCard(
              icon: LucideIcons.userX,
              title: 'لا يوجد طالب مرتبط بحسابك',
              subtitle:
                  'سيتم عرض الجدول الدراسي هنا بعد ربط حسابك بسجل الطالب.',
            ),
          ),
        ],
      );
    }

    final days = widget.data.schedules[student.id] ?? const <DaySchedule>[];

    final tabs = schoolDays;
    final active = days.where((d) => d.dayKey == _selectedDayKey).firstOrNull;
    final periods = active?.periods ?? const <ClassPeriod>[];

    return TabPageScroll(
      children: [
        // ---------------- Header ----------------
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Tap(
                  onTap: widget.data.students.length > 1
                      ? widget.onOpenStudentSwitcher
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'جدول الحصص الأسبوعي',
                        style: AppText.style(
                          size: 16,
                          weight: AppText.extrabold,
                        ),
                      ),
                      Text(
                        '${student.name} • ${student.classLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.style(
                          size: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (periods.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${periods.length} حصص',
                    style: AppText.style(
                      size: 10,
                      weight: AppText.bold,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final child in widget.data.students)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(child.name),
                      selected: child.id == student.id,
                      onSelected: (_) {
                        widget.data.selectStudent(child);
                        setState(() {});
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        // ---------------- Day tabs ----------------
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: NoScrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (int i = 0; i < tabs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _DayTab(
                      name: tabs[i].name,
                      isActive: tabs[i].key == _selectedDayKey,
                      onTap: () =>
                          setState(() => _selectedDayKey = tabs[i].key),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ---------------- Periods ----------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: periods.isEmpty
              ? EmptyStateCard(
                  icon: LucideIcons.bookX,
                  title: days.isEmpty
                      ? 'لم يُضف الجدول بعد'
                      : 'لا توجد حصص في هذا اليوم',
                  subtitle: days.isEmpty
                      ? 'لم تنشر المدرسة جدول هذا الصف حتى الآن.'
                      : 'اختر يوماً آخر لعرض حصصه.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < periods.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _PeriodCard(period: periods[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _DayTab extends StatelessWidget {
  const _DayTab({
    required this.name,
    required this.isActive,
    required this.onTap,
  });

  final String name;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandPurple : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? null : Border.all(color: AppColors.gray100),
          boxShadow: isActive ? AppShadows.sm : null,
        ),
        child: Text(
          name,
          maxLines: 1,
          softWrap: false,
          style: AppText.style(
            size: 12,
            weight: AppText.bold,
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period});

  final ClassPeriod period;

  @override
  Widget build(BuildContext context) {
    final hasTeacher = period.teacher.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Icon(
            subjectIcon(period.subjectKey),
            color: AppColors.brandPurple,
            size: 26,
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue100),
            ),
            child: Text(
              '${period.periodNumber}',
              style: AppText.style(
                size: 12,
                weight: AppText.bold,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(size: 12, weight: AppText.bold),
                ),
                Text(
                  hasTeacher ? period.teacher : 'لم يُحدَّد المعلم',
                  style: AppText.style(
                    size: 10,
                    color: hasTeacher ? AppColors.textMuted : AppColors.gray300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'الحصة ${period.periodNumber}',
            style: AppText.style(
              size: 9,
              weight: AppText.bold,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

IconData subjectIcon(String key) => switch (key) {
  'arabic' => Icons.menu_book,
  'islamic' => Icons.mosque,
  'math' => Icons.calculate,
  'science' => Icons.science,
  'social' => Icons.public,
  'english' => Icons.translate,
  'art' => Icons.palette,
  'pe' => Icons.sports_soccer,
  'computer' => Icons.computer,
  'music' => Icons.music_note,
  _ => Icons.book_outlined,
};
