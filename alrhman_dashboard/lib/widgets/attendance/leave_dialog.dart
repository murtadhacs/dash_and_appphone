import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../api/api_exception.dart';
import '../../core/attendance_policy.dart';
import '../../core/baghdad_time.dart';
import '../../models/student.dart';
import '../common/app_dialog.dart';
import '../common/app_button.dart';
import '../common/app_text_field.dart';
import '../../core/app_colors.dart';
import '../ui/letter_avatar.dart';

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
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FieldLabel(label),
      const SizedBox(height: 6),
      _dateInput(controller, end: end),
    ],
  );

  Widget _dateInput(TextEditingController controller, {bool end = false}) =>
      TextFormField(
    controller: controller,
    readOnly: _locked,
    textDirection: TextDirection.ltr,
    style: const TextStyle(fontSize: 14),
    decoration: appInputDecoration(hint: 'yyyy-MM-dd').copyWith(
      suffixIcon: IconButton(
        tooltip: 'اختيار تاريخ',
        onPressed: _locked ? null : () => _pick(controller),
        icon: const Icon(LucideIcons.calendar, size: 18),
        color: AppColors.textMuted,
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
        maxWidth: 600,
        icon: LucideIcons.calendarX,
        iconBackground: AppColors.warnBg,
        iconForeground: AppColors.warnText,
        title: 'منح إجازة',
        subtitle: 'تُحتسب أيام الدوام فقط',
        onClose: _close,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DialogNote(
                'سجّل الإجازات قبل 12:00 بتوقيت بغداد',
                tone: NoteTone.warn,
                icon: LucideIcons.clock,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DialogNote(_error!, tone: NoteTone.bad),
                ),
              if (_complete)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DialogNote(
                    'تم تسجيل الإجازة بنجاح لـ ${_savedDates.length} أيام دراسية.',
                    tone: NoteTone.ok,
                  ),
                ),
              AbsorbPointer(
                absorbing: _saving || _savedDates.isNotEmpty || _complete,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FieldLabel('الطالب'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _search,
                      readOnly: _locked,
                      style: const TextStyle(fontSize: 14),
                      decoration: appInputDecoration(
                        hint: 'ابحث بالاسم أو الصف أو رقم البصمة',
                        prefix: const Icon(
                          LucideIcons.search,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hoverColor: AppColors.rowHover,
                                leading: LetterAvatar(name: s.name, size: 34),
                                title: Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            LetterAvatar(name: _student!.name),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _student!.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  Text(
                                    '${_student!.gradeSection} • معرّف البصمة: ${_student!.rfidTag}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.circleCheck,
                              color: AppColors.green,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (_, constraints) {
                        final start = _dateField('من تاريخ', _start);
                        final end = _dateField('إلى تاريخ', _end, end: true);
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
                    DialogNote(
                      '${_days.length} أيام دوام (الجمعة والسبت مستثناتان). ستُرسل كل يوم على حدة.',
                      tone: NoteTone.ok,
                      icon: LucideIcons.check,
                    ),
                    const SizedBox(height: 14),
                    const FieldLabel('السبب / ملاحظات'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _reason,
                      readOnly: _locked,
                      minLines: 3,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                      decoration: appInputDecoration(
                        hint: 'مثال: مراجعة طبية',
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'جارٍ الحفظ: ${_savedDates.length} من ${_days.length} أيام',
                    style: const TextStyle(color: AppColors.textSub),
                  ),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
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
                      icon: LucideIcons.check,
                      style: AppButtonStyle.amber,
                      onPressed: _saving ? null : _submit,
                      label: _saving
                          ? 'جارٍ الحفظ...'
                          : _savedDates.isEmpty
                          ? 'منح الإجازة'
                          : 'إكمال الأيام المتبقية',
                    ),
                  AppButton(
                    onPressed: _saving ? null : _close,
                    style: AppButtonStyle.outline,
                    label: _savedAny ? 'إغلاق' : 'إلغاء',
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
