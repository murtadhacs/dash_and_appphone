import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/baghdad_time.dart';
import '../core/school_days.dart';
import '../data/parent_data.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/common.dart';
import '../widgets/empty_state_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.data,
    this.onRefresh,
    this.onOpenStudentSwitcher,
    this.onNavigateToSchedule,
    this.onNavigateToAttendance,
    this.onNavigateToNotifications,
  });

  final ParentData data;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onOpenStudentSwitcher;
  final VoidCallback? onNavigateToSchedule;
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToNotifications;

  @override
  Widget build(BuildContext context) {
    final student = data.currentStudent;

    if (student == null) {
      return TabPageScroll(
        horizontalPadding: 16,
        onRefresh: onRefresh,
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyStateCard(
              icon: LucideIcons.userX,
              title: 'لا يوجد طالب مرتبط بحسابك',
              subtitle:
                  'سيتم عرض بيانات الطالب هنا بعد ربط حسابك بسجل الطالب في المدرسة.',
            ),
          ),
        ],
      );
    }

    final todayKey = dayKeyOfWeekday(BaghdadTime.today().weekday);
    final todayPeriods = todayKey == null
        ? 0
        : (data.schedules[student.id] ?? const <DaySchedule>[])
                  .where((d) => d.dayKey == todayKey)
                  .firstOrNull
                  ?.periods
                  .length ??
              0;

    return TabPageScroll(
      onRefresh: onRefresh,
      children: [
        // ---------------- App Header ----------------
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Tap(
                  onTap: onOpenStudentSwitcher,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً بك،',
                              style: AppText.style(
                                size: 11,
                                weight: AppText.medium,
                                color: AppColors.textMuted,
                                height: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                data.parent?.name ?? 'ولي أمر الطالب',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.style(
                                  size: 14,
                                  weight: AppText.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Tap(
                onTap: onNavigateToNotifications,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gray100),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        LucideIcons.bell,
                        size: 16,
                        color: AppColors.brandPurple,
                      ),
                      if (data.unreadCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
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
              if (data.banners.isNotEmpty) ...[
                BannerCarousel(banners: data.banners),
                const SizedBox(height: 14),
              ],
              if (!data.dayInfo.isSchool)
                EmptyStateCard(
                  icon: LucideIcons.calendar,
                  title: data.dayInfo.label,
                  subtitle:
                      data.dayInfo.notes ?? 'لا دوام اليوم ولا يُحتسب غياب.',
                ),
              if (data.dayInfo.isSchool)
                _StudentStatusCard(
                  student: student,
                  todayPeriods: todayPeriods,
                  canSwitch: data.students.length > 1,
                  onOpenStudentSwitcher: onOpenStudentSwitcher,
                  onNavigateToSchedule: onNavigateToSchedule,
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: LucideIcons.calendar,
                      iconBg: AppColors.purple50,
                      iconColor: AppColors.brandPurple,
                      title: 'تقويم الحضور',
                      subtitle: 'سجل الشهر والغياب',
                      onTap: onNavigateToAttendance,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      icon: LucideIcons.bookOpen,
                      iconBg: AppColors.blue50,
                      iconColor: AppColors.brandBlue,
                      title: 'الجدول الدراسي',
                      subtitle: todayPeriods > 0
                          ? '$todayPeriods حصص اليوم'
                          : 'الجدول الأسبوعي',
                      onTap: onNavigateToSchedule,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Daily status: مظهر البطاقة حسب حالة اليوم
// ---------------------------------------------------------------------------

/// ألوان ونصوص البطاقة لكل حالة.
class _StatusLook {
  final String badge;
  final String headline;
  final String detail;
  final Color color;
  final Color dark;
  final Color bg;
  final Color border;
  final IconData icon;

  const _StatusLook({
    required this.badge,
    required this.headline,
    required this.detail,
    required this.color,
    required this.dark,
    required this.bg,
    required this.border,
    required this.icon,
  });

  static _StatusLook of(TodayAttendance? t) {
    final now = BaghdadTime.now();
    if (BaghdadTime.isWeekend(now)) {
      return const _StatusLook(
        badge: 'عطلة',
        headline: 'عطلة نهاية الأسبوع',
        detail: 'لا دوام اليوم، نراكم يوم الأحد',
        color: AppColors.gray500,
        dark: AppColors.gray800,
        bg: AppColors.gray50,
        border: AppColors.gray200,
        icon: LucideIcons.sun,
      );
    }
    if (t == null) {
      return const _StatusLook(
        badge: 'غير متوفر',
        headline: 'لا توجد بيانات حضور اليوم',
        detail: 'اسحب للأسفل لتحديث البيانات',
        color: AppColors.gray500,
        dark: AppColors.gray800,
        bg: AppColors.gray50,
        border: AppColors.gray200,
        icon: LucideIcons.circleHelp,
      );
    }
    switch (t.status) {
      case PresenceStatus.present:
        final inTime = t.checkIn;
        final outTime = t.checkOut;
        return _StatusLook(
          badge: 'حاضر',
          headline: inTime != null
              ? 'وقت الوصول: ${BaghdadTime.arabicTime(inTime)}'
              : 'حاضر اليوم',
          detail: outTime != null
              ? 'وقت الانصراف: ${BaghdadTime.arabicTime(outTime)}'
              : 'سُجّلت بصمة الطالب عند البوابة',
          color: AppColors.present,
          dark: AppColors.presentDark,
          bg: AppColors.presentBg,
          border: AppColors.emerald100,
          icon: LucideIcons.check,
        );
      case PresenceStatus.excused:
        return const _StatusLook(
          badge: 'مجاز',
          headline: 'في إجازة معتمدة اليوم',
          detail: 'سجّلت الإدارة إجازة للطالب لهذا اليوم',
          color: AppColors.holiday,
          dark: AppColors.holidayDark,
          bg: AppColors.holidayBg,
          border: AppColors.amber100,
          icon: LucideIcons.calendarCheck,
        );
      case PresenceStatus.absent:
        // "غائب" تشمل من لم يصل بعد؛ قبل الظهر نعرضها كـ"لم يصل بعد".
        if (now.hour < 12) {
          return const _StatusLook(
            badge: 'لم يصل بعد',
            headline: 'لم تُسجَّل بصمة دخول حتى الآن',
            detail: 'يُحدَّث تلقائياً عند وصول الطالب للبوابة',
            color: AppColors.gray500,
            dark: AppColors.gray800,
            bg: AppColors.gray50,
            border: AppColors.gray200,
            icon: LucideIcons.clock,
          );
        }
        return const _StatusLook(
          badge: 'غائب',
          headline: 'لم يُسجَّل حضور الطالب اليوم',
          detail: 'تواصل مع الإدارة إن كان لديه عذر',
          color: AppColors.rose600,
          dark: AppColors.rose700,
          bg: AppColors.rose50,
          border: AppColors.rose100,
          icon: LucideIcons.x,
        );
    }
  }
}

class _StudentStatusCard extends StatelessWidget {
  const _StudentStatusCard({
    required this.student,
    required this.todayPeriods,
    required this.canSwitch,
    this.onOpenStudentSwitcher,
    this.onNavigateToSchedule,
  });

  final Student student;
  final int todayPeriods;
  final bool canSwitch;
  final VoidCallback? onOpenStudentSwitcher;
  final VoidCallback? onNavigateToSchedule;

  @override
  Widget build(BuildContext context) {
    final look = _StatusLook.of(student.today);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: look.border, width: 2),
        boxShadow: AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'حالة الطالب اليوم',
                  style: AppText.style(
                    size: 10,
                    weight: AppText.bold,
                    color: AppColors.gray400,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: look.bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: look.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Pulse(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: look.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        look.badge,
                        style: AppText.style(
                          size: 10,
                          weight: AppText.bold,
                          color: look.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Student identity row
            Tap(
              onTap: onOpenStudentSwitcher,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.style(
                              size: 14,
                              weight: AppText.extrabold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.classLabel,
                            style: AppText.style(
                              size: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canSwitch) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'تبديل',
                          style: AppText.style(
                            size: 10,
                            weight: AppText.bold,
                            color: AppColors.brandPurple,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Arrival / leave times
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: look.bg.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: look.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: look.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(look.icon, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          look.headline,
                          style: AppText.style(
                            size: 11,
                            weight: AppText.bold,
                            color: look.dark,
                          ),
                        ),
                        Text(
                          look.detail,
                          style: AppText.style(size: 9, color: look.color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Today's schedule summary
            Container(
              padding: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.gray100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      todayPeriods > 0
                          ? 'جدول اليوم يشمل $todayPeriods حصص'
                          : 'لا توجد حصص مسجّلة لهذا اليوم',
                      style: AppText.style(size: 11, weight: AppText.medium),
                    ),
                  ),
                  Tap(
                    onTap: onNavigateToSchedule,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض الحصص',
                          style: AppText.style(
                            size: 10,
                            weight: AppText.bold,
                            color: AppColors.brandPurple,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          LucideIcons.chevronLeft,
                          size: 12,
                          color: AppColors.brandPurple,
                        ),
                      ],
                    ),
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

// ---------------------------------------------------------------------------
// Quick-Action Card
// ---------------------------------------------------------------------------
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray100),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.style(size: 11, weight: AppText.bold),
                  ),
                  Text(
                    subtitle,
                    style: AppText.style(size: 9, color: AppColors.textMuted),
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
