import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../../models/device.dart';
import '../common/app_card.dart';
import '../common/icon_tile.dart';
import '../common/pill.dart';

/// بطاقة جهاز بصمة: الرقم التسلسلي، الموقع، الحالة (مفعّل/معطّل)، آخر مزامنة.
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
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 8, color: active ? AppColors.green : AppColors.red),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconTile(
                        icon: Icons.fingerprint,
                        background: AppColors.surfaceMuted,
                        foreground: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              device.serialNumber,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              device.locationName.isEmpty
                                  ? 'بدون موقع'
                                  : device.locationName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: device.locationName.isEmpty
                                    ? AppColors.textMuted
                                    : AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Pill(
                        label: active ? 'مفعّل' : 'معطّل',
                        background: active
                            ? AppColors.greenSoft
                            : AppColors.redSoft,
                        foreground: active
                            ? AppColors.greenDark
                            : AppColors.redDark,
                        borderColor: active
                            ? AppColors.greenBorder
                            : AppColors.redBorder,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'آخر مزامنة',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          device.lastSync == null
                              ? 'لم يرسل بيانات بعد'
                              : BaghdadTime.shortDateTime(device.lastSync!),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'تتحدّث عند وصول بصمات من الجهاز فقط؛ مرور ساعات بلا بصمات لا يعني عطلاً.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    hoverColor: AppColors.accentSoft,
                    onTap: busy ? null : onEditLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'تعديل الموقع',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSub,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: active ? 'تعطيل الجهاز' : 'تفعيل الجهاز',
                    onPressed: onToggle,
                    style: IconButton.styleFrom(
                      foregroundColor: active
                          ? AppColors.greenDark
                          : AppColors.redDark,
                      hoverColor: active
                          ? AppColors.redSoft
                          : AppColors.greenSoft,
                      minimumSize: const Size(32, 32),
                    ),
                    icon: const Icon(Icons.power_settings_new, size: 16),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
