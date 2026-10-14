import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../../models/device.dart';
import '../common/app_card.dart';
import '../common/pill.dart';

/// ملخص أجهزة البصمة (من `GET /api/admin/devices`): الموقع والحالة وآخر مزامنة.
class DevicesSummaryCard extends StatelessWidget {
  final List<Device> devices;
  final VoidCallback onManageDevices;

  const DevicesSummaryCard({
    super.key,
    required this.devices,
    required this.onManageDevices,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أجهزة البصمة',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          if (devices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'لا توجد أجهزة مسجّلة بعد.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          for (final d in devices.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.locationName.isEmpty
                              ? d.serialNumber
                              : d.locationName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSub,
                          ),
                        ),
                        Text(
                          d.lastSync == null
                              ? 'لم يرسل بيانات بعد'
                              : 'آخر مزامنة: ${BaghdadTime.shortDateTime(d.lastSync!)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pill(
                    label: d.isActive ? 'مفعّل' : 'معطّل',
                    background: d.isActive
                        ? AppColors.greenSoft
                        : AppColors.redSoft,
                    foreground: d.isActive
                        ? AppColors.greenDark
                        : AppColors.redDark,
                    borderColor: d.isActive
                        ? AppColors.greenBorder
                        : AppColors.redBorder,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                hoverColor: AppColors.border,
                onTap: onManageDevices,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'إدارة الأجهزة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
