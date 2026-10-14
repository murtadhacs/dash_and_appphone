import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../common/app_button.dart';

/// شريط الحفظ أسفل بطاقة الإعدادات (حالة التغييرات + تراجع + حفظ).
class SettingsActionBar extends StatelessWidget {
  final bool isDirty;
  final bool isSaving;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const SettingsActionBar({
    super.key,
    required this.isDirty,
    required this.isSaving,
    required this.onReset,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isDirty ? AppColors.amber : AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDirty ? 'توجد تغييرات غير محفوظة' : 'جميع الإعدادات محدثة',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
          ),
          if (isDirty) ...[
            AppButton(
              label: 'تراجع',
              style: AppButtonStyle.outline,
              onPressed: isSaving ? null : onReset,
            ),
            const SizedBox(width: 8),
          ],
          AppButton(
            label: isSaving ? 'جارٍ الحفظ...' : 'حفظ التغييرات',
            icon: Icons.save_outlined,
            onPressed: (!isDirty || isSaving) ? null : onSave,
          ),
        ],
      ),
    );
  }
}
