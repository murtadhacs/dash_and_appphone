import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../core/baghdad_time.dart';
import '../core/attendance_policy.dart';
import '../models/attendance_entry.dart';
import '../models/student.dart';
import '../services/excel_export_service.dart';
import '../widgets/attendance/attendance_kpi_row.dart';
import '../widgets/attendance/attendance_table.dart';
import '../widgets/attendance/attendance_toolbar.dart';
import '../widgets/attendance/leave_dialog.dart';
import '../widgets/attendance/holiday_controls.dart';
import '../widgets/attendance/manual_attendance_dialog.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/async_states.dart';

/// فترة تحديث حضور اليوم تلقائياً.
const attendancePollInterval = Duration(seconds: 20);

/// شاشة الحضور والإجازات (بيانات حيّة من `/api/admin/attendance`).
class AttendanceScreen extends StatefulWidget {
  /// يفتح نافذة الإجازة تلقائياً (اختصار من لوحة التحكم).
  final bool openLeaveOnStart;
  final VoidCallback? onStartHandled;

  const AttendanceScreen({
    super.key,
    this.openLeaveOnStart = false,
    this.onStartHandled,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static final _labelFmt = DateFormat('EEEE، d MMMM y', 'ar');
  static final _timeFmt = DateFormat('HH:mm:ss', 'en');

  final _search = TextEditingController();
  late DateTime _date = BaghdadTime.today();
  AttendanceFilter _filter = AttendanceFilter.all;

  AttendanceDay? _day;
  Map<int, Student> _studentsById = {};
  List<Student> _students = const [];
  String? _error;
  bool _firstLoadDone = false;
  bool _exporting = false;
  DateTime? _lastUpdated;
  Timer? _timer;
  int _requestSeq = 0;

  AdminApi get _api => AppScope.of(context).api;

  bool get _isToday => _date == BaghdadTime.today();
  AttendancePolicy get _policy => AttendancePolicy(_date);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstLoadDone) return;
    _firstLoadDone = true;
    _loadStudents();
    _load();
    _timer = Timer.periodic(attendancePollInterval, (_) {
      // التحديث التلقائي ليوم اليوم فقط، وبصمت (بدون مؤشر تحميل).
      if (_isToday) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final list = await _api.students();
      if (!mounted) return;
      setState(() {
        _students = list;
        _studentsById = {for (final s in list) s.id: s};
      });
    } on ApiException {
      // الصف والشعبة اختياريان للعرض؛ لا نُظهر خطأ.
    }
  }

  Future<void> _load({bool silent = false}) async {
    final seq = ++_requestSeq;
    final requested = _date;
    if (!silent) setState(() => _error = null);
    try {
      final day = await _api.attendance(requested);
      // تجاهل ردّ قديم إن تغيّر اليوم أثناء الطلب.
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _day = day;
        _error = null;
        _lastUpdated = BaghdadTime.now();
      });
      if (widget.openLeaveOnStart && !silent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onStartHandled?.call();
          _openLeave();
        });
      }
    } on ApiException catch (e) {
      if (!mounted || seq != _requestSeq) return;
      // عند فشل تحديث صامت نُبقي البيانات السابقة ظاهرة.
      if (!silent || _day == null) setState(() => _error = e.message);
    }
  }

  void _goTo(DateTime d) {
    setState(() {
      _date = d;
      _day = null;
      _error = null;
    });
    _load();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: BaghdadTime.today(),
    );
    if (picked != null) _goTo(DateTime(picked.year, picked.month, picked.day));
  }

  List<AttendanceEntry> get _filtered {
    final day = _day;
    if (day == null) return const [];
    final q = _search.text.trim().toLowerCase();
    return day.ordered.where((e) {
      final matchPill = switch (_policy.hideAbsence &&
              _filter == AttendanceFilter.absent
          ? AttendanceFilter.all
          : _filter) {
        AttendanceFilter.all => true,
        AttendanceFilter.present => e.status == PresenceStatus.present,
        AttendanceFilter.absent => e.status == PresenceStatus.absent,
        AttendanceFilter.excused => e.status == PresenceStatus.excused,
      };
      final grade =
          _studentsById[e.studentId]?.gradeSection.toLowerCase() ?? '';
      final matchSearch =
          q.isEmpty ||
          e.fullName.toLowerCase().contains(q) ||
          grade.contains(q);
      return matchPill && matchSearch;
    }).toList();
  }

  Future<void> _openLeave([int? studentId]) async {
    if (_students.isEmpty) await _loadStudents();
    if (!mounted) return;
    if (_students.isEmpty) {
      _toastError(
        'لا توجد قائمة طلاب فعّالة متاحة، حدّث الصفحة وحاول مرة أخرى',
      );
      return;
    }
    final saved = await LeaveDialog.show(
      context,
      students: _students,
      initialDate: _date,
      prefillStudentId: studentId,
      onSubmit: (id, date, notes) async {
        try {
          await _api.createLeave(studentId: id, date: date, notes: notes);
          if (mounted) await _load(silent: true);
        } on ApiException catch (e) {
          if (e.statusCode == 404) {
            throw ApiException(
              statusCode: 404,
              message: 'الطالب غير موجود أو معطّل، حدّث القائمة وحاول مجدداً',
            );
          }
          rethrow;
        }
      },
    );
    if (!saved || !mounted) return;
    showAppToast(
      context,
      'تم تسجيل الإجازة بنجاح وتحديث كشف الحضور',
      background: AppColors.greenDeep,
    );
    _load();
  }

  Future<void> _cancelLeave(AttendanceEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الإجازة'),
        content: Text(
          'هل تريد إلغاء إجازة "${e.fullName}" ليوم ${_labelFmt.format(_date)}؟\n'
          'سيتم تحديث حالة الطالب وفق سجل حضوره ونوع اليوم.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، ألغِ الإجازة'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.cancelLeave(studentId: e.studentId, date: _date);
      if (!mounted) return;
      showAppToast(context, 'تم إلغاء الإجازة');
      _load();
    } on ApiException catch (err) {
      if (!mounted) return;
      _toastError(err.message);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final file = await _api.exportAttendanceExcel(_date);
      final saved = await ExcelExportService.saveXlsx(
        file.fileName ?? 'attendance_${BaghdadTime.apiDate(_date)}.xlsx',
        file.bytes,
      );
      if (!mounted) return;
      if (saved) {
        showAppToast(
          context,
          'تم حفظ تقرير الحضور',
          subtitle: 'ملف Excel ليوم ${BaghdadTime.apiDate(_date)}',
        );
      }
    } on ApiException catch (e) {
      if (mounted) _toastError(e.message);
    } catch (_) {
      if (mounted) _toastError('تعذر حفظ الملف');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _toastError(String message) => showAppToast(
    context,
    message,
    icon: Icons.error_outline,
    iconColor: AppColors.red,
  );

  @override
  Widget build(BuildContext context) {
    final day = _day;
    if (day == null) {
      return _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : const LoadingView();
    }

    final counts = {
      AttendanceFilter.all: day.entries.length,
      AttendanceFilter.present: day.count(PresenceStatus.present),
      AttendanceFilter.absent: _policy.hideAbsence
          ? 0
          : day.count(PresenceStatus.absent),
      AttendanceFilter.excused: day.count(PresenceStatus.excused),
    };

    return Column(
      children: [
        HolidayControls(api: _api, onChanged: () => _load()),
        const SizedBox(height: 16),
        AttendanceKpiRow(
          day: day,
          hideAbsence: _policy.hideAbsence,
          live: _isToday,
          lastUpdated: _lastUpdated == null
              ? '—'
              : '\u2066${_timeFmt.format(_lastUpdated!)}\u2069',
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: EdgeInsets.zero,
          clip: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AttendanceToolbar(
                dateLabel: _labelFmt.format(_date),
                isToday: _isToday,
                canGoNext: !_isToday,
                onPrev: () => _goTo(_date.subtract(const Duration(days: 1))),
                onNext: () => _goTo(_date.add(const Duration(days: 1))),
                onToday: () => _goTo(BaghdadTime.today()),
                onPickDate: _pickDate,
                filter: _filter,
                onFilterChanged: (f) => setState(() => _filter = f),
                counts: counts,
                onGrantLeave: _openLeave,
                onExport: _exportExcel,
                exporting: _exporting,
                hideAbsence: _policy.hideAbsence,
              ),
              if (!day.dayInfo.isSchool || _policy.weekend)
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    _policy.weekend ? 'عطلة نهاية الأسبوع' : day.dayInfo.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (!day.dayInfo.isSchool && day.dayInfo.notes != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(day.dayInfo.notes!),
                ),
              if (day.dayInfo.isSchool && _policy.awaitingArrival)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'قبل 09:31 بتوقيت بغداد: الطلاب الذين لم يصلوا بعد لا يُحتسبون غائبين.',
                  ),
                ),
              if (_error != null)
                Container(
                  width: double.infinity,
                  color: AppColors.redSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    '$_error — تُعرض آخر بيانات محمّلة',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.redDark,
                    ),
                  ),
                ),
              if (day.dayInfo.isSchool && !_policy.weekend)
                AttendanceTable(
                  entries: _filtered,
                  students: _studentsById,
                  live: _isToday,
                  searchController: _search,
                  onSearchChanged: (_) => setState(() {}),
                  onRegisterExcuse: (e) => _openLeave(e.studentId),
                  onCancelLeave: _cancelLeave,
                  onManualAttendance: (e) => ManualAttendanceDialog.show(
                    context,
                    student: e,
                    initialDate: _date,
                  ),
                  weekend: _policy.weekend,
                  awaitingArrival: _policy.awaitingArrival,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
