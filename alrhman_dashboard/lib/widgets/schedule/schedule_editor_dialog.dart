import 'package:flutter/material.dart';
import '../../api/admin_api.dart';
import '../../api/api_exception.dart';
import '../../core/app_colors.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_text_field.dart';
import '../ui/seg_tabs.dart';
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
    final confirmed = await showConfirmDialog(
      context,
      title: 'حفظ جدول الصف',
      icon: Icons.save_outlined,
      message:
          'الصف: ${widget.schoolClass.label}\n${periods.length} حصة موزّعة على ${_counts.values.where((c) => c > 0).length} أيام.\n'
          '${periods.isEmpty ? 'سيُمسح الجدول الحالي.' : 'سيحل هذا الجدول محل الجدول الحالي ويظهر لأولياء الأمور.'}'
          '${_legacyCount == 0 ? '' : '\nسيُستبدل أيضاً $_legacyCount من السجلات القديمة خارج الحصص 1 إلى 6.'}',
      confirmLabel: 'تأكيد الحفظ',
    );
    if (!confirmed || !mounted) return;
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

  InputDecoration _field(String label) =>
      appInputDecoration(hint: label).copyWith(counterText: '');

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AppDialog(
      icon: Icons.calendar_today_outlined,
      title:
          '${widget.periods.isEmpty ? 'إعداد' : 'تعديل'} جدول ${widget.schoolClass.label}',
      subtitle: 'كل يوم يحتوي 5 أو 6 حصص، ويمكن ترك يوم كامل دون حصص',
      maxWidth: 760,
      onClose: _saving ? () {} : () => Navigator.pop(context, false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SegTabs<String>(
              items: [for (final d in scheduleWeekdays) (d, d)],
              value: _day,
              onChanged: (day) {
                if (_saving) return;
                setState(() {
                  _day = day;
                  _error = null;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          FieldLabel('عدد حصص $_day'),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            key: ValueKey(_day),
            initialValue: _counts[_day],
            borderRadius: BorderRadius.circular(AppRadius.control),
            decoration: appInputDecoration(),
            items: const [
              DropdownMenuItem(value: 0, child: Text('بدون حصص')),
              DropdownMenuItem(value: 5, child: Text('5 حصص')),
              DropdownMenuItem(value: 6, child: Text('6 حصص')),
            ],
            onChanged: _saving
                ? null
                : (count) => setState(() => _counts[_day] = count!),
          ),
          const SizedBox(height: 14),
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
                    style: const TextStyle(fontSize: 14),
                    decoration: _field('مادة الحصة $n'),
                  );
                  final teacher = TextField(
                    key: ValueKey('teacher/$_day/$n'),
                    controller: _teachers[_key(_day, n)],
                    enabled: !_saving,
                    maxLength: 100,
                    style: const TextStyle(fontSize: 14),
                    decoration: _field('المعلم (اختياري)'),
                  );
                  final number = Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$n',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brand,
                      ),
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
                            number,
                            const SizedBox(width: 12),
                            Expanded(child: subject),
                            const SizedBox(width: 12),
                            Expanded(child: teacher),
                          ],
                        );
                },
              ),
            ),
          if (_legacyCount > 0)
            DialogNote(
              'يحتوي الجدول القديم $_legacyCount من الحصص خارج النطاق الحالي؛ ستُستبدل عند الحفظ.',
              tone: NoteTone.warn,
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            DialogNote(_error!, tone: NoteTone.bad),
          ],
          const SizedBox(height: 16),
          DialogActions(
            children: [
              AppButton(
                label: 'إلغاء',
                style: AppButtonStyle.outline,
                onPressed: _saving ? null : () => Navigator.pop(context, false),
              ),
              AppButton(
                label: _saving ? 'جارٍ الحفظ…' : 'حفظ الجدول',
                icon: Icons.save_outlined,
                style: AppButtonStyle.amber,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
