import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/accounts_errors.dart';
import '../../api/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../../core/money.dart';
import '../../models/expense.dart';
import '../../models/teacher.dart';
import '../accounts/accounts_widgets.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_dropdown.dart';
import '../common/app_text_field.dart';

/// إضافة مصروف: ما دُفع فعلياً. لا يُعدَّل ولا يُحذف بعد الحفظ.
/// اختيار المعلم يظهر مع فئة الرواتب فقط (`is_salary`)، وهو اختياري؛
/// لغير المعلمين (حارس، مستخدمة) يُترك فارغاً ويُكتب الاسم في الملاحظة.
class ExpenseFormDialog extends StatefulWidget {
  final List<ExpenseCategory> categories;
  final List<Teacher> teachers;
  final String academicYear;
  final Future<void> Function(
    int categoryId,
    int amount,
    DateTime date,
    String note,
    int? teacherId,
  )
  onSubmit;

  const ExpenseFormDialog({
    super.key,
    required this.categories,
    required this.teachers,
    required this.academicYear,
    required this.onSubmit,
  });

  static Future<bool> show(
    BuildContext context, {
    required List<ExpenseCategory> categories,
    required List<Teacher> teachers,
    required String academicYear,
    required Future<void> Function(int, int, DateTime, String, int?) onSubmit,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ExpenseFormDialog(
          categories: categories,
          teachers: teachers,
          academicYear: academicYear,
          onSubmit: onSubmit,
        ),
      ) ??
      false;

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late int _categoryId = widget.categories.first.id;
  int? _teacherId;
  DateTime _date = BaghdadTime.today();
  bool _saving = false;
  String? _error;

  ExpenseCategory get _category =>
      widget.categories.firstWhere((c) => c.id == _categoryId);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        _categoryId,
        Money.parse(_amount.text)!,
        _date,
        _note.text,
        _category.isSalary ? _teacherId : null,
      );
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
    final salary = _category.isSalary;
    final active = widget.teachers
        .where((t) => t.status == TeacherStatus.active)
        .toList();
    final teachers = active.isEmpty ? widget.teachers : active;
    return AppDialog(
      maxWidth: 640,
      icon: LucideIcons.receipt,
      title: 'إضافة مصروف',
      subtitle: 'ما دُفع فعلياً · السنة ${widget.academicYear}',
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('الفئة', required: true),
                      const SizedBox(height: 6),
                      AppDropdown<int>(
                        value: _categoryId,
                        items: [
                          for (final c in widget.categories)
                            DropdownItem(c.id, c.name),
                        ],
                        onChanged: (v) => setState(() {
                          _categoryId = v;
                          if (!_category.isSalary) _teacherId = null;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('المبلغ', required: true),
                      const SizedBox(height: 6),
                      MoneyField(controller: _amount, hint: 'مثال: 750000'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('تاريخ الدفع', hint: 'ليس في المستقبل'),
                      const SizedBox(height: 6),
                      DateField(
                        value: _date,
                        lastDate: BaghdadTime.today(),
                        onChanged: (d) => setState(() => _date = d),
                      ),
                    ],
                  ),
                ),
                if (salary) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FieldLabel('المعلم', hint: 'اختياري'),
                        const SizedBox(height: 6),
                        AppDropdown<int?>(
                          value: _teacherId,
                          items: [
                            const DropdownItem(null, 'بدون معلم'),
                            for (final t in teachers)
                              DropdownItem(t.id, t.fullName),
                          ],
                          onChanged: (v) => setState(() => _teacherId = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (salary) ...[
              const SizedBox(height: 6),
              const Text(
                'لغير المعلمين (حارس، مستخدمة) اترك المعلم فارغاً واكتب اسم الشخص في الملاحظة.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 16),
            const FieldLabel('ملاحظة', hint: 'اختياري · حتى 200 حرف'),
            const SizedBox(height: 6),
            AppTextField(
              controller: _note,
              maxLength: 200,
              hint: salary ? 'مثال: راتب تشرين الأول' : 'مثال: تعبئة مولد',
            ),
            const SizedBox(height: 12),
            const DialogNote(
              'لا يمكن تعديل المصروف بعد حفظه؛ التصحيح بإلغائه وإدخال مصروف جديد.',
            ),
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
                  label: _saving ? 'جارٍ الحفظ...' : 'حفظ المصروف',
                  icon: LucideIcons.check,
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

/// فئة مصروفات جديدة: الاسم فقط، ولا تعديل ولا حذف لاحقاً، ولا تكون فئة رواتب.
class CategoryDialog extends StatefulWidget {
  final List<ExpenseCategory> existing;
  final Future<void> Function(String name) onSubmit;
  const CategoryDialog({
    super.key,
    required this.existing,
    required this.onSubmit,
  });

  static Future<bool> show(
    BuildContext context, {
    required List<ExpenseCategory> existing,
    required Future<void> Function(String name) onSubmit,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CategoryDialog(existing: existing, onSubmit: onSubmit),
      ) ??
      false;

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_name.text.trim());
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
      icon: LucideIcons.plus,
      title: 'فئة مصروفات جديدة',
      subtitle: 'الاسم فقط · لا تعديل ولا حذف لاحقاً',
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
            const FieldLabel('اسم الفئة', required: true, hint: 'حتى 50 حرفاً'),
            const SizedBox(height: 6),
            AppTextField(
              controller: _name,
              maxLength: 50,
              requiredField: true,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            const Text(
              'الفئات الحالية',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in widget.existing)
                  Chip(
                    label: Text(c.isSalary ? '${c.name} · للرواتب' : c.name),
                    labelStyle: const TextStyle(fontSize: 12),
                    backgroundColor: c.isSalary
                        ? AppColors.tint
                        : AppColors.canvas,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const DialogNote(
              '«رواتب» هي الفئة الوحيدة التي تقبل اختيار معلم. الفئات المضافة لا تكون فئة رواتب أبداً.',
            ),
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
                  label: _saving ? 'جارٍ الإضافة...' : 'إضافة الفئة',
                  icon: LucideIcons.plus,
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
