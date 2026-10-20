import 'dart:async';

import 'package:flutter/material.dart';

import 'api/app_services.dart';
import 'core/app_colors.dart';
import 'core/responsive.dart';
import 'core/school_day_info.dart';
import 'models/navigation_tab.dart';
import 'screens/attendance_screen.dart';
import 'screens/activity_log_screen.dart';
import 'screens/communications_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/students_screen.dart';
import 'widgets/layout/shell_scope.dart';
import 'widgets/layout/sidebar.dart';

/// الهيكل العام بعرض الشاشة كاملة: شريط جانبي كحلي ملاصق لحافة الشاشة
/// (يمين في RTL)، ولوحة محتوى رمادية تملأ الباقي بزاويتين مدوّرتين عند الشريط.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _dayInfo = ValueNotifier<SchoolDayInfo?>(null);

  NavigationTab _tab = NavigationTab.login;
  bool _booting = true;
  bool _started = false;
  bool? _serverOnline;
  Timer? _pingTimer;

  // اختصارات تفتح نوافذ داخل شاشات أخرى
  bool _openAddStudent = false;
  bool _openLeave = false;
  bool _openSchedule = false, _openBanner = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final services = AppScope.of(context);
    // عند 401 على أي طلب موثَّق: نرجع لشاشة الدخول.
    services.client.onUnauthorized = () {
      services.api.logout();
      if (mounted) setState(() => _tab = NavigationTab.login);
    };
    services.api.restoreSession().then((has) {
      if (!mounted) return;
      setState(() {
        _tab = has ? NavigationTab.dashboard : NavigationTab.login;
        _booting = false;
      });
      if (has) _loadDayInfo();
    });
    _ping();
    _pingTimer = Timer.periodic(const Duration(minutes: 1), (_) => _ping());
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _dayInfo.dispose();
    super.dispose();
  }

  Future<void> _ping() async {
    final ok = await AppScope.of(context).client.ping();
    if (mounted && ok != _serverOnline) setState(() => _serverOnline = ok);
  }

  /// حالة اليوم لشارة «الدوام الرسمي قائم» في رأس كل صفحة.
  Future<void> _loadDayInfo() async {
    try {
      final stats = await AppScope.of(context).api.dashboard();
      if (mounted) _dayInfo.value = stats.dayInfo;
    } catch (_) {
      // الشارة اختيارية؛ تبقى مخفية إن تعذرت القراءة.
    }
  }

  void _select(NavigationTab tab) {
    setState(() => _tab = tab);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _logout() async {
    await AppScope.of(context).api.logout();
    if (mounted) setState(() => _tab = NavigationTab.login);
  }

  Widget _buildScreen() {
    switch (_tab) {
      case NavigationTab.dashboard:
        return DashboardScreen(
          onNavigate: _select,
          onOpenSchedule: () => setState(() {
            _tab = NavigationTab.schedule;
            _openSchedule = true;
          }),
          onOpenBanner: () => setState(() {
            _tab = NavigationTab.banners;
            _openBanner = true;
          }),
          onOpenQuickLeave: () => setState(() {
            _tab = NavigationTab.attendance;
            _openLeave = true;
          }),
          onOpenAddStudent: () => setState(() {
            _tab = NavigationTab.students;
            _openAddStudent = true;
          }),
        );
      case NavigationTab.students:
        return StudentsScreen(
          openAddOnStart: _openAddStudent,
          onStartHandled: () => _openAddStudent = false,
        );
      case NavigationTab.attendance:
        return AttendanceScreen(
          openLeaveOnStart: _openLeave,
          onStartHandled: () => _openLeave = false,
        );
      case NavigationTab.devices:
        return const DevicesScreen();
      case NavigationTab.settings:
        return const SettingsScreen();
      case NavigationTab.activityLog:
        return const ActivityLogScreen();
      case NavigationTab.banners:
      case NavigationTab.broadcasts:
        return CommunicationsScreen(
          showBroadcasts: _tab == NavigationTab.broadcasts,
          onSwitch: (broadcasts) => setState(
            () => _tab = broadcasts
                ? NavigationTab.broadcasts
                : NavigationTab.banners,
          ),
          openAddOnStart: _openBanner,
          onStartHandled: () => _openBanner = false,
        );
      case NavigationTab.schedule:
        return ScheduleScreen(
          openAddOnStart: _openSchedule,
          onStartHandled: () => _openSchedule = false,
        );
      case NavigationTab.login:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_tab == NavigationTab.login) {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() => _tab = NavigationTab.dashboard);
          _loadDayInfo();
        },
      );
    }

    final desktop = Breakpoints.isDesktop(context);
    final width = MediaQuery.sizeOf(context).width;
    final sidebar = Sidebar(
      currentTab: _tab,
      onSelectTab: _select,
      username: AppScope.of(context).api.username,
      serverOnline: _serverOnline,
    );
    final pad = width >= Breakpoints.md ? 32.0 : 16.0;
    // كل قسم في التواصل (البنرات/الإشعارات) يبقى نفس الشاشة دون إعادة بناء.
    final screenKey = _tab == NavigationTab.broadcasts
        ? NavigationTab.banners
        : _tab;

    final content = ShellScope(
      onLogout: _logout,
      onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
      showMenuButton: !desktop,
      dayInfo: _dayInfo,
      reportDay: (info) => _dayInfo.value = info,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(pad, 28, pad, 40),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) =>
              current ?? const SizedBox.shrink(),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .015),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(screenKey),
            child: _buildScreen(),
          ),
        ),
      ),
    );

    if (desktop) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.primary,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sidebar,
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(AppRadius.canvas),
                  bottomStart: Radius.circular(AppRadius.canvas),
                ).resolve(Directionality.of(context)),
                child: ColoredBox(color: AppColors.background, child: content),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      // في RTL يفتح الـ drawer من اليمين، مطابقاً لموضع الشريط الجانبي.
      drawer: Drawer(
        width: Breakpoints.sidebarWidth,
        backgroundColor: AppColors.primary,
        child: sidebar,
      ),
      body: SafeArea(child: content),
    );
  }
}
