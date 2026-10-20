import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/dashboard_stats.dart';
import '../common/app_card.dart';
import '../common/icon_tile.dart';
import '../common/responsive_grid.dart';

/// شبكة المؤشرات الخمسة في أعلى لوحة التحكم (من `GET /api/admin/dashboard`).
class KpiRow extends StatelessWidget {
  final DashboardStats stats;
  const KpiRow({super.key, required this.stats});

  String _pct(int v) => '${stats.percentOf(v).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      columns: const {0: 1, 640: 2, 1280: 5},
      children: [
        _KpiCard(
          label: 'إجمالي الطلاب',
          value: '${stats.totalStudents}',
          unit: 'طالب',
          icon: Icons.groups_outlined,
          iconBackground: AppColors.accentSoft,
          iconForeground: AppColors.brand,
        ),
        _KpiCard(
          label: 'إجمالي أولياء الأمور',
          value: '${stats.totalParents}',
          unit: 'ولي أمر',
          icon: Icons.family_restroom_outlined,
          iconBackground: AppColors.accentSoft,
          iconForeground: AppColors.primary,
        ),
        _KpiCard(
          label: 'الحاضرون اليوم',
          value: '${stats.presentToday}',
          unit: 'طالب',
          valueColor: AppColors.green,
          icon: Icons.how_to_reg_outlined,
          iconBackground: AppColors.greenSoft,
          iconForeground: AppColors.greenDark,
          footer: _pct(stats.presentToday),
          footerColor: AppColors.greenDark,
        ),
        _KpiCard(
          label: 'الغائبون اليوم',
          value: '${stats.absentToday}',
          unit: 'طالب',
          valueColor: AppColors.red,
          icon: Icons.person_off_outlined,
          iconBackground: AppColors.redSoft,
          iconForeground: AppColors.redDark,
          footer: _pct(stats.absentToday),
          footerColor: AppColors.redDark,
        ),
        _KpiCard(
          label: 'المجازون',
          value: '${stats.excusedToday}',
          unit: 'طالب',
          valueColor: AppColors.warnDark,
          icon: Icons.schedule,
          iconBackground: AppColors.warnSoft,
          iconForeground: AppColors.warnDeep,
          footer: _pct(stats.excusedToday),
          footerColor: AppColors.warnDark,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final IconData icon;
  final Color iconBackground;
  final Color iconForeground;
  final String? footer;
  final Color footerColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconBackground,
    required this.iconForeground,
    this.valueColor = AppColors.text,
    this.footer,
    this.footerColor = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          IconTile(
            icon: icon,
            background: iconBackground,
            foreground: iconForeground,
            size: 48,
            iconSize: 24,
            radius: 16,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.3,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          footer!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: footerColor,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 6),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 12,
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
    );
  }
}
