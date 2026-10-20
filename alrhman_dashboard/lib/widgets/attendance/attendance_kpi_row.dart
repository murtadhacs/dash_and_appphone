import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/attendance_entry.dart';
import '../ui/kpi_tile.dart';

/// مؤشرات شاشة الحضور كما في Figma: الكل، الحاضرون، الغائبون، المجازون.
/// قبل 09:31 وفي العطل يُخفى مؤشر الغياب.
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

    return KpiGrid(
      children: [
        KpiTile(
          label: 'الكل',
          value: '$total',
          icon: Icons.groups_outlined,
          iconBackground: AppColors.tint,
          iconForeground: AppColors.brand,
        ),
        KpiTile(
          label: 'الحاضرون',
          value: '$present',
          icon: Icons.check_rounded,
          iconBackground: AppColors.okBg,
          iconForeground: AppColors.green,
          extra: pct(present),
          extraColor: AppColors.green,
        ),
        if (!hideAbsence)
          KpiTile(
            label: 'الغائبون',
            value: '$absent',
            icon: Icons.person_off_outlined,
            iconBackground: AppColors.badBg,
            iconForeground: AppColors.red,
            extra: pct(absent),
            extraColor: AppColors.red,
          ),
        KpiTile(
          label: 'المجازون',
          value: '$excused',
          icon: Icons.event_busy_outlined,
          iconBackground: AppColors.warnBg,
          iconForeground: AppColors.warnText,
          extra: pct(excused),
          extraColor: AppColors.warnText,
        ),
      ],
    );
  }
}
