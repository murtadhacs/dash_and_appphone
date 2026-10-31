import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'common.dart';

/// بطاقة إعداد موحّدة (أيقونة ملوّنة + عنوان + وصف + عنصر جانبي)،
/// بنفس شكل بطاقة «تواصل مع إدارة المدرسة».
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    this.iconColor = AppColors.brandPurple,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;

  /// العنصر في نهاية البطاقة؛ سهم افتراضياً عند وجود [onTap].
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final side =
        trailing ??
        (onTap == null
            ? null
            : const Icon(
                LucideIcons.chevronLeft,
                size: 18,
                color: AppColors.textMuted,
              ));
    return Tap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.style(
                      size: 12,
                      weight: AppText.bold,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppText.style(
                        size: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (side != null) ...[const SizedBox(width: 8), side],
          ],
        ),
      ),
    );
  }
}

/// مفتاح تشغيل/إيقاف صغير بألوان التطبيق.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: 0.8,
    child: Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.brandPurple,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: AppColors.gray200,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}

/// عنوان مجموعة صغير فوق بطاقات الإعدادات.
class SettingsGroupLabel extends StatelessWidget {
  const SettingsGroupLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
    child: Text(
      text,
      style: AppText.style(
        size: 10,
        weight: AppText.bold,
        color: AppColors.textMuted,
      ),
    ),
  );
}
