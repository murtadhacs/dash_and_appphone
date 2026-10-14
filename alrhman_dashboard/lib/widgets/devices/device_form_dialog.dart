import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../core/app_colors.dart';
import '../../models/device.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_text_field.dart';

/// نافذة إضافة جهاز جديد، أو تعديل موقع جهاز موجود.
///
/// الرقم التسلسلي هو مفتاح الجهاز فلا يمكن تعديله؛ إن أخطأ المدير فيه فليضف جهازاً
/// جديداً ويعطّل القديم.
class DeviceFormDialog extends StatefulWidget {
  /// null = إضافة جهاز.
  final Device? editing;

  /// تنفّذ الطلب؛ إن رمت [ApiException] تبقى النافذة مفتوحة وتعرض الرسالة.
  final Future<void> Function(String serial, String location) onSubmit;

  const DeviceFormDialog({super.key, this.editing, required this.onSubmit});

  static Future<bool> show(
    BuildContext context, {
    Device? editing,
    required Future<void> Function(String serial, String location) onSubmit,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeviceFormDialog(editing: editing, onSubmit: onSubmit),
    );
    return ok ?? false;
  }

  @override
  State<DeviceFormDialog> createState() => _DeviceFormDialogState();
}

class _DeviceFormDialogState extends State<DeviceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _serial = TextEditingController(
    text: widget.editing?.serialNumber ?? '',
  );
  late final _location = TextEditingController(
    text: widget.editing?.locationName ?? '',
  );
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.editing != null;

  @override
  void dispose() {
    _serial.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_serial.text.trim(), _location.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.statusCode == 409
            ? 'يوجد جهاز مسجّل بهذا الرقم التسلسلي مسبقاً'
            : e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      maxWidth: 480,
      icon: Icons.settings_input_component_outlined,
      title: _isEdit ? 'تعديل موقع الجهاز' : 'إضافة جهاز بصمة',
      subtitle: _isEdit
          ? widget.editing!.serialNumber
          : 'يُسجَّل مفعّلاً مباشرة',
      onClose: _saving ? () {} : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.redBorder),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.redDark,
                  ),
                ),
              ),
            if (!_isEdit) ...[
              const FieldLabel('الرقم التسلسلي للجهاز', required: true),
              const SizedBox(height: 6),
              AppTextField(
                controller: _serial,
                height: 44,
                ltr: true,
                mono: true,
                maxLength: 50,
                fontWeight: FontWeight.bold,
                requiredField: true,
              ),
              const SizedBox(height: 6),
              const Text(
                'يظهر الرقم التسلسلي في قائمة معلومات الجهاز نفسه. لا يمكن تغييره بعد الإضافة.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
            ],
            const FieldLabel('الموقع (اسم البوابة)'),
            const SizedBox(height: 6),
            AppTextField(
              controller: _location,
              height: 44,
              maxLength: 50,
              fontWeight: FontWeight.bold,
              hint: 'مثال: المدخل الرئيسي',
            ),
            const SizedBox(height: 16),
            DialogActions(
              children: [
                AppButton(
                  label: 'إلغاء',
                  style: AppButtonStyle.soft,
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
                AppButton(
                  label: _saving
                      ? 'جارٍ الحفظ...'
                      : (_isEdit ? 'حفظ الموقع' : 'إضافة الجهاز'),
                  icon: Icons.save_outlined,
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
