import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// شريط تنبيه أعلى لوحة التحكم عند عدم وجود أي جهاز بصمة مفعّل.
class DeviceAlertBanner extends StatelessWidget {
  final VoidCallback onOpenDevices;
  const DeviceAlertBanner({super.key, required this.onOpenDevices});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.redBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.redDark),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'لا يوجد أي جهاز بصمة مفعّل، ولن تُسجَّل بصمات الطلاب. فعّل جهازاً أو أضف جهازاً جديداً.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.redDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onOpenDevices,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.redDark,
              backgroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('إدارة الأجهزة'),
          ),
        ],
      ),
    );
  }
}
