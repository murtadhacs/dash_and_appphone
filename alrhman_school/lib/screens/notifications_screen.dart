import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../core/baghdad_time.dart';
import '../data/parent_data.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

/// سجل إشعارات ولي الأمر (`GET /api/mobile/notifications`).
///
/// حالة القراءة على الخادم ومشتركة بين كل هواتف ولي الأمر؛ الشارة من
/// `unread_count` لا من عدّ العناصر المحمّلة.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.data, this.onRefresh});

  final ParentData data;
  final Future<void> Function()? onRefresh;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

enum _Filter { all, today, week, month }

enum _TypeFilter { all, attendance, admin }

class _NotificationsScreenState extends State<NotificationsScreen> {
  _Filter _filter = _Filter.all;
  _TypeFilter _typeFilter = _TypeFilter.all;

  static const _typeLabels = {
    _TypeFilter.all: 'الكل',
    _TypeFilter.attendance: 'الحضور',
    _TypeFilter.admin: 'الإدارة',
  };

  static const _filterLabels = {
    _Filter.all: 'الكل',
    _Filter.today: 'اليوم',
    _Filter.week: 'هذا الأسبوع',
    _Filter.month: 'هذا الشهر',
  };

  /// الحضور: الدخول والخروج والغياب؛ الإدارة: باقي رسائل المدرسة.
  bool _matchesType(AppNotification n) => switch (_typeFilter) {
    _TypeFilter.all => true,
    _TypeFilter.attendance => n.category != NotificationCategory.general,
    _TypeFilter.admin => n.category == NotificationCategory.general,
  };

  bool _matches(AppNotification n) {
    if (!_matchesType(n)) return false;
    final today = BaghdadTime.today();
    final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.today:
        return d == today;
      case _Filter.week:
        // الأسبوع يبدأ الأحد.
        final start = today.subtract(Duration(days: today.weekday % 7));
        return !d.isBefore(start);
      case _Filter.month:
        return d.year == today.year && d.month == today.month;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted || e.needsLogin) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final filtered = data.notifications.where(_matches).toList();
    final showStudentTag = data.students.length > 1;

    return TabPageScroll(
      onRefresh: widget.onRefresh,
      children: [
        // ---------------- Header ----------------
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإشعارات',
                    style: AppText.style(size: 16, weight: AppText.extrabold),
                  ),
                  Text(
                    'رسائل المدرسة وتنبيهات الحضور والانصراف والغياب',
                    style: AppText.style(size: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
              if (data.unreadCount > 0)
                Tap(
                  onTap: () => _run(data.markAllRead),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purple50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.checkCheck,
                          size: 12,
                          color: AppColors.brandPurple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'قراءة الكل (${data.unreadCount})',
                          style: AppText.style(
                            size: 10,
                            weight: AppText.bold,
                            color: AppColors.brandPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------- Type filters ----------------
              NoScrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      for (final f in _TypeFilter.values) ...[
                        if (f != _TypeFilter.all) const SizedBox(width: 6),
                        _FilterChip(
                          label: _typeLabels[f]!,
                          isActive: _typeFilter == f,
                          onTap: () => setState(() => _typeFilter = f),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ---------------- Date filters ----------------
              NoScrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      for (final f in _Filter.values) ...[
                        if (f != _Filter.all) const SizedBox(width: 6),
                        _FilterChip(
                          label: _filterLabels[f]!,
                          isActive: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ---------------- Cards ----------------
              if (filtered.isEmpty)
                _EmptyState(hasAnyNotifications: data.notifications.isNotEmpty)
              else
                for (int i = 0; i < filtered.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _NotificationCard(
                    notif: filtered[i],
                    studentTag: showStudentTag
                        ? data.studentMentionedIn(filtered[i])?.firstName
                        : null,
                    onTap: () => _run(() => data.markRead(filtered[i])),
                  ),
                ],

              // ---------------- Older pages ----------------
              if (data.hasMoreNotifications) ...[
                const SizedBox(height: 12),
                Tap(
                  onTap: data.loadingMoreNotifications
                      ? null
                      : () => _run(data.loadMoreNotifications),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray100),
                    ),
                    child: data.loadingMoreNotifications
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.brandPurple,
                            ),
                          )
                        : Text(
                            'عرض إشعارات أقدم',
                            style: AppText.style(
                              size: 11,
                              weight: AppText.bold,
                              color: AppColors.brandPurple,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandPurple : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? null : Border.all(color: AppColors.gray100),
          boxShadow: isActive ? AppShadows.sm : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AppText.style(
            size: 11,
            weight: isActive ? AppText.bold : AppText.medium,
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAnyNotifications});

  /// True when the filter hid everything; false when there is simply no
  /// notification data at all yet.
  final bool hasAnyNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gray100),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.purple50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasAnyNotifications ? LucideIcons.bell : LucideIcons.bellOff,
              size: 20,
              color: AppColors.brandPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasAnyNotifications
                ? 'لا توجد إشعارات في هذه الفترة'
                : 'صندوق الإشعارات فارغ حالياً',
            textAlign: TextAlign.center,
            style: AppText.style(size: 12, weight: AppText.bold),
          ),
          const SizedBox(height: 8),
          Text(
            hasAnyNotifications
                ? 'اختر فلتر آخر لعرض باقي التنبيهات'
                : 'ستظهر رسائل المدرسة وتنبيهات الحضور والانصراف والغياب هنا فور توفرها.',
            textAlign: TextAlign.center,
            style: AppText.style(size: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notif,
    required this.onTap,
    this.studentTag,
  });

  final AppNotification notif;
  final VoidCallback onTap;
  final String? studentTag;

  @override
  Widget build(BuildContext context) {
    final (iconBg, iconColor, icon, label) = switch (notif.category) {
      NotificationCategory.checkIn => (
        AppColors.presentBg,
        AppColors.present,
        LucideIcons.logIn,
        'دخول',
      ),
      NotificationCategory.checkOut => (
        AppColors.circularBg,
        AppColors.brandBlue,
        LucideIcons.logOut,
        'انصراف',
      ),
      NotificationCategory.absence => (
        AppColors.rose50,
        AppColors.rose600,
        LucideIcons.userX,
        'غياب',
      ),
      NotificationCategory.general => (
        AppColors.purple50,
        AppColors.brandPurple,
        LucideIcons.info,
        'تنبيه',
      ),
    };
    final unread = !notif.isRead;

    return Tap(
      onTap: unread ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread ? AppColors.purple200 : AppColors.gray100,
          ),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            if (unread) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.brandPurple,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                notif.title,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.style(
                                  size: 12,
                                  weight: unread
                                      ? AppText.extrabold
                                      : AppText.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        BaghdadTime.relative(notif.createdAt),
                        style: AppText.style(
                          size: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: AppText.style(
                      size: 11,
                      color: AppColors.textMuted,
                      height: 1.375,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          label,
                          style: AppText.style(
                            size: 8,
                            weight: AppText.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                      if (studentTag != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '($studentTag)',
                          style: AppText.style(
                            size: 8,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
