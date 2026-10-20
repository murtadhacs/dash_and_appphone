import 'package:flutter/material.dart';
import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../models/schedule_class.dart';
import '../models/schedule_period.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_dropdown.dart';
import '../widgets/common/page_button.dart';
import '../widgets/common/pill.dart';
import '../widgets/layout/app_header.dart';
import '../widgets/ui/hover.dart';
import '../widgets/ui/letter_avatar.dart';
import '../widgets/ui/seg_tabs.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/schedule/schedule_editor_dialog.dart';

String scheduleError(ApiException e) =>
    e.statusCode == 400 || e.statusCode == 404
    ? e.serverMessage ?? e.message
    : e.message;

class ScheduleScreen extends StatefulWidget {
  final bool openAddOnStart;
  final VoidCallback? onStartHandled;
  const ScheduleScreen({
    super.key,
    this.openAddOnStart = false,
    this.onStartHandled,
  });
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _search = TextEditingController();
  List<ScheduleClass>? _classes;
  ScheduleClass? _selected;
  List<SchedulePeriod>? _periods;
  String? _error, _previewError, _grade;
  String _status = 'all';
  bool _started = false,
      _loading = false,
      _previewLoading = false,
      _grid = false,
      _editing = false;
  int _page = 0, _previewSequence = 0;
  bool _quickHandled = false;
  static const _pageSize = 6;
  AdminApi get _api => AppScope.of(context).api;
  String _classKey(ScheduleClass c) => '${c.grade}\u0000${c.section}';
  bool _complete(ScheduleClass c) =>
      c.dayCount == 5 && c.periodCount >= 25 && c.periodCount <= 30;
  List<ScheduleClass> get _filtered => (_classes ?? []).where((c) {
    final q = _search.text.trim().toLowerCase();
    return (q.isEmpty || c.label.toLowerCase().contains(q)) &&
        (_grade == null || c.grade == _grade) &&
        switch (_status) {
          'empty' => c.periodCount == 0,
          'complete' => _complete(c),
          'partial' => c.periodCount > 0 && !_complete(c),
          _ => true,
        };
  }).toList();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await _api.scheduleClasses();
      if (!mounted) return;
      final previous = _selected;
      final selected =
          classes
              .where(
                (c) => previous != null && _classKey(c) == _classKey(previous),
              )
              .firstOrNull ??
          classes.firstOrNull;
      setState(() {
        _classes = classes;
        _selected = selected;
        _page = 0;
        if (!classes.any((c) => c.grade == _grade)) _grade = null;
        if (selected == null) {
          _periods = null;
          _previewError = null;
          _previewLoading = false;
          _previewSequence++;
        }
      });
      if (selected != null) await _select(selected);
      if (mounted && widget.openAddOnStart && !_quickHandled) {
        _quickHandled = true;
        widget.onStartHandled?.call();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _quickSchedule();
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = scheduleError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quickSchedule() async {
    if (_classes == null || _classes!.isEmpty) {
      showAppToast(context, 'أضف طلاباً وحدّد الصف والشعبة أولاً');
      return;
    }
    final selected = await showDialog<ScheduleClass>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.calendar_today_outlined,
        title: 'اختر الصف لإعداد جدوله',
        subtitle: 'يُفتح محرر الجدول الأسبوعي للصف المختار',
        maxWidth: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in _classes!)
              _ClassTile(
                schoolClass: c,
                status: _statusPill(c),
                selected: false,
                onTap: () => Navigator.pop(context, c),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) await _edit(selected);
  }

