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
  final IconData icon; // stroke ≈ 1.8
  final IconData activeIcon; // stroke 2.5
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
        icon: LucideIcons.home400,
        activeIcon: LucideIcons.home500,
      ),
      const _NavTab(
        id: AppTab.attendance,
        label: 'الحضور',
        icon: LucideIcons.calendarCheck400,
        activeIcon: LucideIcons.calendarCheck500,
      ),
      const _NavTab(
        id: AppTab.schedule,
        label: 'الجدول',
        icon: LucideIcons.bookOpen400,
        activeIcon: LucideIcons.bookOpen500,
      ),
      _NavTab(
        id: AppTab.notifications,
        label: 'الإشعارات',
        icon: LucideIcons.bell400,
        activeIcon: LucideIcons.bell500,
        badge: unreadNotificationsCount,
      ),
      const _NavTab(
        id: AppTab.settings,
        label: 'الإعدادات',
        icon: LucideIcons.settings400,
        activeIcon: LucideIcons.settings500,
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
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.gray100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPurple.withValues(alpha: 0.14),
                  blurRadius: 36,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
                const BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
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
                  size: 16,
                  color: color,
                ),
                if (tab.badge > 0 && !isActive)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.rose500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
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
