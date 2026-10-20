import 'package:flutter/material.dart';

import 'api/app_services.dart';
import 'core/app_colors.dart';
import 'core/responsive.dart';
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
import 'widgets/layout/app_header.dart';
import 'widgets/layout/sidebar.dart';

/// الهيكل العام: شريط جانبي + هيدر + الشاشة الحالية، وإدارة الجلسة.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  NavigationTab _tab = NavigationTab.login;
  bool _booting = true;
  bool _started = false;

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
    });
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
        return CommunicationsScreen(
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_tab == NavigationTab.login) {
      return LoginScreen(
        onLoginSuccess: () => setState(() => _tab = NavigationTab.dashboard),
      );
    }

    final desktop = Breakpoints.isDesktop(context);
    final width = MediaQuery.sizeOf(context).width;
    final username = AppScope.of(context).api.username;
    final sidebar = Sidebar(
      currentTab: _tab,
      onSelectTab: _select,
      username: username,
    );

    final content = Column(
      children: [
        AppHeader(
          title: _titleFor(_tab),
          onToggleSidebar: () => _scaffoldKey.currentState?.openDrawer(),
          onLogout: _logout,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              width >= Breakpoints.md ? 32 : 16,
              20,
              width >= Breakpoints.md ? 32 : 16,
              40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                // مفتاح بحسب التبويب ليُعاد بناء الشاشة عند التبديل.
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: _buildScreen(),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    // سطح المكتب: إطار كحلي بزوايا مدوّرة يضم الشريط الجانبي (يمين في RTL)
    // ولوحة المحتوى العائمة. الشاشات الصغيرة: لوحة كاملة + Drawer.
    if (desktop) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.viewport,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.shell),
            ),
            child: Row(
              children: [
                sidebar,
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.canvas),
                    child: ColoredBox(
                      color: AppColors.background,
                      child: content,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  String _titleFor(NavigationTab tab) {
    switch (tab) {
      case NavigationTab.dashboard:
        return 'نظرة عامة';
      case NavigationTab.students:
        return 'الطلاب وأولياء الأمور';
      case NavigationTab.attendance:
        return 'الحضور والغياب';
      case NavigationTab.devices:
        return 'الأجهزة وبوابات الحضور';
      case NavigationTab.banners:
        return 'الإعلانات والإشعارات';
      case NavigationTab.schedule:
        return 'الجدول الدراسي';
      case NavigationTab.settings:
        return 'الإعدادات العامة';
      case NavigationTab.activityLog:
        return 'سجل النشاط';
      case NavigationTab.login:
        return '';
    }
  }
}
