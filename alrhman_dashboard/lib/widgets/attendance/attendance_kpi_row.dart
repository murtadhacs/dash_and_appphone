import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/attendance_entry.dart';
import '../common/app_card.dart';
import '../common/icon_tile.dart';
import '../common/pulse_dot.dart';
import '../common/responsive_grid.dart';

/// بطاقات المؤشرات الأربعة أعلى شاشة الحضور (محسوبة من بيانات اليوم).
class AttendanceKpiRow extends StatelessWidget {
  final AttendanceDay day;
  final bool live;
  final String lastUpdated;
  final bool hideAbsence;

  const AttendanceKpiRow({
    super.key,
    required this.day,
    required this.live,
    required this.lastUpdated,
    this.hideAbsence = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = day.entries.length;
    String pct(int n) =>
        total == 0 ? '0%' : '${(n * 100 / total).toStringAsFixed(1)}%';
    final present = day.count(PresenceStatus.present);
    final absent = day.count(PresenceStatus.absent);
    final excused = day.count(PresenceStatus.excused);

    return ResponsiveGrid(
      columns: const {0: 1, 640: 2, 1280: 4},
      children: [
        _Kpi(
          icon: Icons.how_to_reg_outlined,
          iconBg: AppColors.greenSoft,
          iconFg: AppColors.greenDark,
          label: 'الطلاب الحاضرون',
          value: '$present',
          sub: pct(present),
          subColor: AppColors.greenDark,
          trailing: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: total == 0 ? 0 : present / total,
              strokeWidth: 3.5,
              strokeCap: StrokeCap.round,
              color: AppColors.green,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
        ),
        if (!hideAbsence)
          _Kpi(
            icon: Icons.person_off_outlined,
            iconBg: AppColors.redSoft,
            iconFg: AppColors.redDark,
            label: 'الغائبون',
            value: '$absent',
            sub: pct(absent),
            subColor: AppColors.redDark,
          ),
        _Kpi(
          icon: Icons.schedule,
          iconBg: AppColors.warnSoft,
          iconFg: AppColors.warnDeep,
          label: 'المجازون',
          value: '$excused',
          sub: pct(excused),
          subColor: AppColors.warnDeep,
        ),
        _Kpi(
          icon: Icons.sync,
          iconBg: AppColors.accentSoft,
          iconFg: AppColors.brand,
          label: live ? 'تحديث تلقائي' : 'عرض يوم سابق',
          value: lastUpdated,
          valueSize: 16,
          sub: live ? 'كل 20 ثانية' : '',
          subColor: AppColors.textMuted,
          trailing: live
              ? const PulseDot(color: AppColors.green, size: 10, ping: true)
              : null,
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final String value;
  final double valueSize;
  final String sub;
  final Color subColor;
  final Widget? trailing;

  const _Kpi({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    required this.value,
    this.valueSize = 24,
    required this.sub,
    required this.subColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconTile(
            icon: icon,
            background: iconBg,
            foreground: iconFg,
            size: 48,
            iconSize: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: valueSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
