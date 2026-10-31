import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'common.dart';

class _NavTab {
  const _NavTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badge = 0,
  });

  final AppTab id;
  final String label;
  final IconData icon; // light stroke
  final IconData activeIcon; // medium stroke
  final int badge;
}

/// Floating pill navigation bar pinned to the bottom of the main screens.
class PhoneBottomNav extends StatelessWidget {
  const PhoneBottomNav({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    this.unreadNotificationsCount = 3,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onSelectTab;
  final int unreadNotificationsCount;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _NavTab(
        id: AppTab.home,
        label: 'الرئيسية',
        icon: LucideIcons.school300,
        activeIcon: LucideIcons.school500,
      ),
      const _NavTab(
        id: AppTab.attendance,
        label: 'الحضور',
        icon: LucideIcons.userRoundCheck300,
        activeIcon: LucideIcons.userRoundCheck500,
      ),
      const _NavTab(
        id: AppTab.schedule,
        label: 'الجدول',
        icon: LucideIcons.notebookTabs300,
        activeIcon: LucideIcons.notebookTabs500,
      ),
      _NavTab(
        id: AppTab.notifications,
        label: 'الإشعارات',
        icon: LucideIcons.bell300,
        activeIcon: LucideIcons.bell500,
        badge: unreadNotificationsCount,
      ),
      const _NavTab(
        id: AppTab.settings,
        label: 'الإعدادات',
        icon: LucideIcons.slidersHorizontal300,
        activeIcon: LucideIcons.slidersHorizontal500,
      ),
    ];

    return Positioned(
      left: 12,
      right: 12,
      bottom: navBottomInset(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x29282C46),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Color(0x0F282C46),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                for (final tab in tabs)
                  Expanded(
                    child: _NavButton(
                      tab: tab,
                      isActive: currentTab == tab.id,
                      onTap: () => onSelectTab(tab.id),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.brandPurple : AppColors.textMuted;

    return Tap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  size: 20,
                  color: color,
                ),
                if (tab.badge > 0 && !isActive)
                  Positioned(
                    top: -2,
                    right: -3,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.brandPurple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.white, spreadRadius: 2),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              maxLines: 1,
              softWrap: false,
              style: AppText.style(
                size: 9,
                weight: isActive ? AppText.extrabold : AppText.semibold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
