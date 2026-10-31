import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/accounts_errors.dart';
import '../../api/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/iraqi_phone.dart';
import '../../models/teacher.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_dropdown.dart';
import '../common/app_text_field.dart';

/// إضافة معلم أو تعديل سجله. التعديل (PUT) يستبدل السجل كله، فالنافذة تعرض
/// كل الحقول بقيمها الحالية وتُرسلها جميعاً.
class TeacherFormDialog extends StatefulWidget {
  /// null = إضافة.
  final Teacher? editing;
  final List<String> specializations;
  final Future<void> Function(TeacherInput input) onSubmit;

  const TeacherFormDialog({
    super.key,
    this.editing,
    this.specializations = const [],
    required this.onSubmit,
  });

  static Future<bool> show(
    BuildContext context, {
    Teacher? editing,
    List<String> specializations = const [],
    required Future<void> Function(TeacherInput input) onSubmit,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TeacherFormDialog(
          editing: editing,
          specializations: specializations,
          onSubmit: onSubmit,
        ),
      ) ??
      false;

  @override
  State<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<TeacherFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.editing?.firstName);
  late final _father = TextEditingController(text: widget.editing?.fatherName);
  late final _grand = TextEditingController(
    text: widget.editing?.grandfatherName,
  );
  late final _phone = TextEditingController(
    text: widget.editing == null
        ? ''
        : IraqiPhone.display(widget.editing!.phone),
  );
  late final _special = TextEditingController(
    text: widget.editing?.specialization,
  );
  late final _rfid = TextEditingController(text: widget.editing?.rfidTag);
  late final _notes = TextEditingController(text: widget.editing?.notes);
  late String _gender = widget.editing?.gender ?? 'male';
  late TeacherStatus _status = widget.editing?.status ?? TeacherStatus.active;

  bool _saving = false;
  String? _error, _phoneError, _rfidError;

  bool get _isEdit => widget.editing != null;

