import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/responsive.dart';
import '../common/app_button.dart';

enum AttendanceFilter { all, present, absent, excused }

/// شريط الأدوات: تنقل التاريخ + فلاتر الحالة + منح إجازة + تصدير Excel.
class AttendanceToolbar extends StatelessWidget {
  final String dateLabel;
  final bool isToday;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onPickDate;
  final AttendanceFilter filter;
  final ValueChanged<AttendanceFilter> onFilterChanged;
  final Map<AttendanceFilter, int> counts;
  final VoidCallback onGrantLeave;
  final VoidCallback onExport;
  final bool exporting;
  final bool hideAbsence;

  const AttendanceToolbar({
    super.key,
    required this.dateLabel,
    required this.isToday,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onPickDate,
    required this.filter,
    required this.onFilterChanged,
    required this.counts,
    required this.onGrantLeave,
    required this.onExport,
    required this.exporting,
    this.hideAbsence = false,
  });

  @override
  Widget build(BuildContext context) {
    final left = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [_dateNav(context), _todayButton(), _pills()],
    );

    final right = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        AppButton(
          label: 'منح إجازة',
          icon: Icons.add_circle_outline,
          style: AppButtonStyle.amber,
          onPressed: onGrantLeave,
        ),
        AppButton(
          label: exporting ? 'جارٍ التنزيل...' : 'تصدير إلى Excel',
          style: AppButtonStyle.outline,
          iconWidget: const _ExcelIcon(),
          onPressed: exporting ? null : onExport,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          return c.maxWidth >= 1000
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 16),
                    right,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [left, const SizedBox(height: 16), right],
                );
        },
      ),
    );
  }

  Widget _dateNav(BuildContext context) {
    final showToday = MediaQuery.sizeOf(context).width >= Breakpoints.sm;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _arrow(Icons.chevron_right, 'اليوم السابق', onPrev),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  if (isToday && showToday) ...[
                    const SizedBox(width: 8),
                    const Text(
                      '(اليوم)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _arrow(Icons.chevron_left, 'اليوم التالي', canGoNext ? onNext : null),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, String tip, VoidCallback? onTap) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: IconActionButton(
        icon: icon,
        tooltip: tip,
        color: AppColors.textSub,
        hoverBackground: Colors.white,
        onPressed: onTap,
      ),
    );
  }

  Widget _todayButton() => Material(
    color: AppColors.surfaceMuted,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      hoverColor: AppColors.border,
      onTap: onToday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'اليوم',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    ),
  );

  Widget _pills() {
    final items = <(AttendanceFilter, String)>[
      (AttendanceFilter.all, 'الكل (${counts[AttendanceFilter.all] ?? 0})'),
      (
        AttendanceFilter.present,
        'الحاضرون (${counts[AttendanceFilter.present] ?? 0})',
      ),
      if (!hideAbsence)
        (
          AttendanceFilter.absent,
          'الغياب (${counts[AttendanceFilter.absent] ?? 0})',
        ),
      (
        AttendanceFilter.excused,
        'الإجازات (${counts[AttendanceFilter.excused] ?? 0})',
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 4,
        children: [
          for (final (value, label) in items)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onFilterChanged(value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: filter == value ? AppColors.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: filter == value ? Colors.white : AppColors.textSub,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// أيقونة Excel (مرسومة بالكود بدل SVG).
class _ExcelIcon extends StatelessWidget {
  const _ExcelIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF107C41),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: const Text(
        'X',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
