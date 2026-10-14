import 'package:flutter/material.dart';
import '../../api/api_exception.dart';
import '../../core/attendance_policy.dart';
import '../../core/baghdad_time.dart';
import '../../models/student.dart';
import '../common/app_dialog.dart';
import '../common/app_button.dart';
import '../common/app_text_field.dart';
import '../../core/app_colors.dart';

class LeaveDialog extends StatefulWidget {
  final List<Student> students;
  final int? prefillStudentId;
  final DateTime initialDate;
  final Future<void> Function(int studentId, DateTime date, String notes)
  onSubmit;
  const LeaveDialog({
    super.key,
    required this.students,
    required this.initialDate,
    required this.onSubmit,
    this.prefillStudentId,
  });
  static Future<bool> show(
    BuildContext context, {
    required List<Student> students,
    required DateTime initialDate,
    int? prefillStudentId,
    required Future<void> Function(int studentId, DateTime date, String notes)
    onSubmit,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => LeaveDialog(
          students: students,
          initialDate: initialDate,
          prefillStudentId: prefillStudentId,
          onSubmit: onSubmit,
        ),
      ) ??
      false;
  @override
  State<LeaveDialog> createState() => _LeaveDialogState();
}

class _LeaveDialogState extends State<LeaveDialog> {
  final _form = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _reason = TextEditingController();
  late final _start = TextEditingController(
    text: BaghdadTime.apiDate(widget.initialDate),
  );
  late final _end = TextEditingController(
    text: BaghdadTime.apiDate(widget.initialDate),
  );
  Student? _student;
  bool _saving = false;
  bool _complete = false;
  bool _savedAny = false;
  String? _error;
  final _savedDates = <String>{};
  bool get _locked => _saving || _savedDates.isNotEmpty || _complete;
  @override
  void initState() {
    super.initState();
    _student = widget.students
        .where((s) => s.id == widget.prefillStudentId)
        .firstOrNull;
    _search.text = _student?.name ?? '';
  }

