import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../../models/device.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';
import '../common/pill.dart';

/// بطاقة جهاز كما في Figma: الموقع والرقم التسلسلي وحالة التفعيل،
/// ثم «آخر مزامنة»، ثم أزرار تعديل الموقع والتفعيل/التعطيل.
///
/// لا نعرض حالة "متصل/غير متصل": `last_sync` لا يتحدّث إلا عند وصول بصمات.
class DeviceCard extends StatelessWidget {
  final Device device;
  final bool busy;
  final VoidCallback onEditLocation;
  final VoidCallback onToggle;

  const DeviceCard({
    super.key,
    required this.device,
    required this.busy,
    required this.onEditLocation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final active = device.isActive;
    return AppCard(
      hover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.cpu, size: 28, color: AppColors.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.locationName.isEmpty
                          ? 'بدون موقع'
                          : device.locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                        color: device.locationName.isEmpty
                            ? AppColors.textMuted
                            : AppColors.text,
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SelectableText(
                        device.serialNumber,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Pill.tone(
                active ? 'مفعّل' : 'معطّل',
                active ? BadgeTone.ok : BadgeTone.gray,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                const Tooltip(
                  message:
                      'تتحدّث عند وصول بصمات من الجهاز فقط؛ مرور ساعات بلا بصمات لا يعني عطلاً.',
                  child: Text(
                    'آخر مزامنة',
                    style: TextStyle(fontSize: 13, color: AppColors.textSub),
                  ),
                ),
                const Spacer(),
                Text(
                  device.lastSync == null
                      ? 'لا توجد مزامنة بعد'
                      : BaghdadTime.shortDateTime(device.lastSync!),
                  textDirection: device.lastSync == null
                      ? null
                      : TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              AppButton(
                label: 'تعديل الموقع',
                icon: LucideIcons.pencil,
                style: AppButtonStyle.outline,
                small: true,
                onPressed: busy ? null : onEditLocation,
              ),
              const SizedBox(width: 10),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                AppButton(
                  label: active ? 'تعطيل' : 'تفعيل',
                  icon: active ? LucideIcons.pause : LucideIcons.check,
                  style: active
                      ? AppButtonStyle.dangerSoft
                      : AppButtonStyle.amber,
                  small: true,
                  tooltip: active ? 'تعطيل الجهاز' : 'تفعيل الجهاز',
                  onPressed: onToggle,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
