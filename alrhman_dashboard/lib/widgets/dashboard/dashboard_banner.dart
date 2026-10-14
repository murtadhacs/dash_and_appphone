import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../common/app_card.dart';
import '../common/icon_tile.dart';
import '../common/pill.dart';

class DashboardBanner extends StatelessWidget {
  final String dayLabel;
  const DashboardBanner({super.key, required this.dayLabel});
  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        const IconTile(
          icon: Icons.space_dashboard_outlined,
          background: AppColors.accentSoft,
          foreground: AppColors.brand,
          size: 48,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نظرة عامة',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ملخص اليوم والوصول السريع إلى إدارة المدرسة • ${BaghdadTime.apiDate(BaghdadTime.today())}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
              const SizedBox(height: 10),
              Pill(
                label: dayLabel,
                background: AppColors.accentSoft,
                foreground: AppColors.brand,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