  @override
  void dispose() {
    _search.dispose();
    _reason.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  DateTime? _parse(String text) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text.trim())) return null;
    try {
      final date = BaghdadTime.parseApiDate(text.trim());
      return date.year < 2020 || date.year > 2100 ? null : date;
    } catch (_) {
      return null;
    }
  }

  List<DateTime> get _days {
    final start = _parse(_start.text), end = _parse(_end.text);
    if (start == null || end == null || end.isBefore(start)) return [];
    return leaveSchoolDays(start, end);
  }

  Future<void> _pick(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parse(controller.text) ?? widget.initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) {
      setState(() => controller.text = BaghdadTime.apiDate(picked));
    }
  }

  Future<void> _submit() async {
    if (_saving || _complete || !_form.currentState!.validate()) return;
    if (_student == null) {
      setState(() => _error = 'اختر الطالب من القائمة');
      return;
    }
    final days = _days;
    if (days.isEmpty) {
      setState(
        () => _error =
            'الفترة المختارة لا تحتوي يوماً دراسياً، اختر أياماً من الأحد إلى الخميس',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    FocusScope.of(context).unfocus();
    try {
      for (final date in days) {
        final key = BaghdadTime.apiDate(date);
        if (_savedDates.contains(key)) continue;
        await widget.onSubmit(_student!.id, date, _reason.text.trim());
        _savedDates.add(key);
        _savedAny = true;
        if (!mounted) return;
        setState(() {});
      }
      if (mounted) setState(() => _complete = true);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? (e.statusCode == 404
                ? 'الطالب غير موجود أو معطّل، حدّث قائمة الطلاب وحاول مجدداً'
                : e.statusCode == 400
                ? 'تعذر تسجيل الإجازة، راجع الطالب والتواريخ والملاحظات'
                : e.message)
          : 'تعذر تسجيل الإجازة، حاول مرة أخرى';
      setState(
        () => _error =
            '$message\nتم حفظ ${_savedDates.length} من ${days.length} أيام. أعد المحاولة لإكمال الأيام المتبقية فقط.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _dateField(
    String label,
    TextEditingController controller, {
    bool end = false,
  }) => TextFormField(
    controller: controller,
    readOnly: _locked,
    textDirection: TextDirection.ltr,
    decoration: appInputDecoration(hint: 'yyyy-MM-dd').copyWith(
      labelText: label,
      suffixIcon: IconButton(
        onPressed: _locked ? null : () => _pick(controller),
        icon: const Icon(Icons.calendar_month),
      ),
    ),
    onChanged: (_) => setState(() {}),
    validator: (v) {
      final d = _parse(v ?? '');
      if (d == null ||
          d.isBefore(DateTime(2020)) ||
          d.isAfter(DateTime(2100, 12, 31))) {
        return 'اكتب تاريخاً صحيحاً بصيغة yyyy-MM-dd';
      }
      if (end &&
          _parse(_start.text) != null &&
          d.isBefore(_parse(_start.text)!)) {
        return 'النهاية يجب أن تكون بعد البداية أو في اليوم نفسه';
      }
      return null;
    },
  );
  Widget _notice(
    String text,
    IconData icon,
    Color background,
    Color foreground,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: foreground, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: foreground, fontSize: 12, height: 1.7),
          ),
        ),
      ],
    ),
  );

  void _close() {
    if (!_saving) Navigator.pop(context, _savedAny);
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final choices = widget.students
        .where(
          (s) =>
              query.isEmpty ||
              '${s.name} ${s.gradeSection} ${s.rfidTag}'.toLowerCase().contains(
                query,
              ),
        )
        .take(30);
    return PopScope(
      canPop: !_saving,
      child: AppDialog(
        maxWidth: 640,
        icon: Icons.event_available,
        title: 'تسجيل إجازة',
        subtitle: 'اختر الطالب وحدّد الفترة وأضف ملاحظات الإجازة',
        onClose: _close,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _notice(
                'سجّل الإجازات قبل 12:00 بتوقيت بغداد',
                Icons.schedule,
                AppColors.warnSoft,
                AppColors.warnDeep,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.redDark),
                  ),
                ),
              if (_complete)
                Text(
                  'تم تسجيل الإجازة بنجاح لـ ${_savedDates.length} أيام دراسية.',
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              AbsorbPointer(
                absorbing: _saving || _savedDates.isNotEmpty || _complete,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _search,
                      readOnly: _locked,
                      decoration: appInputDecoration(
                        hint: 'ابحث بالاسم أو الصف أو رقم البصمة',
                        prefix: const Icon(Icons.search),
                      ).copyWith(labelText: 'الطالب'),
                      onChanged: (_) => setState(() {
                        _student = null;
                        _error = null;
                      }),
                    ),
                    if (_student == null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final s in choices)
                              ListTile(
                                dense: true,
                                title: Text(s.name),
                                subtitle: Text(
                                  '${s.gradeSection} • معرّف البصمة: ${s.rfidTag}',
                                ),
                                onTap: () => setState(() {
                                  _student = s;
                                  _search.text = s.name;
                                }),
                              ),
                            if (choices.isEmpty)
                              const ListTile(
                                title: Text(
                                  'لا يوجد طالب مطابق في القائمة الفعّالة',
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (_student != null) ...[
                      const SizedBox(height: 12),
                      _notice(
                        '${_student!.gradeSection} • معرّف البصمة: ${_student!.rfidTag}',
                        Icons.person_outline,
                        AppColors.accentSoft,
                        AppColors.primary,
                      ),
                    ],
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (_, constraints) {
                        final start = _dateField('بداية الإجازة', _start);
                        final end = _dateField(
                          'نهاية الإجازة',
                          _end,
                          end: true,
                        );
                        return constraints.maxWidth < 440
                            ? Column(
                                children: [
                                  start,
                                  const SizedBox(height: 16),
                                  end,
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: start),
                                  const SizedBox(width: 16),
                                  Expanded(child: end),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 12),
                    _notice(
                      'عدد أيام الإجازة الدراسية: ${_days.length} • الجمعة والسبت مستثنيان',
                      Icons.date_range_outlined,
                      AppColors.surfaceMuted,
                      AppColors.textSub,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reason,
                      readOnly: _locked,
                      maxLines: 3,
                      decoration:
                          appInputDecoration(
                            hint: 'اكتب سبب الإجازة أو الملاحظات اللازمة',
                          ).copyWith(
                            labelText: 'تفاصيل وملاحظات الإجازة',
                            alignLabelWithHint: true,
                          ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'اكتب تفاصيل العذر'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_saving)
                Text(
                  'جارٍ الحفظ: ${_savedDates.length} من ${_days.length} أيام',
                ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  AppButton(
                    onPressed: _saving ? null : _close,
                    style: AppButtonStyle.soft,
                    label: _savedAny ? 'إغلاق' : 'إلغاء',
                  ),
                  if (_complete)
                    AppButton(
                      style: AppButtonStyle.outline,
                      onPressed: () {
                        final next = nextSchoolDay(_parse(_end.text)!);
                        setState(() {
                          _start.text = BaghdadTime.apiDate(next);
                          _end.text = _start.text;
                          _complete = false;
                          _savedDates.clear();
                          _error = null;
                        });
                      },
                      label: 'إضافة اليوم الدراسي التالي',
                    ),
                  if (!_complete)
                    AppButton(
                      icon: Icons.check_circle_outline,
                      onPressed: _saving ? null : _submit,
                      label: _saving
                          ? 'جارٍ الحفظ...'
                          : _savedDates.isEmpty
                          ? 'تأكيد وتسجيل الإجازة'
                          : 'إكمال الأيام المتبقية',
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
