import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/accounts_errors.dart';
import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../core/baghdad_time.dart';
import '../core/iraqi_phone.dart';
import '../models/teacher.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dropdown.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/pill.dart';
import '../widgets/layout/app_header.dart';
import '../widgets/teachers/teacher_form_dialog.dart';
import '../widgets/ui/kpi_tile.dart';
import '../widgets/ui/letter_avatar.dart';
import '../widgets/ui/seg_tabs.dart';
import '../widgets/ui/ui_table.dart';

enum _TeachersView { list, attendance }

BadgeTone _statusTone(TeacherStatus s) => switch (s) {
  TeacherStatus.active => BadgeTone.ok,
  TeacherStatus.onLeave => BadgeTone.warn,
  TeacherStatus.transferred => BadgeTone.tint,
  TeacherStatus.retired => BadgeTone.gray,
};

/// المعلمون: القائمة (بحث وحالة وإضافة وتعديل) وحضورهم اليومي.
/// لا حذف للمعلم؛ الحالة هي البديل.
class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  _TeachersView _view = _TeachersView.list;

  final _search = TextEditingController();
  Timer? _debounce;
  TeacherStatus? _status;
  List<Teacher>? _teachers;
  String? _error;
  bool _loading = false;
  int _seq = 0;

  DateTime _date = BaghdadTime.today();
  TeacherAttendanceDay? _day;
  String? _dayError;
  bool _dayLoading = false;

  bool _started = false;

  AdminApi get _api => AppScope.of(context).api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.teachers(search: _search.text, status: _status);
      if (!mounted || seq != _seq) return;
      setState(() {
        _teachers = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = e.accountsMessage;
        _loading = false;
      });
    }
  }

  Future<void> _loadDay() async {
    setState(() {
      _dayLoading = true;
      _dayError = null;
    });
    final requested = _date;
    try {
      final day = await _api.teachersAttendance(requested);
      if (!mounted || requested != _date) return;
      setState(() {
        _day = day;
        _dayLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requested != _date) return;
      setState(() {
        _dayError = e.accountsMessage;
        _dayLoading = false;
      });
    }
  }

  void _setView(_TeachersView v) {
    setState(() => _view = v);
    if (v == _TeachersView.attendance && _day == null) _loadDay();
  }

  void _setDate(DateTime d) {
    setState(() {
      _date = DateTime(d.year, d.month, d.day);
      _day = null;
    });
    _loadDay();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<List<String>> _specializations() async {
    try {
      return await _api.teacherSpecializations();
    } on ApiException {
      return const [];
    }
  }

  Future<void> _add() async {
    final specs = await _specializations();
    if (!mounted) return;
    final saved = await TeacherFormDialog.show(
      context,
      specializations: specs,
      onSubmit: (input) async {
        await _api.createTeacher(input);
      },
    );
    if (!saved || !mounted) return;
    showAppToast(context, 'تمت إضافة المعلم');
    _load();
    _day = null;
  }

  Future<void> _edit(Teacher t) async {
    Teacher fresh = t;
    try {
      fresh = await _api.teacher(t.id);
    } on ApiException catch (e) {
      if (mounted) _toastError(e.accountsMessage);
      return;
    }
    final specs = await _specializations();
    if (!mounted) return;
    final saved = await TeacherFormDialog.show(
      context,
      editing: fresh,
      specializations: specs,
      onSubmit: (input) async {
        await _api.updateTeacher(fresh.id, input);
      },
    );
    if (!saved || !mounted) return;
    showAppToast(context, 'تم تحديث بيانات المعلم');
    _load();
    _day = null;
  }

  void _toastError(String message) => showAppToast(
    context,
    message,
    icon: LucideIcons.circleAlert,
    iconColor: AppColors.red,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'المعلمون',
          badge: _teachers == null
              ? null
              : Pill.tone('${_teachers!.length} معلماً', BadgeTone.tint),
          actions: [
            AppButton(
              label: 'تحديث',
              icon: LucideIcons.refreshCw,
              style: AppButtonStyle.outline,
              onPressed: _view == _TeachersView.list
                  ? (_loading ? null : _load)
                  : (_dayLoading ? null : _loadDay),
            ),
          ],
          cta: AppButton(
            label: 'إضافة معلم',
            icon: LucideIcons.plus,
            style: AppButtonStyle.amber,
            onPressed: _add,
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SegTabs<_TeachersView>(
            value: _view,
            onChanged: _setView,
            items: const [
              (_TeachersView.list, 'قائمة المعلمين'),
              (_TeachersView.attendance, 'حضور المعلمين'),
            ],
            icons: const [LucideIcons.users, LucideIcons.fingerprintPattern],
          ),
        ),
        const SizedBox(height: 20),
        if (_view == _TeachersView.list) _list() else _attendance(),
      ],
    );
  }

  // ------------------------------------------------------------- القائمة

  Widget _list() {
    final teachers = _teachers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 340,
                child: AppTextField(
                  controller: _search,
                  prefixIcon: LucideIcons.search,
                  hint: 'ابحث بالاسم أو برقم الهاتف (3 أرقام فأكثر)',
                  onChanged: _onSearch,
                  fill: AppColors.canvas,
                ),
              ),
              SizedBox(
                width: 200,
                child: AppDropdown<TeacherStatus?>(
                  value: _status,
                  fill: AppColors.canvas,
                  items: [
                    const DropdownItem(null, 'كل الحالات'),
                    for (final s in TeacherStatus.values)
                      DropdownItem(s, s.label),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v);
                    _load();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (teachers == null)
          _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : const LoadingView()
        else
          AppCard(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: teachers.isEmpty
                ? const EmptyView(
                    message: 'لا يوجد معلمون مطابقون',
                    icon: LucideIcons.users,
                  )
                : UiTable(
                    columns: const [
                      UiCol('المعلم', flex: 4, minWidth: 240),
                      UiCol('التخصص', flex: 3, minWidth: 140),
                      UiCol('الهاتف', flex: 3, minWidth: 140),
                      UiCol('رقم البصمة', flex: 2, minWidth: 110),
                      UiCol('الحالة', flex: 2, minWidth: 130),
                      UiCol('الإجراءات', flex: 1, minWidth: 90),
                    ],
                    rows: [for (final t in teachers) _row(t)],
                  ),
          ),
      ],
    );
  }

  UiRow _row(Teacher t) => UiRow(
    key: ValueKey(t.id),
    cells: [
      PersonCell(
        avatar: LetterAvatar(name: t.fullName),
        title: t.fullName,
        subtitle: t.gender == 'female' ? 'معلمة' : 'معلم',
      ),
      Text(
        (t.specialization ?? '').isEmpty ? '—' : t.specialization!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: AppColors.text),
      ),
      LtrText(IraqiPhone.display(t.phone)),
      t.rfidTag == null
          ? Pill.tone('غير مسجل', BadgeTone.gray)
          : Pill.tone(t.rfidTag!, BadgeTone.tint, ltr: true, mono: true),
      Pill.tone(t.status.label, _statusTone(t.status)),
      IconActionButton(
        icon: LucideIcons.pencil,
        tooltip: 'تعديل بيانات المعلم',
        onPressed: () => _edit(t),
      ),
    ],
  );

  // -------------------------------------------------------------- الحضور

  Widget _attendance() {
    final day = _day;
    final today = BaghdadTime.today();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconActionButton(
                icon: LucideIcons.chevronRight,
                tooltip: 'اليوم السابق',
                onPressed: () =>
                    _setDate(_date.subtract(const Duration(days: 1))),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.control),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100, 12, 31),
                  );
                  if (picked != null) _setDate(picked);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        BaghdadTime.apiDate(_date),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconActionButton(
                icon: LucideIcons.chevronLeft,
                tooltip: 'اليوم التالي',
                onPressed: () => _setDate(_date.add(const Duration(days: 1))),
              ),
              const Spacer(),
              if (_date != today)
                AppButton(
                  label: 'اليوم',
                  style: AppButtonStyle.soft,
                  small: true,
                  onPressed: () => _setDate(today),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (day == null)
          _dayError != null
              ? ErrorView(message: _dayError!, onRetry: _loadDay)
              : const LoadingView()
        else ...[
          if (!day.schoolDay) ...[
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.calendarOff,
                    color: AppColors.warnText,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'يوم عطلة: ${day.dayInfo.label}. لا يُعدّ أي معلم «لم يبصم» في الأيام المغلقة.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          KpiGrid(
            children: [
              KpiTile(
                label: 'بصموا',
                value: '${day.punched}',
                icon: LucideIcons.fingerprintPattern,
              ),
              KpiTile(
                label: 'لم يبصموا',
                value: '${day.missing}',
                icon: LucideIcons.circleAlert,
              ),
              KpiTile(
                label: 'المعلمون في القائمة',
                value: '${day.entries.length}',
                icon: LucideIcons.users,
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: day.entries.isEmpty
                ? const EmptyView(
                    message: 'لا توجد بصمات ولا معلمون فعّالون لهذا اليوم',
                    icon: LucideIcons.fingerprintPattern,
                  )
                : UiTable(
                    columns: const [
                      UiCol('المعلم', flex: 4, minWidth: 220),
                      UiCol('الحالة', flex: 2, minWidth: 130),
                      UiCol('أول بصمة', flex: 2, minWidth: 110),
                      UiCol('آخر بصمة', flex: 2, minWidth: 110),
                      UiCol('عدد البصمات', flex: 2, minWidth: 110),
                    ],
                    rows: [
                      for (final e in day.entries)
                        UiRow(
                          key: ValueKey(e.teacherId),
                          cells: [
                            PersonCell(
                              avatar: LetterAvatar(name: e.fullName),
                              title: e.fullName,
                            ),
                            e.notPunched
                                ? Pill.tone('لم يبصم', BadgeTone.bad)
                                : e.punchCount > 0
                                ? Pill.tone('بصم', BadgeTone.ok)
                                : Pill.tone(e.status.label, BadgeTone.gray),
                            _time(e.firstPunch),
                            _time(e.lastPunch),
                            Text(
                              '${e.punchCount}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          const Text(
            'لا توجد قواعد تأخير أو غياب للمعلمين؛ وقت الوصول هو المعلومة. '
            'آخر بصمة تظهر عند وجود بصمتين فأكثر، وبصمات المعلمين لا ترسل إشعارات.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _time(String? t) => t == null
      ? const Text('—', style: TextStyle(color: AppColors.textMuted))
      : LtrText(t);
}
