import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/responsive.dart';
import '../common/app_button.dart';
import '../common/pulse_dot.dart';

/// ترويسة شاشة الأجهزة: مسار + عنوان + أزرار (إضافة جهاز، تحديث).
class DevicesHeader extends StatelessWidget {
  final bool refreshing;
  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  const DevicesHeader({
    super.key,
    required this.refreshing,
    required this.onAdd,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final titles = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سجّل أجهزة البصمة وفعّلها أو عطّلها. الجهاز المعطّل لا تُحفظ بصماته.',
          style: TextStyle(fontSize: 14, color: AppColors.textSub),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppButton(label: 'إضافة جهاز', icon: Icons.add, onPressed: onAdd),
        Tooltip(
          message: 'تحديث القائمة',
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.control),
              hoverColor: AppColors.surfaceMuted,
              onTap: refreshing ? null : onRefresh,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: SpinningIcon(
                    icon: Icons.refresh,
                    spinning: refreshing,
                    color: refreshing ? AppColors.primary : AppColors.textSub,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (MediaQuery.sizeOf(context).width >= Breakpoints.md) {
      return Row(
        children: [
          Expanded(child: titles),
          const SizedBox(width: 16),
          actions,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titles, const SizedBox(height: 16), actions],
    );
  }
}