  @override
  void dispose() {
    for (final c in [
      _first,
      _father,
      _grand,
      _phone,
      _special,
      _rfid,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _suggestions {
    final q = _special.text.trim();
    final all = widget.specializations;
    final list = q.isEmpty
        ? all
        : all.where((s) => s.contains(q) && s != q).toList();
    return list.take(8).toList();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    final phone = IraqiPhone.normalize(_phone.text);
    if (phone == null) {
      setState(
        () => _phoneError = 'رقم هاتف عراقي غير صالح، مثال: 07701234567',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = _phoneError = _rfidError = null;
    });
    try {
      await widget.onSubmit(
        TeacherInput(
          firstName: _first.text,
          fatherName: _father.text,
          grandfatherName: _grand.text,
          phone: phone,
          gender: _gender,
          status: _status,
          specialization: _special.text,
          notes: _notes.text,
          rfidTag: _rfid.text,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      final text = e.accountsMessage;
      final m = (e.serverMessage ?? '').toLowerCase();
      setState(() {
        _saving = false;
        if (m.contains('phone')) {
          _phoneError = text;
        } else if (m.contains('rfid_tag')) {
          _rfidError = text;
        } else {
          _error = text;
        }
      });
    }
  }

  Widget _labeled(Widget label, Widget field, {String? error, String? help}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label,
          const SizedBox(height: 6),
          field,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                error,
                style: const TextStyle(color: AppColors.redDark, fontSize: 12),
              ),
            )
          else if (help != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                help,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      );

  Widget _row(List<Widget> children) => LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth < 520) {
        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              children[i],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: children[i]),
          ],
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    return AppDialog(
      maxWidth: 720,
      icon: LucideIcons.userRound,
      title: _isEdit ? 'تعديل بيانات المعلم' : 'إضافة معلم',
      subtitle: _isEdit
          ? widget.editing!.fullName
          : 'لا يملك المعلم تطبيقاً ولا تسجيل دخول؛ السجل للوحة الإدارة ولمطابقة بصمته',
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
            _row([
              _labeled(
                const FieldLabel('الاسم الأول', required: true),
                AppTextField(
                  controller: _first,
                  maxLength: 100,
                  requiredField: true,
                  hint: 'أحمد',
                ),
              ),
              _labeled(
                const FieldLabel('اسم الأب', required: true),
                AppTextField(
                  controller: _father,
                  maxLength: 100,
                  requiredField: true,
                  hint: 'علي',
                ),
              ),
              _labeled(
                const FieldLabel('اسم الجد', required: true),
                AppTextField(
                  controller: _grand,
                  maxLength: 100,
                  requiredField: true,
                  hint: 'حسن',
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _row([
              _labeled(
                const FieldLabel('رقم الهاتف', required: true),
                AppTextField(
                  controller: _phone,
                  ltr: true,
                  keyboardType: TextInputType.phone,
                  hint: '07XXXXXXXXX',
                  maxLength: 20,
                  requiredField: true,
                  onChanged: (_) => setState(() => _phoneError = null),
                ),
                error: _phoneError,
                help:
                    'بأي صيغة عراقية؛ يُحفظ +9647XXXXXXXXX. قد يطابق رقم ولي أمر.',
              ),
              _labeled(
                const FieldLabel('الجنس', required: true),
                AppDropdown<String>(
                  value: _gender,
                  items: const [
                    DropdownItem('male', 'ذكر'),
                    DropdownItem('female', 'أنثى'),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
              ),
              _labeled(
                const FieldLabel('الحالة'),
                AppDropdown<TeacherStatus>(
                  value: _status,
                  items: [
                    for (final s in TeacherStatus.values)
                      DropdownItem(s, s.label),
                  ],
                  onChanged: (v) => setState(() => _status = v),
                ),
                help: 'وصفية فقط؛ لا توقف حفظ البصمات.',
              ),
            ]),
            const SizedBox(height: 16),
            _row([
              _labeled(
                const FieldLabel('التخصص', hint: 'اختياري'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _special,
                      maxLength: 100,
                      hint: 'مثال: الرياضيات',
                      onChanged: (_) => setState(() {}),
                    ),
                    if (suggestions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final s in suggestions)
                              ActionChip(
                                label: Text(s),
                                labelStyle: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.brand,
                                ),
                                backgroundColor: AppColors.tint,
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    setState(() => _special.text = s),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                help: 'اختر اسماً مطابقاً لمادة الجدول الأسبوعي إن وُجد.',
              ),
              _labeled(
                const FieldLabel('رقم البصمة', hint: 'من 1 إلى 99'),
                AppTextField(
                  controller: _rfid,
                  ltr: true,
                  mono: true,
                  maxLength: 2,
                  keyboardType: TextInputType.number,
                  hint: 'مثال: 12',
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return null;
                    return RegExp(r'^[1-9][0-9]?$').hasMatch(value)
                        ? null
                        : 'من 1 إلى 99 ودون صفر في البداية';
                  },
                  onChanged: (_) => setState(() => _rfidError = null),
                ),
                error: _rfidError,
                help:
                    'رقم المعلم في جهاز البصمة. أرقام الطلاب من 100 فأكثر. '
                    'إن تُرك فارغاً تُهمل بصماته.',
              ),
            ]),
            const SizedBox(height: 16),
            _labeled(
              const FieldLabel('ملاحظات', hint: 'اختياري · حتى 500 حرف'),
              AppTextField(controller: _notes, maxLength: 500, maxLines: 3),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 12),
              const DialogNote(
                'التعديل يستبدل السجل كله: ترك رقم البصمة أو التخصص فارغاً يمسحه. '
                'لا يوجد حذف للمعلم؛ غيّر الحالة بدلاً منه.',
                tone: NoteTone.warn,
              ),
            ],
            const SizedBox(height: 16),
            DialogActions(
              children: [
                AppButton(
                  label: 'إلغاء',
                  style: AppButtonStyle.outline,
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
                AppButton(
                  label: _saving
                      ? 'جارٍ الحفظ...'
                      : (_isEdit ? 'حفظ التعديلات' : 'إضافة المعلم'),
                  icon: _isEdit ? LucideIcons.save : LucideIcons.plus,
                  style: AppButtonStyle.amber,
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
