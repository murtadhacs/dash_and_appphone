import 'package:flutter/material.dart';

import 'api/api_exception.dart';
import 'data/parent_data.dart';
import 'models/models.dart';
import 'screens/attendance_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/fade_route.dart';
import 'widgets/phone_bottom_nav.dart';
import 'widgets/student_bottom_sheet.dart';

/// Main navigation container: the five tab pages, the floating bottom nav,
/// and the student-switcher sheet overlay.
///
/// البيانات كلها في [ParentData] (حُمّلت في شاشة التحميل)؛ هنا نعرضها ونحدّثها
/// عند السحب للتحديث أو عند العودة إلى التطبيق.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.data});

  final ParentData data;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  AppTab _currentTab = AppTab.home;
  bool _isStudentSwitcherOpen = false;

  ParentData get _data => widget.data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// عند العودة إلى التطبيق: حضور اليوم والإشعارات قد تغيّرت.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(silent: true);
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      try {
        await _data.api.refreshDeviceRegistration();
      } catch (_) {}
      await _data.refresh();
    } on ApiException catch (e) {
      if (silent || e.needsLogin || !mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _selectTab(AppTab tab) => setState(() => _currentTab = tab);

  void _openStudentSwitcher() => setState(() => _isStudentSwitcherOpen = true);

  void _closeStudentSwitcher() =>
      setState(() => _isStudentSwitcherOpen = false);

  Future<void> _handleLogout() async {
    await _data.api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      FadeRoute(
        page: const LoginScreen(),
        duration: const Duration(milliseconds: 250),
      ),
      (route) => false,
    );
  }

  Widget _buildPage() {
    switch (_currentTab) {
      case AppTab.home:
        return HomeScreen(
          key: const ValueKey('home'),
          data: _data,
          onRefresh: _refresh,
          onOpenStudentSwitcher: _openStudentSwitcher,
          onNavigateToSchedule: () => _selectTab(AppTab.schedule),
          onNavigateToAttendance: () => _selectTab(AppTab.attendance),
          onNavigateToNotifications: () => _selectTab(AppTab.notifications),
        );
      case AppTab.attendance:
        return AttendanceScreen(
          key: const ValueKey('attendance'),
          data: _data,
          onOpenStudentSwitcher: _openStudentSwitcher,
        );
      case AppTab.schedule:
        return ScheduleScreen(
          key: const ValueKey('schedule'),
          data: _data,
          onOpenStudentSwitcher: _openStudentSwitcher,
        );
      case AppTab.notifications:
        return NotificationsScreen(
          key: const ValueKey('notifications'),
          data: _data,
          onRefresh: _refresh,
        );
      case AppTab.settings:
        return SettingsScreen(
          key: const ValueKey('settings'),
          data: _data,
          onLogout: _handleLogout,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isStudentSwitcherOpen && _currentTab == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isStudentSwitcherOpen) {
          _closeStudentSwitcher();
        } else if (_currentTab != AppTab.home) {
          _selectTab(AppTab.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ListenableBuilder(
          listenable: _data,
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              _buildPage(),
              PhoneBottomNav(
                currentTab: _currentTab,
                onSelectTab: _selectTab,
                unreadNotificationsCount: _data.unreadCount,
              ),
              if (_isStudentSwitcherOpen)
                StudentBottomSheet(
                  students: _data.students,
                  currentStudent: _data.currentStudent,
                  onSelectStudent: _data.selectStudent,
                  onClose: _closeStudentSwitcher,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
