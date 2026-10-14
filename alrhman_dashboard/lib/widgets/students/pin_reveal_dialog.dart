import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../common/app_button.dart';
import '../common/app_toast.dart';
import '../common/icon_tile.dart';

/// يعرض رمز ولي الأمر مرة واحدة بعد الحفظ (الخادم لا يستطيع عرضه لاحقاً).
class PinRevealDialog extends StatefulWidget {
  final String parentName;
  final String pin;

  const PinRevealDialog({
    super.key,
    required this.parentName,
    required this.pin,
  });

  static Future<void> show(
    BuildContext context, {
    required String parentName,
    required String pin,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinRevealDialog(parentName: parentName, pin: pin),
    );
  }

  @override
  State<PinRevealDialog> createState() => _PinRevealDialogState();
}

class _PinRevealDialogState extends State<PinRevealDialog> {
  bool _show = false;
  late final _password = TextEditingController(text: widget.pin);
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconTile(
                icon: Icons.vpn_key_outlined,
                background: AppColors.warnSoft,
                foreground: AppColors.warnDeep,
                size: 56,
                iconSize: 28,
                circle: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'تم الحفظ — سلّم كلمة المرور لولي الأمر',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'كلمة مرور ${widget.parentName} إلى التطبيق:',
                style: const TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _password,
                  readOnly: true,
                  obscureText: !_show,
                  autocorrect: false,
                  enableSuggestions: false,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      tooltip: _show ? 'إخفاء' : 'إظهار',
                      onPressed: () => setState(() => _show = !_show),
                      icon: Icon(
                        _show
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'لن تتوفر كلمة المرور مرة أخرى بعد إغلاق النافذة. إن ضاعت فعيّن كلمة مرور جديدة من تعديل الطالب.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'نسخ كلمة المرور',
                      icon: Icons.copy_outlined,
                      style: AppButtonStyle.soft,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: widget.pin),
                        );
                        if (context.mounted) {
                          showAppToast(context, 'تم نسخ كلمة المرور');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'تم',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
