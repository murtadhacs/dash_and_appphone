import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/accounts_errors.dart';
import '../../api/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../../core/money.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_text_field.dart';
import '../common/pill.dart';

/// مبلغ بالدينار: أرقام لاتينية LTR، ومع [strike] يُشطب (دفعة أو مصروف ملغى).
class MoneyText extends StatelessWidget {
  final int? value;
  final bool strike;
  final Color color;
  final double size;
  final FontWeight weight;

  const MoneyText(
    this.value, {
    super.key,
    this.strike = false,
    this.color = AppColors.text,
    this.size = 14,
    this.weight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Text(
        '—',
        style: TextStyle(fontSize: size, color: AppColors.textMuted),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: Money.format(value!),
            style: TextStyle(
              decoration: strike ? TextDecoration.lineThrough : null,
            ),
          ),
          TextSpan(
            text: ' د.ع',
            style: TextStyle(
              fontSize: size - 2,
              fontWeight: FontWeight.w500,
              color: strike ? AppColors.textMuted : AppColors.textSub,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: strike ? AppColors.textMuted : color,
      ),
    );
  }
}

/// لا يُعرض القسط غير المحدد صفراً أبداً.
class NotSetBadge extends StatelessWidget {
  const NotSetBadge({super.key});

  @override
  Widget build(BuildContext context) =>
      Pill.tone('لم يحدد القسط', BadgeTone.warn);
}

/// حقل مبلغ: أرقام فقط (تُقبل العربية وتُحوَّل)، ويُقرأ عدداً صحيحاً بالدينار.
class MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final bool allowZero;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const MoneyField({
    super.key,
    required this.controller,
    this.allowZero = false,
    this.hint = 'مثال: 500000',
    this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      ltr: true,
      keyboardType: TextInputType.number,
      hint: hint,
      onChanged: onChanged,
      maxLength: 16,
      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹,٬]'))],
      suffix: const Padding(
        padding: EdgeInsetsDirectional.only(end: 14, start: 8),
        child: Text(
          'د.ع',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
      validator: (v) {
        final n = allowZero
            ? Money.parseAllowZero(v ?? '')
            : Money.parse(v ?? '');
        if (n != null) return null;
        return allowZero
            ? 'عدد صحيح بالدينار من 0 إلى 1,000,000,000'
            : 'عدد صحيح بالدينار من 1 إلى 1,000,000,000';
      },
    );
  }
}

/// حقل تاريخ يفتح منتقي التاريخ؛ لا يُكتب يدوياً.
class DateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? lastDate;

  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.control),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: lastDate ?? DateTime(2100, 12, 31),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: appInputDecoration(
          suffix: const Padding(
            padding: EdgeInsetsDirectional.only(end: 14, start: 8),
            child: Icon(
              LucideIcons.calendar,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ),
        child: Text(
          BaghdadTime.apiDate(value),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
          style: const TextStyle(fontSize: 14, color: AppColors.text),
        ),
      ),
    );
  }
}

/// نافذة إلغاء (دفعة أو مصروف): السبب إلزامي حتى 200 حرفاً، والسجل يبقى.
class VoidDialog extends StatefulWidget {
  final String title, subtitle, confirmLabel;
  final Widget summary;
  final String? warning;
  final Future<void> Function(String reason) onSubmit;

  const VoidDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.onSubmit,
    this.confirmLabel = 'تأكيد الإلغاء',
    this.warning,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget summary,
    required Future<void> Function(String reason) onSubmit,
    String? warning,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => VoidDialog(
          title: title,
          subtitle: subtitle,
          summary: summary,
          warning: warning,
          onSubmit: onSubmit,
        ),
      ) ??
      false;

  @override
  State<VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<VoidDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_reason.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.accountsMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      maxWidth: 540,
      icon: LucideIcons.ban,
      title: widget.title,
      subtitle: widget.subtitle,
      onClose: _saving ? () {} : null,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DialogNote(_error!, tone: NoteTone.bad),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: widget.summary,
            ),
            const SizedBox(height: 16),
            const FieldLabel(
              'سبب الإلغاء',
              required: true,
              hint: 'حتى 200 حرف',
            ),
            const SizedBox(height: 6),
            AppTextField(
              controller: _reason,
              maxLength: 200,
              maxLines: 3,
              hint: 'مثال: صفر زائد في المبلغ',
              requiredField: true,
            ),
            const SizedBox(height: 4),
            if (widget.warning != null)
              DialogNote(widget.warning!, tone: NoteTone.warn),
            const SizedBox(height: 16),
            DialogActions(
              children: [
                AppButton(
                  label: 'تراجع',
                  style: AppButtonStyle.outline,
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
                AppButton(
                  label: _saving ? 'جارٍ الإلغاء...' : widget.confirmLabel,
                  icon: LucideIcons.ban,
                  style: AppButtonStyle.danger,
                  onPressed: _saving ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة رقم صغيرة (القسط، الخصم...) بعنوان وقيمة.
class FigureCard extends StatelessWidget {
  final String label;
  final Widget value;
  const FigureCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }
}

/// مربع تأكيد بنص: بديل عن CheckboxListTile الذي يعطي خطأ عند وضعه فوق بطاقة بخلفية.
class ConfirmCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  const ConfirmCheck({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (v) => onChanged!(v ?? false),
              visualDensity: VisualDensity.compact,
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.textSub,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
