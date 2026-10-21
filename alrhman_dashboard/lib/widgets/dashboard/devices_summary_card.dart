import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../../models/device.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';
import '../common/pill.dart';

/// شريط الجهاز أسفل لوحة التحكم كما في Figma: الجهاز الأساسي وآخر مزامنة
/// وعدد الأجهزة المفعّلة وزر إدارة الأجهزة. بلا جهاز مفعّل يظهر تنبيه.
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
    final active = devices.where((d) => d.isActive).toList();
    final main = active.firstOrNull ?? devices.firstOrNull;
    final none = active.isEmpty;

    final title = main == null
        ? 'لا توجد أجهزة مسجّلة بعد'
        : 'جهاز الحضور - ${main.locationName.isEmpty ? main.serialNumber : main.locationName}';
    final subtitle = none
        ? 'لا يوجد أي جهاز بصمة مفعّل، ولن تُسجَّل بصمات الطلاب. فعّل جهازاً أو أضف جهازاً جديداً.'
        : 'مفعّل إدارياً · ${main!.lastSync == null ? 'لم يرسل بيانات بعد' : 'آخر مزامنة ${BaghdadTime.shortDateTime(main.lastSync!)}'}';

    return AppCard(
      hover: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, c) {
          final info = Row(
            children: [
              Icon(
                none ? LucideIcons.triangleAlert : LucideIcons.cpu,
                size: 28,
                color: AppColors.brand,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: none ? AppColors.redDark : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Pill.tone(
                none ? 'لا جهاز مفعّل' : '${active.length} جهاز مفعّل',
                none ? BadgeTone.bad : BadgeTone.ok,
              ),
              const SizedBox(width: 18),
              AppButton(
                label: 'إدارة الأجهزة',
                icon: LucideIcons.cpu,
                style: none ? AppButtonStyle.amber : AppButtonStyle.primary,
                onPressed: onManageDevices,
              ),
            ],
          );
          if (c.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, const SizedBox(height: 14), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}
