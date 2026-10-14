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
          footer: '${_pct(stats.presentToday)} من الإجمالي',
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
          footer: '${_pct(stats.absentToday)} من الإجمالي',
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
          footer: '${_pct(stats.excusedToday)} من الإجمالي',
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSub,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: valueColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconTile(
                icon: icon,
                background: iconBackground,
                foreground: iconForeground,
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.surfaceMuted)),
              ),
              child: Text(
                footer!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: footerColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
