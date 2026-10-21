import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_toast.dart';

/// نافذة «رمز دخول ولي الأمر» (D2): تُعرض مرة واحدة بعد الحفظ
/// لأن الخادم لا يستطيع عرض كلمة المرور لاحقاً.
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

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.pin));
    if (mounted) showAppToast(context, 'تم نسخ كلمة المرور');
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: LucideIcons.keyRound,
      iconBackground: AppColors.okBg,
      iconForeground: AppColors.green,
      title: 'رمز دخول ولي الأمر',
      subtitle: widget.parentName,
      maxWidth: 480,
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'تم الحفظ — سلّم كلمة المرور لولي الأمر',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: TextField(
              controller: _password,
              readOnly: true,
              obscureText: !_show,
              autocorrect: false,
              enableSuggestions: false,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
              ),
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                label: 'نسخ الرمز',
                icon: LucideIcons.copy,
                style: AppButtonStyle.outline,
                small: true,
                onPressed: _copy,
              ),
              const SizedBox(width: 10),
              AppButton(
                label: _show ? 'إخفاء' : 'إظهار',
                tooltip: _show ? 'إخفاء' : 'إظهار',
                icon: _show
                    ? LucideIcons.eyeOff
                    : LucideIcons.eye,
                style: AppButtonStyle.outline,
                small: true,
                onPressed: () => setState(() => _show = !_show),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const DialogNote(
            'يُعرض الرمز بعد نجاح الحفظ فقط، ولا يمكن استرجاعه لاحقاً. سلّمه لولي الأمر الآن، وإن ضاع فعيّن كلمة مرور جديدة من تعديل الطالب.',
            tone: NoteTone.warn,
          ),
          const SizedBox(height: 20),
          DialogActions(
            children: [
              AppButton(
                label: 'إغلاق',
                style: AppButtonStyle.primary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
