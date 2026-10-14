import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';

class QuickActionsCard extends StatelessWidget {
  final VoidCallback onAddStudent, onGrantLeave, onAddSchedule, onAddBanner;
  final VoidCallback? onExport;
  const QuickActionsCard({
    super.key,
    required this.onAddStudent,
    required this.onGrantLeave,
    required this.onExport,
    required this.onAddSchedule,
    required this.onAddBanner,
  });
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'أهم مهام الإدارة في مكان واحد',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (_, constraints) {
            final columns = constraints.maxWidth >= 1050
                ? 5
                : constraints.maxWidth >= 640
                ? 3
                : constraints.maxWidth >= 380
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final action in [
                  ('تسجيل طالب', Icons.person_add_alt, onAddStudent),
                  ('تسجيل إجازة', Icons.event_available_outlined, onGrantLeave),
                  (
                    'إضافة جدول سريع',
                    Icons.calendar_month_outlined,
                    onAddSchedule,
                  ),
                  (
                    'إضافة بنر',
                    Icons.add_photo_alternate_outlined,
                    onAddBanner,
                  ),
                  ('تصدير كشف اليوم', Icons.download_outlined, onExport),
                ])
                  SizedBox(
                    width: width,
                    child: AppButton(
                      label: action.$1,
                      icon: action.$2,
                      onPressed: action.$3,
                      height: 48,
                      expand: true,
                      style: AppButtonStyle.outline,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
