import 'package:flutter/material.dart';
import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../models/schedule_class.dart';
import '../models/schedule_period.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_data_table.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/pill.dart';
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
      builder: (context) => SimpleDialog(
        title: const Text('اختر الصف لإعداد جدوله'),
        children: [
          for (final c in _classes!)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, c),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(c.label),
              ),
            ),
        ],
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

  Widget _statusPill(ScheduleClass c) => Pill(
    label: c.periodCount == 0
        ? 'بانتظار الإعداد'
        : _complete(c)
        ? 'الأسبوع مكتمل'
        : 'جدول جزئي',
    background: c.periodCount == 0
        ? AppColors.warnSoft
        : _complete(c)
        ? AppColors.greenSoft
        : AppColors.accentSoft,
    foreground: c.periodCount == 0
        ? AppColors.warnDeep
        : _complete(c)
        ? AppColors.greenDeep
        : AppColors.brand,
    icon: c.periodCount == 0
        ? Icons.schedule
        : _complete(c)
        ? Icons.check_circle_outline
        : Icons.view_week_outlined,
  );
  @override
  Widget build(BuildContext context) {
    if (_classes == null) {
      return _error == null
          ? const LoadingView()
          : ErrorView(message: _error!, onRetry: _load);
    }
    final classes = _filtered;
    final pages = (classes.length / _pageSize).ceil();
    final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
    final visible = classes.skip(page * _pageSize).take(_pageSize).toList();
    final grades = _classes!.map((c) => c.grade).toSet().toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(grades),
        const SizedBox(height: 24),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: AppColors.redDark)),
          const SizedBox(height: 12),
        ],
        if (_loading) const LinearProgressIndicator(),
        _classList(visible, classes.length, page, pages),
        const SizedBox(height: 24),
        _preview(),
      ],
    );
  }

  Widget _header(List<String> grades) {
    final complete = _classes!.where(_complete).length;
    final ratio = _classes!.isEmpty ? 0.0 : complete / _classes!.length;
    final readiness = Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تغطية الجداول للأسبوع الدراسي',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            '$complete من ${_classes!.length} صفوف مكتملة',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.brand,
                  backgroundColor: AppColors.border,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(ratio * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.brand,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.calendar_view_week_outlined,
            color: AppColors.brand,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة الجداول الدراسية',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'اختر الصف لمعاينة جدوله، وأضف المواد والمعلمين أو عدّل الحصص مباشرةً.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (_, constraints) => constraints.maxWidth < 700
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [title, const SizedBox(height: 16), readiness],
                  )
                : Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 24),
                      readiness,
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'البحث باسم الصف أو الشعبة…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _page = 0),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('grade/$_grade/${grades.join()}'),
                  initialValue: _grade,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('جميع الصفوف'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('جميع الصفوف'),
                    ),
                    for (final g in grades)
                      DropdownMenuItem(value: g, child: Text(g)),
                  ],
                  onChanged: (v) => setState(() {
                    _grade = v;
                    _page = 0;
                  }),
                ),
              ),
              SizedBox(
                width: 175,
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('كافة الحالات')),
                    DropdownMenuItem(
                      value: 'complete',
                      child: Text('الأسبوع مكتمل'),
                    ),
                    DropdownMenuItem(
                      value: 'partial',
                      child: Text('جدول جزئي'),
                    ),
                    DropdownMenuItem(
                      value: 'empty',
                      child: Text('بانتظار الإعداد'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _status = v!;
                    _page = 0;
                  }),
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.view_list_outlined),
                    label: Text('قائمة الصفوف'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.grid_view_outlined),
                    label: Text('عرض شبكي'),
                  ),
                ],
                selected: {_grid},
                onSelectionChanged: (values) =>
                    setState(() => _grid = values.first),
              ),
              IconButton(
                tooltip: 'تحديث الجداول',
                onPressed: _loading || _editing ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _classList(
    List<ScheduleClass> visible,
    int total,
    int page,
    int pages,
  ) => AppCard(
    padding: EdgeInsets.zero,
    clip: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'سجل الصفوف والشعب الدراسية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Pill(
                label: '${_classes!.length} صفوف مسجّلة',
                background: AppColors.accentSoft,
                foreground: AppColors.brand,
              ),
              const Text(
                'اختر صفاً لعرض المعاينة',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (visible.isEmpty)
          EmptyView(
            message: _classes!.isEmpty
                ? 'لا توجد صفوف مسجّلة. حدّد الصف والشعبة في بيانات الطلاب أولاً.'
                : 'لا توجد صفوف مطابقة للبحث',
          ),
        if (!_grid && visible.isNotEmpty)
          AppDataTable(
            dataRowHeight: 88,
            columnSpacing: 16,
            columns: [
              tableColumn('الصف والشعبة'),
              tableColumn('الطلاب'),
              tableColumn('الحصص'),
              tableColumn('حالة الجدول'),
              tableColumn('الإجراءات'),
            ],
            rows: [
              for (final c in visible)
                DataRow(
                  key: ValueKey(_classKey(c)),
                  selected:
                      _selected != null &&
                      _classKey(c) == _classKey(_selected!),
                  color: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? AppColors.accentSoft.withValues(alpha: .45)
                        : null,
                  ),
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 125,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (c.studentCount == 0)
                              const Text(
                                'بدون طلاب فعّالين',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      onTap: () => _select(c),
                    ),
                    DataCell(Text('${c.studentCount}')),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c.periodCount} حصة',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${c.dayCount} أيام',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(_statusPill(c)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'معاينة ${c.label}',
                            onPressed: () => _select(c),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              color: AppColors.brand,
                              size: 20,
                            ),
                          ),
                          AppButton(
                            onPressed: _editing ? null : () => _edit(c),
                            label: c.periodCount == 0 ? 'إعداد' : 'تعديل',
                            icon: Icons.edit_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        if (_grid && visible.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final width = constraints.maxWidth > 600
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final c in visible)
                      SizedBox(
                        width: width,
                        child: InkWell(
                          onTap: () => _select(c),
                          borderRadius: BorderRadius.circular(12),
                          child: AppCard(
                            color:
                                _selected != null &&
                                    _classKey(c) == _classKey(_selected!)
                                ? AppColors.accentSoft
                                : AppColors.surface,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${c.studentCount} طالب • ${c.periodCount} حصة • ${c.dayCount} أيام',
                                ),
                                const SizedBox(height: 12),
                                _statusPill(c),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _editing ? null : () => _edit(c),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: Text(
                                    c.periodCount == 0
                                        ? 'إعداد الجدول'
                                        : 'تعديل الجدول',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                total == 0
                    ? '0 صفوف'
                    : 'عرض ${page * _pageSize + 1}–${(page * _pageSize + visible.length)} من $total صفوف',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: page > 0
                        ? () => setState(() => _page = page - 1)
                        : null,
                    child: const Text('السابق'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${pages == 0 ? 0 : page + 1} / $pages'),
                  ),
                  OutlinedButton(
                    onPressed: page + 1 < pages
                        ? () => setState(() => _page = page + 1)
                        : null,
                    child: const Text('التالي'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _preview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selected == null
                        ? 'معاينة الجدول'
                        : 'معاينة جدول ${_selected!.label}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _selected == null
                  ? 'اختر صفاً من القائمة'
                  : '${_selected!.studentCount} طالب • ${_periods?.length ?? _selected!.periodCount} حصة',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            if (_previewLoading)
              const LoadingView(height: 180)
            else if (_previewError != null)
              ErrorView(
                message: _previewError!,
                height: 210,
                onRetry: () => _select(_selected!),
              )
            else if (_periods != null && _periods!.isEmpty) ...[
              const Icon(
                Icons.calendar_today_outlined,
                size: 38,
                color: AppColors.outline,
              ),
              const SizedBox(height: 12),
              const Text(
                'لم يُعدّ جدول هذا الصف بعد',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _editing ? null : () => _edit(_selected!),
                icon: const Icon(Icons.add),
                label: const Text('إعداد جدول الصف'),
              ),
            ] else if (_periods != null) ...[
              _weekTable(),
            ],
          ],
        ),
      ),
      const SizedBox(height: 18),
      AppCard(
        color: AppColors.surfaceMuted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تنظيم الجدول',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '• أيام الدراسة من الأحد إلى الخميس.\n• كل يوم مسجّل يحتوي 5 أو 6 حصص متتالية.\n• يمكن ترك يوم كامل دون حصص.\n• الحفظ يحدّث جدول الصف المحدد لأولياء الأمور.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSub,
                height: 1.8,
              ),
            ),
            if (_periods != null &&
                _periods!.any((p) => p.teacher?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              const Divider(),
              const Text(
                'معلمو حصص الصف',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _periods!
                    .map((p) => p.teacher)
                    .whereType<String>()
                    .where((s) => s.isNotEmpty)
                    .toSet()
                    .join('، '),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
  Widget _weekTable() {
    final byCell = {for (final p in _periods!) '${p.day}/${p.number}': p};
    return LayoutBuilder(
      builder: (_, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 820 ? 820 : constraints.maxWidth,
            child: Table(
              columnWidths: const {0: FixedColumnWidth(90)},
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: const TableBorder(
                horizontalInside: BorderSide(color: AppColors.border),
              ),
              children: [
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'اليوم',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    for (var n = 1; n <= 6; n++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '$n',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                for (final day in scheduleWeekdays)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      for (var n = 1; n <= 6; n++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 8,
                          ),
                          child: () {
                            final period = byCell['$day/$n'];
                            return Tooltip(
                              message: period == null
                                  ? 'لا توجد حصة'
                                  : '${period.subject}${period.teacher == null ? '' : '\n${period.teacher}'}',
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 64,
                                ),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: period == null
                                      ? AppColors.background
                                      : AppColors.accentSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  period?.subject ?? '—',
                                  softWrap: true,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: period == null
                                        ? AppColors.outline
                                        : AppColors.brand,
                                  ),
                                ),
                              ),
                            );
                          }(),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
