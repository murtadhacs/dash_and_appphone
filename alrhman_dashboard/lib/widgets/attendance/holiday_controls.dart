import 'package:flutter/material.dart';
import '../../api/admin_api.dart';
import '../../api/api_exception.dart';
import '../../core/baghdad_time.dart';
import '../../models/holiday.dart';

class HolidayControls extends StatefulWidget {
  final AdminApi api;
  final Future<void> Function() onChanged;
  const HolidayControls({
    super.key,
    required this.api,
    required this.onChanged,
  });
  @override
  State<HolidayControls> createState() => _HolidayControlsState();
}

class _HolidayControlsState extends State<HolidayControls> {
  List<Holiday> _items = [];
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.api.holidays();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.serverMessage ?? e.message);
    }
  }

  Future<bool> _confirm(String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تراجع'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _cancel(Holiday h) async {
    final options = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CancelOptions(holiday: h),
    );
    if (options == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await widget.api.cancelHoliday(
        h.id,
        dryRun: true,
        notify: options['notify'] as bool,
        notes: options['notes'] as String,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      final ok = await _confirm(
        'إنهاء / إلغاء ${h.title}',
        'يُلغى التعطيل من اليوم فصاعداً، وتبقى الأيام الماضية عطلة.\n'
            '${preview['action'] == 'shortened' ? 'تنتهي العطلة في ${preview['end_date']}.' : 'ستُحذف العطلة.'}\n'
            'سيُرسل إشعار إلى ${preview['recipient_count']} ولي أمر.',
      );
      if (!ok || !mounted) return;
      setState(() => _busy = true);
      await widget.api.cancelHoliday(
        h.id,
        dryRun: false,
        notify: options['notify'] as bool,
        notes: options['notes'] as String,
      );
      await _load();
      await widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.serverMessage ?? e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create(String mode) async {
    final draft = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _HolidayForm(mode: mode),
    );
    if (draft == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await widget.api.createHoliday(draft, dryRun: true);
      if (!mounted) return;
      setState(() => _busy = false);
      final ok = await _confirm(
        mode == 'pause' ? 'تأكيد إيقاف الدوام' : 'تأكيد تسجيل العطلة',
        '${draft['title']}\nمن ${preview['start_date']} إلى ${preview['end_date'] ?? 'حتى إلغاء الإيقاف'}\n'
        '${preview['school_days'] ?? 'مدة مفتوحة'} أيام دراسية، إشعار ${preview['recipient_count']} ولي أمر.\n\n'
        'يتوقف حساب الغياب وإشعار الغياب وإشعارات الدخول والانصراف. '
        'تستمر أجهزة البصمة بحفظ الحركات، وتبقى الإجازات وتسجيل الدخول والتعاميم متاحة.\n\n'
        'سجّل العطلة قبل 12:00 بتوقيت بغداد. إشعار الغياب وإشعارات البصمة التي أُرسلت لا تُسحب.',
      );
      if (!ok || !mounted) return;
      setState(() => _busy = true);
      await widget.api.createHoliday(draft, dryRun: false);
      await _load();
      await widget.onChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.serverMessage ?? e.message);
      if (e.statusCode == 409) {
        // The contract identifies the conflicting closure in its message.
        final match = RegExp(
          r'closure\s+(\d+)',
          caseSensitive: false,
        ).firstMatch(e.serverMessage ?? e.message);
        final id = match == null ? null : int.tryParse(match.group(1)!);
        final conflict = _items.where((h) => h.id == id).firstOrNull;
        if (conflict != null &&
            await _confirm(
              'تداخل مع عطلة مسجّلة',
              '${e.serverMessage ?? e.message}\nفتح إلغاء ${conflict.title}؟',
            )) {
          if (mounted) await _cancel(conflict);
        } else if (mounted && conflict == null) {
          await _confirm(
            'تداخل مع عطلة مسجّلة',
            '${e.serverMessage ?? e.message}\nاختر تواريخ أخرى أو ألغِ العطلة المتداخلة من القائمة.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : () => _create('day'),
                icon: const Icon(Icons.event),
                label: const Text('عطلة يوم'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _create('range'),
                icon: const Icon(Icons.date_range),
                label: const Text('عطلة فترة'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _create('pause'),
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('إيقاف الدوام'),
              ),
              IconButton(
                onPressed: _busy ? null : _load,
                tooltip: 'تحديث العطل',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const Text(
            'سجّل العطلة قبل 12:00 بتوقيت بغداد؛ الإشعارات المرسلة لا تُسحب. لا يمكن تداخل العطل.',
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          for (final h in _items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                h.kind == 'pause' ? Icons.pause_circle : Icons.event,
              ),
              title: Text(
                '${h.active ? 'عطلة جارية: ' : 'عطلة قادمة: '}${h.title}',
              ),
              subtitle: Text(
                '${h.startDate} — ${h.endDate ?? 'حتى إلغاء الإيقاف'}${h.notes == null ? '' : '\n${h.notes}'}',
              ),
              trailing: TextButton(
                onPressed: _busy ? null : () => _cancel(h),
                child: Text(
                  h.kind == 'pause' && h.active
                      ? 'استئناف الدوام'
                      : 'إنهاء / إلغاء',
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _HolidayForm extends StatefulWidget {
  final String mode;
  const _HolidayForm({required this.mode});
  @override
  State<_HolidayForm> createState() => _HolidayFormState();
}

class _HolidayFormState extends State<_HolidayForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  DateTime _start = BaghdadTime.today();
  DateTime? _end;
  bool _notify = true;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(bool end) async {
    final first = end
        ? _start
        : widget.mode == 'pause'
        ? BaghdadTime.today()
        : DateTime(2000);
    final initial = end ? (_end ?? _start) : _start;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() {
        if (end) {
          _end = picked;
        } else {
          _start = picked;
          if (_end != null && _end!.isBefore(_start)) {
            _end = null;
          }
        }
      });
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (widget.mode == 'range' && _end == null) {
      setState(() => _error = 'اختر تاريخ نهاية الفترة');
      return;
    }
    final days = _end == null
        ? 1
        : DateTime.utc(_end!.year, _end!.month, _end!.day)
                  .difference(
                    DateTime.utc(_start.year, _start.month, _start.day),
                  )
                  .inDays +
              1;
    if (widget.mode != 'pause' && days > 60) {
      setState(
        () => _error =
            'العطلة بحد أقصى 60 يوماً؛ استخدم إيقاف الدوام لفترة أطول.',
      );
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'kind': widget.mode == 'pause' ? 'pause' : 'holiday',
      'start_date': BaghdadTime.apiDate(_start),
      if (widget.mode != 'day' && _end != null)
        'end_date': BaghdadTime.apiDate(_end!),
      'title': _title.text.trim(),
      'notes': _notes.text.trim(),
      'notify': _notify,
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.mode == 'pause'
          ? 'إيقاف الدوام'
          : widget.mode == 'range'
          ? 'عطلة فترة (حتى 60 يوماً)'
          : 'عطلة يوم',
    ),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'عنوان العطلة'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'أدخل العنوان' : null,
              ),
              TextFormField(
                controller: _notes,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                ),
              ),
              TextButton(
                onPressed: () => _pick(false),
                child: Text('البداية: ${BaghdadTime.apiDate(_start)}'),
              ),
              if (widget.mode != 'day')
                TextButton(
                  onPressed: () => _pick(true),
                  child: Text(
                    'النهاية: ${_end == null ? 'غير محددة' : BaghdadTime.apiDate(_end!)}',
                  ),
                ),
              if (widget.mode == 'pause' && _end != null)
                TextButton(
                  onPressed: () => setState(() => _end = null),
                  child: const Text('إيقاف مفتوح المدة'),
                ),
              CheckboxListTile(
                value: _notify,
                onChanged: (v) => setState(() => _notify = v!),
                title: const Text('إشعار أولياء الأمور'),
              ),
              const Text(
                'سجّل العطلة قبل 12:00. الإشعارات التي أُرسلت لا يمكن سحبها.',
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
        onPressed: () => Navigator.pop(context),
        child: const Text('تراجع'),
      ),
      FilledButton(onPressed: _submit, child: const Text('معاينة قبل التأكيد')),
    ],
  );
}

class _CancelOptions extends StatefulWidget {
  final Holiday holiday;
  const _CancelOptions({required this.holiday});
  @override
  State<_CancelOptions> createState() => _CancelOptionsState();
}

class _CancelOptionsState extends State<_CancelOptions> {
  final _notes = TextEditingController();
  bool _notify = true;
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('إنهاء / إلغاء ${widget.holiday.title}'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الإلغاء من اليوم فصاعداً؛ تبقى الأيام الماضية عطلة.'),
            TextField(
              controller: _notes,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات الإلغاء (اختياري)',
              ),
            ),
            CheckboxListTile(
              value: _notify,
              onChanged: (v) => setState(() => _notify = v!),
              title: const Text('إشعار أولياء الأمور'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('تراجع'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, <String, dynamic>{
          'notify': _notify,
          'notes': _notes.text.trim(),
        }),
        child: const Text('معاينة الإلغاء'),
      ),
    ],
  );
}
