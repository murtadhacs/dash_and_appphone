import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';
import '../common/pill.dart';
import '../layout/app_header.dart';
import '../ui/seg_tabs.dart';

enum AttendanceFilter { all, present, absent, excused }

/// بطاقة التاريخ كما في Figma: السابق/التاريخ/التالي وزر «اليوم» يميناً،
/// وتنبيه ما قبل 09:31 وأزرار العطل يساراً.
class AttendanceDateBar extends StatelessWidget {
  final String dateLabel;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onPickDate;
  final bool awaitingArrival;
  final Widget holidayActions;

  const AttendanceDateBar({
    super.key,
    required this.dateLabel,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onPickDate,
    required this.awaitingArrival,
    required this.holidayActions,
  });

  @override
  Widget build(BuildContext context) {
    final nav = Wrap(
      spacing: 6,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        HeaderSquareButton(
          tooltip: 'اليوم السابق',
          icon: Icons.chevron_right_rounded,
          onTap: onPrev,
        ),
        _DateChip(label: dateLabel, onTap: onPickDate),
        Opacity(
          opacity: canGoNext ? 1 : .4,
          child: HeaderSquareButton(
            tooltip: 'اليوم التالي',
            icon: Icons.chevron_left_rounded,
            onTap: canGoNext ? onNext : null,
          ),
        ),
        const SizedBox(width: 4),
        AppButton(
          label: 'اليوم',
          icon: Icons.schedule_rounded,
          style: AppButtonStyle.outline,
          small: true,
          onPressed: onToday,
        ),
      ],
    );
    final side = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (awaitingArrival)
          Pill.tone('قبل 09:31: عداد الغياب بانتظار الوصول', BadgeTone.warn),
        holidayActions,
      ],
    );
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 900
            ? Row(
                children: [
                  nav,
                  const Spacer(),
                  Flexible(child: side),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [nav, const SizedBox(height: 12), side],
              ),
      ),
    );
  }
}

class _DateChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _DateChip({required this.label, required this.onTap});

  @override
  State<_DateChip> createState() => _DateChipState();
}

class _DateChipState extends State<_DateChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'اختيار تاريخ',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 44,
            constraints: const BoxConstraints(minWidth: 240),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _hover ? AppColors.canvas : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: _hover ? AppColors.brand : AppColors.line,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSub,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شريط الأدوات فوق الجدول: البحث، فلتر الحالة، التصدير، والتسجيل اليدوي.
class AttendanceTools extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final AttendanceFilter filter;
  final ValueChanged<AttendanceFilter> onFilterChanged;
  final Map<AttendanceFilter, int> counts;
  final bool hideAbsence;
  final VoidCallback onExport;
  final bool exporting;
  final VoidCallback? onManualAttendance;

  const AttendanceTools({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.filter,
    required this.onFilterChanged,
    required this.counts,
    required this.hideAbsence,
    required this.onExport,
    required this.exporting,
    this.onManualAttendance,
  });

  @override
  Widget build(BuildContext context) {
    String n(AttendanceFilter f) => '${counts[f] ?? 0}';
    final tabs = SegTabs<AttendanceFilter>(
      items: [
        (AttendanceFilter.all, 'الكل (${n(AttendanceFilter.all)})'),
        (AttendanceFilter.present, 'حاضر (${n(AttendanceFilter.present)})'),
        if (!hideAbsence)
          (AttendanceFilter.absent, 'غائب (${n(AttendanceFilter.absent)})'),
        (AttendanceFilter.excused, 'مجاز (${n(AttendanceFilter.excused)})'),
      ],
      value: filter,
      onChanged: onFilterChanged,
    );
    final buttons = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        AppButton(
          label: exporting ? 'جارٍ التنزيل...' : 'تصدير Excel',
          icon: Icons.download_rounded,
          style: AppButtonStyle.outline,
          onPressed: exporting ? null : onExport,
        ),
        AppButton(
          label: 'تسجيل حضور يدوي',
          icon: Icons.lock_outline_rounded,
          style: AppButtonStyle.outline,
          tooltip: 'التسجيل اليدوي غير مربوط بالخادم حالياً',
          onPressed: onManualAttendance,
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        final search = HeaderSearch(
          controller: searchController,
          hint: 'ابحث باسم الطالب أو الصف أو الشعبة',
          onChanged: onSearchChanged,
          width: c.maxWidth >= 700 ? 300 : c.maxWidth,
        );
        if (c.maxWidth >= 1100) {
          return Row(
            children: [
              search,
              const SizedBox(width: 12),
              tabs,
              const Spacer(),
              buttons,
            ],
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [search, tabs, buttons],
        );
      },
    );
  }
}
