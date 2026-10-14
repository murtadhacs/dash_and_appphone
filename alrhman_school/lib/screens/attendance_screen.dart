import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../core/baghdad_time.dart';
import '../core/month_calendar.dart';
import '../data/parent_data.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import '../widgets/empty_state_card.dart';

/// تقويم الحضور الشهري للطالب المحدد (`GET /api/mobile/attendance/monthly`).
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    required this.data,
    this.onOpenStudentSwitcher,
  });

  final ParentData data;
  final VoidCallback? onOpenStudentSwitcher;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late DateTime _month = _firstOfMonth(BaghdadTime.today());
  CalendarCell? _selected;
  bool _loading = false;
  String? _error;

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  bool get _isCurrentMonth => _month == _firstOfMonth(BaghdadTime.today());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (!force && widget.data.isMonthLoaded(_month)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.data.loadMonth(_month, force: force);
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.needsLogin ? null : e.message;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selected = null;
    });
    _load();
  }

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
                  'سيتم عرض سجل الحضور والانصراف هنا بعد ربط حسابك بسجل الطالب.',
            ),
          ),
        ],
      );
    }

    final records = widget.data.recordsFor(student.id, _month);
    final stats = MonthStats.of(records ?? const []);
    final today = BaghdadTime.today();
    final grid = records == null
        ? const <CalendarCell?>[]
        : buildMonthGrid(
            _month,
            records,
            today,
            holidays: widget.data.holidaysFor(_month),
          );

    // اليوم المحدد افتراضياً: اليوم (إن كان ضمن الشهر) أو آخر يوم له سجل.
    final selected =
        grid
            .whereType<CalendarCell>()
            .where(
              (c) =>
                  _selected != null &&
                  BaghdadTime.sameDay(c.date, _selected!.date),
            )
            .firstOrNull ??
        grid
            .whereType<CalendarCell>()
            .where((c) => c.record != null)
            .fold<CalendarCell?>(
              null,
              (best, c) =>
                  (best == null || c.date.isAfter(best.date)) ? c : best,
            );

    return TabPageScroll(
      onRefresh: () => _load(force: true),
      children: [
        // ---------------- Header ----------------
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الحضور والانصراف',
                    style: AppText.style(size: 16, weight: AppText.extrabold),
                  ),
                  Text(
                    'متابعة سجل الانضباط والدوام',
                    style: AppText.style(size: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
              if (stats.rate != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.emerald200),
                  ),
                  child: Text(
                    'نسبة الحضور ${stats.rate}٪',
                    style: AppText.style(
                      size: 10,
                      weight: AppText.bold,
                      color: AppColors.emerald700,
                    ),
                  ),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StudentSelector(
                student: student,
                canSwitch: widget.data.students.length > 1,
                onTap: widget.onOpenStudentSwitcher,
              ),
              const SizedBox(height: 12),

              // ---------------- Monthly quick stats ----------------
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'أيام الحضور',
                      value: '${stats.present} يوم',
                      valueColor: AppColors.emerald600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'الغياب',
                      value: '${stats.absent} يوم',
                      valueColor: AppColors.absent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'الإجازات',
                      value: '${stats.excused} يوم',
                      valueColor: AppColors.amber600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---------------- Calendar card ----------------
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: AppShadows.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MonthHeader(
                      title: BaghdadTime.monthTitle(_month),
                      onPrev: () => _changeMonth(-1),
                      onNext: _isCurrentMonth ? null : () => _changeMonth(1),
                    ),
                    const SizedBox(height: 12),
                    if (_loading && records == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brandPurple,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else if (_error != null && records == null)
                      _CalendarError(message: _error!, onRetry: _load)
                    else ...[
                      const _WeekdayHeader(),
                      const SizedBox(height: 12),
                      _CalendarGrid(
                        cells: grid,
                        today: today,
                        selected: selected,
                        onSelect: (c) => setState(() => _selected = c),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.gray100),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _LegendItem(
                              color: AppColors.present,
                              label: 'حاضر (${stats.present})',
                            ),
                            _LegendItem(
                              color: AppColors.absent,
                              label: 'غائب (${stats.absent})',
                            ),
                            _LegendItem(
                              color: AppColors.holiday,
                              label: 'مجاز (${stats.excused})',
                            ),
                          ],
                        ),
                      ),
                      if (stats.schoolDays == 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد أيام دراسية مسجّلة في هذا الشهر بعد.',
                          textAlign: TextAlign.center,
                          style: AppText.style(
                            size: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      if (selected != null) ...[
                        const SizedBox(height: 12),
                        _SelectedDayCard(cell: selected),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentSelector extends StatelessWidget {
  const _StudentSelector({
    required this.student,
    required this.canSwitch,
    this.onTap,
  });

  final Student student;
  final bool canSwitch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: canSwitch ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.purple200),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.style(size: 12, weight: AppText.bold),
                  ),
                  Text(
                    student.classLabel,
                    style: AppText.style(size: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (canSwitch)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.purple50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: AppColors.brandPurple,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.title, required this.onPrev, this.onNext});

  final String title;
  final VoidCallback onPrev;

  /// null في الشهر الحالي (لا أشهر قادمة).
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, VoidCallback? onTap, String tip) => Tap(
      onTap: onTap,
      child: Tooltip(
        message: tip,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: onTap == null ? AppColors.gray50 : AppColors.purple50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 14,
            color: onTap == null ? AppColors.gray300 : AppColors.brandPurple,
          ),
        ),
      ),
    );

    return Row(
      children: [
        // في RTL: السهم الأيمن للسابق والأيسر للتالي.
        arrow(LucideIcons.chevronRight, onPrev, 'الشهر السابق'),
        Expanded(
          child: Text(
            'تقويم شهر $title',
            textAlign: TextAlign.center,
            style: AppText.style(size: 12, weight: AppText.bold),
          ),
        ),
        arrow(LucideIcons.chevronLeft, onNext, 'الشهر التالي'),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final d in const [
          'أحد',
          'اثنين',
          'ثلاثاء',
          'أربعاء',
          'خميس',
          'جمعة',
          'سبت',
        ])
          Expanded(
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: AppText.style(
                size: 9,
                weight: AppText.bold,
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarError extends StatelessWidget {
  const _CalendarError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.style(size: 11, weight: AppText.bold),
          ),
          const SizedBox(height: 10),
          Tap(
            onTap: onRetry,
            child: Text(
              'إعادة المحاولة',
              style: AppText.style(
                size: 11,
                weight: AppText.bold,
                color: AppColors.brandPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.style(
              size: 9,
              weight: AppText.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppText.style(
              size: 14,
              weight: AppText.extrabold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.cells,
    required this.today,
    required this.selected,
    required this.onSelect,
  });

  final List<CalendarCell?> cells;
  final DateTime today;
  final CalendarCell? selected;
  final ValueChanged<CalendarCell> onSelect;

  @override
  Widget build(BuildContext context) {
    const columns = 7;
    const gap = 4.0;
    final rows = (cells.length / columns).ceil();

    return Column(
      children: [
        for (int r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: gap),
                  Expanded(
                    child: switch (r * columns + c < cells.length
                        ? cells[r * columns + c]
                        : null) {
                      final cell? => _CalendarCell(
                        cell: cell,
                        isToday: BaghdadTime.sameDay(cell.date, today),
                        isSelected:
                            selected != null &&
                            BaghdadTime.sameDay(selected!.date, cell.date),
                        onTap: () => onSelect(cell),
                      ),
                      null => const SizedBox.shrink(),
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.cell,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final CalendarCell cell;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final numberText = '${cell.date.day}';

    Color bg;
    Color fg;
    Color? dot;
    FontWeight weight = AppText.regular;
    double radius = 12;
    List<BoxShadow>? shadow;

    if (isSelected) {
      bg = AppColors.brandPurple;
      fg = Colors.white;
      dot = cell.record == null ? null : Colors.white;
      weight = AppText.bold;
      shadow = AppShadows.sm;
    } else {
      switch (cell.state) {
        case DayState.present:
          bg = AppColors.presentBg;
          fg = AppColors.presentDark;
          dot = AppColors.present;
          weight = AppText.bold;
        case DayState.absent:
          bg = AppColors.rose50;
          fg = AppColors.rose700;
          dot = AppColors.absent;
          weight = AppText.bold;
        case DayState.holiday:
        case DayState.excused:
          bg = AppColors.holidayBg;
          fg = AppColors.holidayDark;
          dot = AppColors.holiday;
          weight = AppText.medium;
        case DayState.weekend:
        case DayState.future:
        case DayState.noRecord:
          bg = AppColors.gray50;
          fg = cell.state == DayState.future
              ? AppColors.gray300
              : AppColors.gray400;
          radius = 8;
      }
    }

    return Tap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadow,
          border: isToday && !isSelected
              ? Border.all(color: AppColors.brandPurple)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              numberText,
              style: AppText.style(size: 10, weight: weight, color: fg),
            ),
            if (cell.holiday != null)
              Text(
                cell.holiday!.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.style(size: 8, color: fg),
              ),
            if (dot != null)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppText.style(size: 10)),
      ],
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({required this.cell});

  final CalendarCell cell;

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor, statusBorder) = switch (cell.state) {
      DayState.present => ('حاضر', AppColors.present, AppColors.emerald100),
      DayState.absent => ('غائب', AppColors.absent, AppColors.rose100),
      DayState.excused => ('مجاز', AppColors.holiday, AppColors.amber100),
      DayState.holiday => ('عطلة', AppColors.holiday, AppColors.amber100),
      DayState.weekend => (
        'عطلة نهاية الأسبوع',
        AppColors.gray500,
        AppColors.gray100,
      ),
      DayState.future => ('قادم', AppColors.gray500, AppColors.gray100),
      DayState.noRecord => (
        'لا يوجد سجل',
        AppColors.gray500,
        AppColors.gray100,
      ),
    };
    final record = cell.record;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'تفاصيل يوم ${BaghdadTime.dayTitle(cell.date)}',
                  style: AppText.style(size: 10, weight: AppText.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  statusText,
                  style: AppText.style(
                    size: 10,
                    weight: AppText.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (cell.holiday != null) ...[
            const SizedBox(height: 8),
            Text(
              cell.holiday!.title,
              style: AppText.style(size: 12, weight: AppText.bold),
            ),
            if (cell.holiday!.notes != null)
              Text(cell.holiday!.notes!, style: AppText.style(size: 11)),
          ],
          if (record != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'دخول: ${BaghdadTime.arabicTime(record.checkIn)}',
                    style: AppText.style(size: 9, color: AppColors.textMuted),
                  ),
                  Text(
                    'انصراف: ${BaghdadTime.arabicTime(record.checkOut)}',
                    style: AppText.style(size: 9, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