  Future<void> _select(ScheduleClass c) async {
    final sequence = ++_previewSequence;
    setState(() {
      _selected = c;
      _periods = null;
      _previewError = null;
      _previewLoading = true;
    });
    try {
      final periods = await _api.schedule(c);
      if (mounted && sequence == _previewSequence) {
        setState(() {
          _periods = periods;
          _previewLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted && sequence == _previewSequence) {
        setState(() {
          _previewError = scheduleError(e);
          _previewLoading = false;
        });
      }
    }
  }

  Future<void> _edit(ScheduleClass c) async {
    if (_editing) return;
    setState(() => _editing = true);
    try {
      // Always read the selected class from the server before editing it.
      final periods = await _api.schedule(c);
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            ScheduleEditorDialog(api: _api, schoolClass: c, periods: periods),
      );
      if (saved == true && mounted) {
        _selected = c;
        showAppToast(context, 'تم حفظ جدول ${c.label}');
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(
          context,
          scheduleError(e),
          icon: Icons.error_outline,
          iconColor: AppColors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Widget _statusPill(ScheduleClass c) => c.periodCount == 0
      ? Pill.tone('فارغ', BadgeTone.bad)
      : _complete(c)
      ? Pill.tone('مكتمل', BadgeTone.ok)
      : Pill.tone('جزئي', BadgeTone.warn);

  bool _isSelected(ScheduleClass c) =>
      _selected != null && _classKey(c) == _classKey(_selected!);

  @override
  Widget build(BuildContext context) {
    final header = PageHeader(
      title: 'الجداول الأسبوعية',
      search: HeaderSearch(
        controller: _search,
        hint: 'ابحث باسم الصف أو الشعبة',
        onChanged: (_) => setState(() => _page = 0),
      ),
      cta: AppButton(
        label: 'إضافة جدول',
        icon: Icons.add_rounded,
        style: AppButtonStyle.amber,
        onPressed: _classes == null || _editing ? null : _quickSchedule,
      ),
    );
    if (_classes == null) {
      return Column(
        children: [
          header,
          const SizedBox(height: 24),
          _error == null
              ? const LoadingView()
              : ErrorView(message: _error!, onRetry: _load),
        ],
      );
    }
    final classes = _filtered;
    final pages = (classes.length / _pageSize).ceil();
    final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
    final visible = classes.skip(page * _pageSize).take(_pageSize).toList();
    final grades = _classes!.map((c) => c.grade).toSet().toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 24),
        _readiness(),
        const SizedBox(height: 24),
        _tools(grades),
        const SizedBox(height: 20),
        if (_error != null) ...[
          DialogNote(_error!, tone: NoteTone.bad),
          const SizedBox(height: 12),
        ],
        if (_loading) ...[
          const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, c) {
            final list = _classList(visible, classes.length, page, pages);
            if (c.maxWidth >= 1100) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: _grid ? 520 : 420, child: list),
                  const SizedBox(width: 20),
                  Expanded(child: _preview()),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [list, const SizedBox(height: 20), _preview()],
            );
          },
        ),
      ],
    );
  }

  Widget _readiness() {
    final complete = _classes!.where(_complete).length;
    final ratio = _classes!.isEmpty ? 0.0 : complete / _classes!.length;
    final title = Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.okBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.calendar_today_outlined,
            size: 24,
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'جاهزية الجداول',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Text(
                '$complete صفاً مكتملاً من أصل ${_classes!.length}',
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
    final bar = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 320,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                color: AppColors.green,
                backgroundColor: AppColors.canvas,
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Text(
          '${(ratio * 100).round()}%',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ],
    );
    return AppCard(
      hover: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 700
            ? Row(children: [Expanded(child: title), bar])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 14),
                  FittedBox(child: bar),
                ],
              ),
      ),
    );
  }

  Widget _tools(List<String> grades) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegTabs<String>(
                items: const [
                  ('all', 'الكل'),
                  ('complete', 'مكتمل'),
                  ('partial', 'جزئي'),
                  ('empty', 'فارغ'),
                ],
                value: _status,
                onChanged: (v) => setState(() {
                  _status = v;
                  _page = 0;
                }),
              ),
              SizedBox(
                width: 200,
                child: AppDropdown<String>(
                  value: _grade ?? '',
                  items: [
                    const DropdownItem('', 'كل المراحل'),
                    for (final g in grades) DropdownItem(g, g),
                  ],
                  onChanged: (v) => setState(() {
                    _grade = v.isEmpty ? null : v;
                    _page = 0;
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SegTabs<bool>(
          items: const [(false, ''), (true, '')],
          icons: const [Icons.view_list_rounded, Icons.grid_view_rounded],
          tooltips: const ['قائمة الصفوف', 'عرض شبكي'],
          value: _grid,
          onChanged: (v) => setState(() => _grid = v),
        ),
        const SizedBox(width: 10),
        AppButton(
          label: 'تحديث',
          icon: Icons.refresh_rounded,
          style: AppButtonStyle.outline,
          small: true,
          onPressed: _loading || _editing ? null : _load,
        ),
      ],
    );
  }

  Widget _classList(
    List<ScheduleClass> visible,
    int total,
    int page,
    int pages,
  ) => AppCard(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'الصفوف والشعب',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              Pill.tone('${_classes!.length} صفوف مسجّلة', BadgeTone.tint),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          EmptyView(
            message: _classes!.isEmpty
                ? 'لا توجد صفوف مسجّلة. حدّد الصف والشعبة في بيانات الطلاب أولاً.'
                : 'لا توجد صفوف مطابقة للبحث',
          ),
        if (!_grid)
          for (final c in visible)
            _ClassTile(
              key: ValueKey(_classKey(c)),
              schoolClass: c,
              status: _statusPill(c),
              selected: _isSelected(c),
              onTap: () => _select(c),
            ),
        if (_grid && visible.isNotEmpty)
          LayoutBuilder(
            builder: (_, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in visible)
                    SizedBox(
                      width: width,
                      child: _ClassGridCard(
                        schoolClass: c,
                        status: _statusPill(c),
                        selected: _isSelected(c),
                        onTap: () => _select(c),
                        onEdit: _editing ? null : () => _edit(c),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tooltip(
              message: 'السابق',
              child: PageButton(
                icon: Icons.chevron_right_rounded,
                bordered: true,
                onTap: page > 0 ? () => setState(() => _page = page - 1) : null,
              ),
            ),
            const SizedBox(width: 6),
            for (var i = 0; i < pages; i++) ...[
              PageButton(
                label: '${i + 1}',
                active: i == page,
                bordered: true,
                onTap: () => setState(() => _page = i),
              ),
              const SizedBox(width: 6),
            ],
            Tooltip(
              message: 'التالي',
              child: PageButton(
                icon: Icons.chevron_left_rounded,
                bordered: true,
                onTap: page + 1 < pages
                    ? () => setState(() => _page = page + 1)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          total == 0
              ? '0 صفوف'
              : 'عرض ${page * _pageSize + 1}–${(page * _pageSize + visible.length)} من $total صفوف',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    ),
  );

  Widget _preview() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardTitle(
          _selected == null ? 'معاينة الجدول' : 'معاينة: ${_selected!.label}',
          trailing: [
            if (_selected != null)
              AppButton(
                label: (_periods?.isEmpty ?? _selected!.periodCount == 0)
                    ? 'إعداد الجدول'
                    : 'تعديل الجدول',
                icon: Icons.edit_outlined,
                style: AppButtonStyle.primary,
                small: true,
                onPressed: _editing ? null : () => _edit(_selected!),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _selected == null
              ? 'اختر صفاً من القائمة'
              : '${_selected!.studentCount} طالب • ${_periods?.length ?? _selected!.periodCount} حصة',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        if (_previewLoading)
          const LoadingView(height: 180)
        else if (_previewError != null)
          ErrorView(
            message: _previewError!,
            height: 210,
            onRetry: () => _select(_selected!),
          )
        else if (_periods != null && _periods!.isEmpty) ...[
          const SizedBox(height: 12),
          const Icon(
            Icons.calendar_today_outlined,
            size: 38,
            color: AppColors.outline,
          ),
          const SizedBox(height: 12),
          const Text(
            'لم يُعدّ جدول هذا الصف بعد',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSub),
          ),
          const SizedBox(height: 16),
          Center(
            child: AppButton(
              label: 'إعداد جدول الصف',
              icon: Icons.add_rounded,
              style: AppButtonStyle.amber,
              onPressed: _editing ? null : () => _edit(_selected!),
            ),
          ),
          const SizedBox(height: 12),
        ] else if (_periods != null)
          _weekTable(),
        const SizedBox(height: 14),
        const Text(
          'الأحد إلى الخميس · ست حصص يومياً · مكتمل = 5 أيام و 25 إلى 30 حصة',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        if (_periods != null &&
            _periods!.any((p) => p.teacher?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 8),
          Text(
            'المعلمون: ${_periods!.map((p) => p.teacher).whereType<String>().where((s) => s.isNotEmpty).toSet().join('، ')}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSub),
          ),
        ],
      ],
    ),
  );

  Widget _weekTable() {
    final byCell = {for (final p in _periods!) '${p.day}/${p.number}': p};
    Widget cell(String text, {Color? bg, Color? fg, String? tip}) {
      final box = AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: bg ?? AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: fg ?? AppColors.textSub,
          ),
        ),
      );
      return Padding(
        padding: const EdgeInsets.all(4),
        child: tip == null
            ? box
            : Tooltip(message: tip, child: HoverLift(lift: 2, scale: 1.04, child: box)),
      );
    }

    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth < 640 ? 640 : constraints.maxWidth,
          child: Table(
            columnWidths: const {0: FixedColumnWidth(84)},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  const SizedBox(),
                  for (var n = 1; n <= 6; n++) cell('الحصة $n'),
                ],
              ),
              for (final day in scheduleWeekdays)
                TableRow(
                  children: [
                    cell(day),
                    for (var n = 1; n <= 6; n++)
                      () {
                        final period = byCell['$day/$n'];
                        if (period == null) {
                          return cell(
                            '—',
                            bg: AppColors.background,
                            fg: AppColors.outline,
                          );
                        }
                        const palette = AppColors.avatarPalette;
                        final (bg, fg) =
                            palette[period.subject.trim().hashCode.abs() %
                                palette.length];
                        return cell(
                          period.subject,
                          bg: bg,
                          fg: fg,
                          tip: period.teacher == null
                              ? period.subject
                              : '${period.subject}\n${period.teacher}',
                        );
                      }(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// سطر صف في قائمة الصفوف: مربع الحرف، الاسم، الطلاب والحصص، والحالة.
class _ClassTile extends StatefulWidget {
  final ScheduleClass schoolClass;
  final Widget status;
  final bool selected;
  final VoidCallback onTap;

  const _ClassTile({
    super.key,
    required this.schoolClass,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ClassTile> createState() => _ClassTileState();
}

class _ClassTileState extends State<_ClassTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.schoolClass;
    final on = widget.selected || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFFF7F8FA)
                : (_hover ? AppColors.rowHover : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
            border: on
                ? Border.all(
                    color: widget.selected ? AppColors.line : Colors.transparent,
                  )
                : null,
          ),
          child: Row(
            children: [
              LetterAvatar(
                name: c.section.trim().isEmpty
                    ? c.label
                    : c.section.trim().characters.last,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      '${c.studentCount} طالباً · ${c.periodCount} حصة',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              widget.status,
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة صف في العرض الشبكي مع زر تعديل/إعداد الجدول.
class _ClassGridCard extends StatelessWidget {
  final ScheduleClass schoolClass;
  final Widget status;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _ClassGridCard({
    required this.schoolClass,
    required this.status,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = schoolClass;
    return HoverLift(
      borderRadius: BorderRadius.circular(18),
      hoverShadow: hoverCardShadow,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.tint : AppColors.canvas,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${c.studentCount} طالب • ${c.periodCount} حصة • ${c.dayCount} أيام',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              status,
              const SizedBox(height: 10),
              AppButton(
                label: c.periodCount == 0 ? 'إعداد' : 'تعديل',
                icon: Icons.edit_outlined,
                style: AppButtonStyle.outline,
                small: true,
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
