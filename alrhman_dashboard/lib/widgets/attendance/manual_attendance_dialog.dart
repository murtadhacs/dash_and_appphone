import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../core/baghdad_time.dart';
import '../../models/attendance_entry.dart';
import '../../models/manual_attendance.dart';

class ManualAttendanceDialog extends StatefulWidget {
  final AttendanceEntry student;
  final DateTime initialDate;
  final Future<ManualAttendancePreview> Function(ManualAttendanceDraft)?
  onPreview;
  final Future<void> Function(ManualAttendanceDraft)? onSubmit;
  const ManualAttendanceDialog({
    super.key,
    required this.student,
    required this.initialDate,
    this.onPreview,
    this.onSubmit,
  });

  static Future<bool?> show(
    BuildContext context, {
    required AttendanceEntry student,
    required DateTime initialDate,
  }) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        ManualAttendanceDialog(student: student, initialDate: initialDate),
  );

  @override
  State<ManualAttendanceDialog> createState() => _ManualAttendanceDialogState();
}

class _ManualAttendanceDialogState extends State<ManualAttendanceDialog> {
  final _form = GlobalKey<FormState>();
  final _time = TextEditingController(text: '08:00');
  final _notes = TextEditingController();
  late DateTime _date;
  String _kind = 'in';
  bool _notify = true, _busy = false;
  String? _error;
  bool get _connected => widget.onPreview != null && widget.onSubmit != null;

  @override
  void initState() {
    super.initState();
    final today = BaghdadTime.today();
    final yesterday = today.subtract(const Duration(days: 1));
    _date = widget.initialDate == yesterday ? yesterday : today;
  }

  @override
  void dispose() {
    _time.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    if (!_connected || _busy || !_form.currentState!.validate()) return;
    final draft = ManualAttendanceDraft(
      studentId: widget.student.studentId,
      date: _date,
      kind: _kind,
      time: _time.text.trim(),
      notify: _notify,
      notes: _notes.text.trim(),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await widget.onPreview!(draft);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تأكيد الحضور اليدوي'),
          content: Text(
            'الطالب: ${preview.studentName}\nالصف: ${preview.grade ?? '—'}\nالشعبة: ${preview.section ?? '—'}\n'
            'التاريخ: ${BaghdadTime.apiDate(draft.date)}\n${draft.kind == 'in' ? 'دخول' : 'خروج'}: ${draft.time}\n'
            'إشعار الوالد: ${draft.notify ? 'نعم' : 'لا'}${draft.notes.isEmpty ? '' : '\nالملاحظة: ${draft.notes}'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تراجع'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد التسجيل'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await widget.onSubmit!(draft);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = (e.statusCode == 400 || e.statusCode == 409)
              ? e.serverMessage ?? e.message
              : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = BaghdadTime.today();
    final yesterday = today.subtract(const Duration(days: 1));
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('تسجيل حضور يدوي'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${widget.student.fullName} • رقم الطالب ${widget.student.studentId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<DateTime>(
                    initialValue: _date,
                    decoration: const InputDecoration(labelText: 'التاريخ'),
                    items: [
                      DropdownMenuItem(
                        value: today,
                        child: Text('اليوم • ${BaghdadTime.apiDate(today)}'),
                      ),
                      DropdownMenuItem(
                        value: yesterday,
                        child: Text('أمس • ${BaghdadTime.apiDate(yesterday)}'),
                      ),
                    ],
                    onChanged: _busy ? null : (v) => setState(() => _date = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _kind,
                    decoration: const InputDecoration(labelText: 'النوع'),
                    items: const [
                      DropdownMenuItem(value: 'in', child: Text('دخول')),
                      DropdownMenuItem(value: 'out', child: Text('خروج')),
                    ],
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                            _kind = v!;
                            _time.text = _kind == 'in' ? '08:00' : '13:00';
                          }),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _time,
                    enabled: !_busy,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'الوقت بتوقيت بغداد (HH:mm)',
                      hintText: '08:00',
                    ),
                    validator: (v) =>
                        RegExp(
                          r'^([01][0-9]|2[0-3]):[0-5][0-9]$',
                        ).hasMatch((v ?? '').trim())
                        ? null
                        : 'أدخل الوقت بصيغة 24 ساعة، مثل 08:00',
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _notify,
                    title: const Text('إشعار الوالد'),
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _notify = v!),
                  ),
                  TextFormField(
                    controller: _notes,
                    enabled: !_busy,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظة (اختياري)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_connected)
                    const Text(
                      'التسجيل غير متاح حالياً. النموذج جاهز، وستُتاح المعاينة والتأكيد عند تفعيل الخدمة.',
                    ),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: _connected && !_busy ? _preview : null,
            child: Text(_busy ? 'جارٍ التحقق…' : 'معاينة قبل التأكيد'),
          ),
        ],
      ),
    );
  }
}
