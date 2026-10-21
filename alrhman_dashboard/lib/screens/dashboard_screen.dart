import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../core/baghdad_time.dart';
import '../models/attendance_entry.dart';
import '../models/dashboard_stats.dart';
import '../models/device.dart';
import '../models/navigation_tab.dart';
import '../models/student.dart';
import '../services/excel_export_service.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/pill.dart';
import '../widgets/layout/app_header.dart';
import '../widgets/layout/shell_scope.dart';
import '../widgets/ui/kpi_tile.dart';
import '../widgets/common/async_states.dart';
import '../widgets/dashboard/attendance_donut_card.dart';
import '../widgets/dashboard/dashboard_hero.dart';
import '../widgets/dashboard/devices_summary_card.dart';
import '../widgets/dashboard/live_feed_card.dart';
import 'attendance_screen.dart' show attendancePollInterval;

/// لقطة كاملة لبيانات لوحة التحكم.
class _Snapshot {
  final DashboardStats stats;
  final AttendanceDay today;
  final List<Device> devices;
  final Map<int, Student> students;
  const _Snapshot(this.stats, this.today, this.devices, this.students);
}

/// شاشة لوحة التحكم الرئيسية (بيانات حيّة، تتحدّث كل 20 ثانية).
class DashboardScreen extends StatefulWidget {
  final ValueChanged<NavigationTab> onNavigate;
  final VoidCallback onOpenQuickLeave;
  final VoidCallback onOpenAddStudent;
  final VoidCallback onOpenSchedule, onOpenBanner;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenQuickLeave,
    required this.onOpenAddStudent,
    required this.onOpenSchedule,
    required this.onOpenBanner,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static final _timeFmt = DateFormat('HH:mm:ss', 'en');
  static final _dayFmt = DateFormat('EEEE', 'ar');

  _Snapshot? _data;
  String? _error;
  bool _refreshing = false;
  bool _exporting = false;
  bool _started = false;
  DateTime? _lastUpdated;
  Timer? _timer;

  AdminApi get _api => AppScope.of(context).api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
    _timer = Timer.periodic(attendancePollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      if (!silent) _error = null;
    });
    try {
      final today = BaghdadTime.today();
      final results = await Future.wait([
        _api.dashboard(),
        _api.attendance(today),
        _api.devices(),
        // قائمة الطلاب للصف والشعبة فقط؛ فشلها لا يمنع عرض اللوحة.
        _api.students().catchError((_) => <Student>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _data = _Snapshot(
          results[0] as DashboardStats,
          results[1] as AttendanceDay,
          results[2] as List<Device>,
          {for (final s in results[3] as List<Student>) s.id: s},
        );
        _error = null;
        _lastUpdated = DateTime.now();
        _refreshing = false;
      });
      ShellScope.maybeOf(context)?.reportDay((results[0] as DashboardStats).dayInfo);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        // عند فشل تحديث صامت نُبقي البيانات السابقة.
        if (!silent || _data == null) _error = e.message;
      });
    }
  }

  Future<void> _exportToday() async {
    setState(() => _exporting = true);
    try {
      final date = BaghdadTime.today();
      final file = await _api.exportAttendanceExcel(date);
      final saved = await ExcelExportService.saveXlsx(
        file.fileName ?? 'attendance_${BaghdadTime.apiDate(date)}.xlsx',
        file.bytes,
      );
      if (!mounted) return;
      if (saved) showAppToast(context, 'تم حفظ تقرير حضور اليوم');
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
    icon: LucideIcons.circleAlert,
    iconColor: AppColors.red,
  );

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final header = PageHeader(
      title: 'نظرة عامة',
      badge: Pill.tone(
        'اليوم · ${_dayFmt.format(BaghdadTime.today())}',
        BadgeTone.gray,
      ),
    );
    if (data == null) {
      return Column(
        children: [
          header,
          const SizedBox(height: 24),
          _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : const LoadingView(),
        ],
      );
    }

    final s = data.stats;
    final info = s.dayInfo;
    String pct(int v) => '${s.percentOf(v).toStringAsFixed(1)}%';

    final donut = info.isSchool
        ? AttendanceDonutCard(stats: s)
        : AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardTitle(info.label),
                const SizedBox(height: 10),
                if (info.notes != null)
                  Text(
                    info.notes!,
                    style: const TextStyle(color: AppColors.textSub),
                  ),
                const SizedBox(height: 6),
                const Text(
                  'لا دوام اليوم ولا يُحتسب غياب.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          );
    final feed = LiveFeedCard(
      arrivals: data.today.arrivals,
      students: data.students,
      lastUpdated: _lastUpdated == null
          ? '—'
          : '\u2066${_timeFmt.format(_lastUpdated!)}\u2069',
      refreshing: _refreshing,
      onRefresh: _load,
      onOpenFullLog: () => widget.onNavigate(NavigationTab.attendance),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 28),
        DashboardHero(
          onAddStudent: widget.onOpenAddStudent,
          onGrantLeave: widget.onOpenQuickLeave,
          onExport: _exporting ? null : _exportToday,
          onAddSchedule: widget.onOpenSchedule,
          onAddBanner: widget.onOpenBanner,
        ),
        const SizedBox(height: 24),
        KpiGrid(
          children: [
            KpiTile(
              label: 'إجمالي الطلاب',
              value: '${s.totalStudents}',
              icon: LucideIcons.graduationCap,
              iconBackground: AppColors.tint,
              iconForeground: AppColors.brand,
            ),
            KpiTile(
              label: 'أولياء الأمور',
              value: '${s.totalParents}',
              icon: LucideIcons.users,
              iconBackground: AppColors.tint,
              iconForeground: AppColors.brand,
            ),
            KpiTile(
              label: 'الحاضرون اليوم',
              value: '${s.presentToday}',
              icon: LucideIcons.check,
              iconBackground: AppColors.okBg,
              iconForeground: AppColors.green,
              extra: pct(s.presentToday),
              extraColor: AppColors.green,
            ),
            KpiTile(
              label: 'الغائبون اليوم',
              value: '${s.absentToday}',
              icon: LucideIcons.userX,
              iconBackground: AppColors.badBg,
              iconForeground: AppColors.red,
              extra: pct(s.absentToday),
              extraColor: AppColors.red,
            ),
            KpiTile(
              label: 'المجازون اليوم',
              value: '${s.excusedToday}',
              icon: LucideIcons.calendarX,
              iconBackground: AppColors.warnBg,
              iconForeground: AppColors.warnText,
              extra: pct(s.excusedToday),
              extraColor: AppColors.warnText,
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 1000 && info.isSchool) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 400, child: donut),
                    const SizedBox(width: 20),
                    Expanded(child: feed),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                donut,
                if (info.isSchool) ...[const SizedBox(height: 20), feed],
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        DevicesSummaryCard(
          devices: data.devices,
          onManageDevices: () => widget.onNavigate(NavigationTab.devices),
        ),
      ],
    );
  }
}
