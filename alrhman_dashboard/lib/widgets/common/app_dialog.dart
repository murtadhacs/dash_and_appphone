import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'icon_tile.dart';

/// نافذة منبثقة بترويسة ملونة (أيقونة + عنوان + وصف + زر إغلاق) ومحتوى قابل للتمرير.
class AppDialog extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconForeground;
  final String title;
  final String? subtitle;
  final Widget child;
  final double maxWidth;
  final VoidCallback? onClose;

  const AppDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.iconBackground = AppColors.brand,
    this.iconForeground = Colors.white,
    this.maxWidth = 672,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      shadowColor: const Color(0x290F172A),
      elevation: 24,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 4),
              child: Row(
                children: [
                  IconTile(
                    icon: icon,
                    background: iconBackground,
                    foreground: iconForeground,
                    size: 44,
                    iconSize: 22,
                    radius: AppRadius.control,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.4,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onClose ?? () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// صف أزرار أسفل النافذة (إلغاء + تأكيد).
class DialogActions extends StatelessWidget {
  final List<Widget> children;
  const DialogActions({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      // في RTL يقع الإجراء الأساسي (الأخير في القائمة) أقصى اليمين، ثم الإلغاء.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (var i = children.length - 1; i >= 0; i--) ...[
            children[i],
            if (i > 0) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
