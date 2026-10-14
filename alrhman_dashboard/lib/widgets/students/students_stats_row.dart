import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/student.dart';
import '../common/app_card.dart';
import '../common/icon_tile.dart';
import '../common/responsive_grid.dart';

/// بطاقات الإحصاء الثلاث أعلى شاشة الطلاب (محسوبة من قائمة الطلاب الفعلية).
class StudentsStatsRow extends StatelessWidget {
  final List<Student> students;
  const StudentsStatsRow({super.key, required this.students});

  @override
  Widget build(BuildContext context) {
    final parents = students
        .map((s) => s.parentPhone)
        .where((p) => p.isNotEmpty)
        .toSet()
        .length;
    final withoutRfid = students.where((s) => !s.hasRealRfid).length;

    return ResponsiveGrid(
      columns: const {0: 1, 768: 3},
      gap: 16,
      children: [
        _StatCard(
          label: 'إجمالي الطلاب',
          value: '${students.length}',
          valueColor: AppColors.primary,
          icon: Icons.groups_outlined,
          iconColor: AppColors.primary,
        ),
        _StatCard(
          label: 'أولياء الأمور',
          value: '$parents',
          icon: Icons.family_restroom_outlined,
          iconColor: AppColors.brand,
        ),
        _StatCard(
          label: 'بدون معرّف بصمة',
          value: '$withoutRfid',
          valueColor: withoutRfid == 0 ? AppColors.text : AppColors.warnDark,
          note: withoutRfid == 0
              ? null
              : 'لن تُسجَّل بصماتهم حتى يُحدَّد المعرّف',
          icon: Icons.sensors,
          iconColor: AppColors.warnDark,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? note;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.valueColor = AppColors.text,
    this.note,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warnDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconTile(
            icon: icon,
            background: AppColors.surfaceMuted,
            foreground: iconColor,
            size: 48,
            iconSize: 24,
          ),
        ],
      ),
    );
  }
}
