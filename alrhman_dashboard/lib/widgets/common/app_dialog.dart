import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import 'app_button.dart';
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
    this.iconBackground = AppColors.tint,
    this.iconForeground = AppColors.brand,
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
                        LucideIcons.x,
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
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [for (var i = children.length - 1; i >= 0; i--) children[i]],
      ),
    );
  }
}

/// صندوق ملاحظة داخل النوافذ (معلومة، تحذير، نجاح) كما في Figma.
enum NoteTone { info, warn, ok, bad }

class DialogNote extends StatelessWidget {
  final String text;
  final NoteTone tone;
  final IconData? icon;

  const DialogNote(this.text, {super.key, this.tone = NoteTone.info, this.icon});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, defaultIcon) = switch (tone) {
      NoteTone.info => (AppColors.tint, AppColors.brand, LucideIcons.info),
      NoteTone.warn => (
        AppColors.warnBg,
        const Color(0xFFB26B00),
        LucideIcons.triangleAlert,
      ),
      NoteTone.ok => (AppColors.okBg, const Color(0xFF0B8F63), LucideIcons.check),
      NoteTone.bad => (AppColors.badBg, AppColors.redDark, LucideIcons.circleAlert),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon ?? defaultIcon, size: 18, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.7, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// نافذة تأكيد بأسلوب Figma. ترجع true عند التأكيد.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'تراجع',
  bool danger = false,
  IconData icon = LucideIcons.circleQuestionMark,
  Widget? extra,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AppDialog(
      icon: icon,
      title: title,
      maxWidth: 520,
      iconBackground: danger ? AppColors.badBg : AppColors.tint,
      iconForeground: danger ? AppColors.red : AppColors.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.8,
              color: AppColors.textSub,
            ),
          ),
          if (extra != null) ...[const SizedBox(height: 14), extra],
          const SizedBox(height: 20),
          DialogActions(
            children: [
              AppButton(
                label: cancelLabel,
                style: AppButtonStyle.outline,
                onPressed: () => Navigator.pop(ctx, false),
              ),
              AppButton(
                label: confirmLabel,
                style: danger ? AppButtonStyle.danger : AppButtonStyle.amber,
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}
