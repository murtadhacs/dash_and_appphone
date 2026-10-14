import 'package:flutter/material.dart';
import '../../api/admin_api.dart';
import '../../api/api_exception.dart';
import '../../core/app_colors.dart';
import '../../models/schedule_class.dart';
import '../../models/schedule_period.dart';

class ScheduleEditorDialog extends StatefulWidget {
  final AdminApi api;
  final ScheduleClass schoolClass;
  final List<SchedulePeriod> periods;
  const ScheduleEditorDialog({
    super.key,
    required this.api,
    required this.schoolClass,
    required this.periods,
  });
  @override
  State<ScheduleEditorDialog> createState() => _ScheduleEditorDialogState();
}

class _ScheduleEditorDialogState extends State<ScheduleEditorDialog> {
  final _subjects = <String, TextEditingController>{};
  final _teachers = <String, TextEditingController>{};
  final _counts = <String, int>{};
  String _day = scheduleWeekdays.first;
  bool _saving = false;
  String? _error;
  String _key(String day, int number) => '$day/$number';
  int get _legacyCount => widget.periods
      .where(
        (p) =>
            !scheduleWeekdays.contains(p.day) || p.number < 1 || p.number > 6,
      )
      .length;
  @override
  void initState() {
    super.initState();
    for (final day in scheduleWeekdays) {
      final rows = widget.periods.where((p) => p.day == day).toList();
      _counts[day] = rows.isEmpty
          ? (widget.periods.isEmpty ? 5 : 0)
          : rows.any((p) => p.number >= 6)
          ? 6
          : 5;
      for (var n = 1; n <= 6; n++) {
        final period = rows.where((p) => p.number == n).firstOrNull;
        _subjects[_key(day, n)] = TextEditingController(
          text: period?.subject ?? '',
        );
        _teachers[_key(day, n)] = TextEditingController(
          text: period?.teacher ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [..._subjects.values, ..._teachers.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final periods = <SchedulePeriod>[];
    for (final day in scheduleWeekdays) {
      for (var n = 1; n <= _counts[day]!; n++) {
        final subject = _subjects[_key(day, n)]!.text.trim();
        final teacher = _teachers[_key(day, n)]!.text.trim();
        if (subject.isEmpty || subject.length > 100 || teacher.length > 100) {
          setState(() {
            _day = day;
            _error = subject.isEmpty
                ? 'أدخل مادة الحصة $n ليوم $day'
                : 'اسم المادة أو المعلم لا يتجاوز 100 حرف';
          });
          return;
        }
        periods.add(
          SchedulePeriod(
            day: day,
            number: n,
            subject: subject,
            teacher: teacher,
          ),
        );
      }
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حفظ جدول الصف'),
        content: Text(
          'الصف: ${widget.schoolClass.label}\n${periods.length} حصة موزّعة على ${_counts.values.where((c) => c > 0).length} أيام.\n'
          '${periods.isEmpty ? 'سيُمسح الجدول الحالي.' : 'سيحل هذا الجدول محل الجدول الحالي ويظهر لأولياء الأمور.'}'
          '${_legacyCount == 0 ? '' : '\nسيُستبدل أيضاً $_legacyCount من السجلات القديمة خارج الحصص 1 إلى 6.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الحفظ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.saveSchedule(widget.schoolClass, periods);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.statusCode == 400 || e.statusCode == 404
              ? e.serverMessage ?? e.message
              : e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(
        '${widget.periods.isEmpty ? 'إعداد' : 'تعديل'} جدول ${widget.schoolClass.label}',
      ),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'اختر اليوم وأدخل المواد والمعلمين. كل يوم يحتوي 5 أو 6 حصص، ويمكن ترك يوم كامل دون حصص.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final day in scheduleWeekdays)
                    ChoiceChip(
                      label: Text(day),
                      selected: _day == day,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() {
                              _day = day;
                              _error = null;
                            }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: ValueKey(_day),
                initialValue: _counts[_day],
                decoration: InputDecoration(
                  labelText: 'عدد حصص $_day',
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('بدون حصص')),
                  DropdownMenuItem(value: 5, child: Text('5 حصص')),
                  DropdownMenuItem(value: 6, child: Text('6 حصص')),
                ],
                onChanged: _saving
                    ? null
                    : (count) => setState(() => _counts[_day] = count!),
              ),
              const SizedBox(height: 12),
              for (var n = 1; n <= _counts[_day]!; n++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final subject = TextField(
                        key: ValueKey('subject/$_day/$n'),
                        controller: _subjects[_key(_day, n)],
                        enabled: !_saving,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: 'مادة الحصة $n',
                          counterText: '',
                          border: const OutlineInputBorder(),
                        ),
                      );
                      final teacher = TextField(
                        key: ValueKey('teacher/$_day/$n'),
                        controller: _teachers[_key(_day, n)],
                        enabled: !_saving,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'المعلم (اختياري)',
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                      );
                      return constraints.maxWidth < 450
                          ? Column(
                              children: [
                                subject,
                                const SizedBox(height: 8),
                                teacher,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: subject),
                                const SizedBox(width: 12),
                                Expanded(child: teacher),
                              ],
                            );
                    },
                  ),
                ),
              if (_legacyCount > 0)
                Text(
                  'يحتوي الجدول القديم $_legacyCount من الحصص خارج النطاق الحالي؛ ستُستبدل عند الحفظ.',
                  style: const TextStyle(color: AppColors.warnDeep),
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.redDark)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'جارٍ الحفظ…' : 'حفظ الجدول'),
        ),
      ],
    ),
  );
}
