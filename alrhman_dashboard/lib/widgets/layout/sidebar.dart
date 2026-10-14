import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/responsive.dart';
import '../../core/assets.dart';
import '../../models/navigation_tab.dart';

class _NavItem {
  final NavigationTab tab;
  final String label;
  final IconData icon;
  const _NavItem(this.tab, this.label, this.icon);
}

const _navItems = [
  _NavItem(NavigationTab.dashboard, 'لوحة التحكم', Icons.dashboard_outlined),
  _NavItem(
    NavigationTab.students,
    'الطلاب وأولياء الأمور',
    Icons.school_outlined,
  ),
  _NavItem(
    NavigationTab.attendance,
    'الحضور والاجازات',
    Icons.event_available_outlined,
  ),
  _NavItem(NavigationTab.devices, 'الأجهزة وبوابات الحضور', Icons.fingerprint),
  _NavItem(
    NavigationTab.schedule,
    'الجدول الدراسي',
    Icons.calendar_view_week_outlined,
  ),
  _NavItem(
    NavigationTab.banners,
    'الإعلانات والإشعارات',
    Icons.photo_library_outlined,
  ),
  _NavItem(NavigationTab.settings, 'الإعدادات العامة', Icons.settings_outlined),
  _NavItem(NavigationTab.activityLog, 'سجل النشاط', Icons.history_outlined),
];

/// الشريط الجانبي: يظهر ثابتاً على الشاشات الكبيرة وداخل Drawer على الصغيرة.
class Sidebar extends StatelessWidget {
  final NavigationTab currentTab;
  final ValueChanged<NavigationTab> onSelectTab;

  const Sidebar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Breakpoints.sidebarWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          _brandHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 10, 8, 10),
                  child: Text(
                    'القائمة الرئيسية',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                for (final item in _navItems)
                  _NavTile(
                    item: item,
                    active: item.tab == currentTab,
                    onTap: () => onSelectTab(item.tab),
                  ),
              ],
            ),
          ),
          _statusFooter(),
        ],
      ),
    );
  }

  Widget _brandHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Image.asset(appLogoAsset, height: 40, fit: BoxFit.contain),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرحمن الابتدائية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'نظام الإدارة المدرسية',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSub,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: const Text(
        'الرحمن الابتدائية • الإصدار 1.0',
        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? AppColors.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: AppColors.border,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              // الشريط البرتقالي على الحافة اليمنى للعنصر النشط.
              border: Border(
                right: BorderSide(
                  color: active ? AppColors.amber : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: active ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.bold : FontWeight.w500,
                      color: active ? AppColors.primary : AppColors.textSub,
                    ),
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
