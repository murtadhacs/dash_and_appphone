import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/admin_api.dart';
import '../../api/api_exception.dart';
import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../../models/holiday.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_text_field.dart';
import '../common/pill.dart';
import '../ui/seg_tabs.dart';

/// أزرار «إدارة العطل» و«إيقاف الدوام» في بطاقة التاريخ.
///
/// الإنشاء والإلغاء يمران دائماً بمعاينة `dry_run` ثم تأكيد صريح قبل أي كتابة.
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

  /// نافذة «معاينة أثر العطلة» (D5): أرقام المعاينة ثم تأكيد أو رجوع.
  Future<bool> _previewDialog({
    required String title,
    required String subtitle,
    required List<(String, String)> stats,
    required String message,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AppDialog(
          icon: LucideIcons.eye,
          title: title,
          subtitle: subtitle,
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Pill.tone('dry_run', BadgeTone.tint, ltr: true, mono: true),
                  Pill.tone('لم يُنفَّذ أي تغيير بعد', BadgeTone.warn),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              stats[i].$1,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 22,
                                height: 1.4,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              stats[i].$2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              DialogNote(message),
              const SizedBox(height: 20),
              DialogActions(
                children: [
                  AppButton(
                    label: 'رجوع',
                    style: AppButtonStyle.outline,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  AppButton(
                    label: confirmLabel,
                    icon: LucideIcons.check,
                    style: AppButtonStyle.amber,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ],
          ),
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
      final shortened = preview['action'] == 'shortened';
      final ok = await _previewDialog(
        title: 'معاينة إنهاء ${h.title}',
        subtitle: shortened
            ? 'تنتهي العطلة في ${preview['end_date']}'
            : 'ستُحذف العطلة',
        stats: [
          (shortened ? 'تقصير' : 'حذف', 'نوع العملية'),
          ('${preview['recipient_count']}', 'مستلمو الإشعار'),
        ],
        message:
            'يُلغى التعطيل من اليوم فصاعداً، وتبقى الأيام الماضية عطلة. '
            'سيُرسل إشعار إلى ${preview['recipient_count']} ولي أمر.',
        confirmLabel: h.kind == 'pause' && h.active
            ? 'تأكيد استئناف الدوام'
            : 'تأكيد الإلغاء',
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

  Future<void> _manage(String mode) async {
    final result = await showDialog<_ManageResult>(
      context: context,
      builder: (_) => _ManageDialog(mode: mode, items: _items),
    );
    if (result == null || !mounted) return;
    if (result.cancel != null) {
      await _cancel(result.cancel!);
    } else if (result.draft != null) {
      await _create(result.draft!);
    }
  }

  Future<void> _create(Map<String, dynamic> draft) async {
    final pause = draft['kind'] == 'pause';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await widget.api.createHoliday(draft, dryRun: true);
      if (!mounted) return;
      setState(() => _busy = false);
      final ok = await _previewDialog(
        title: pause ? 'معاينة إيقاف الدوام' : 'معاينة أثر العطلة',
        subtitle:
            '${draft['title']} · من ${preview['start_date']} إلى ${preview['end_date'] ?? 'حتى إلغاء الإيقاف'}',
        stats: [
          ('${preview['school_days'] ?? '—'}', 'أيام دراسية'),
          ('${preview['recipient_count']}', 'مستلمو الإشعار'),
        ],
        message:
            'إشعار ${preview['recipient_count']} ولي أمر. '
            'يتوقف حساب الغياب وإشعار الغياب وإشعارات الدخول والانصراف، '
            'وتستمر أجهزة البصمة بحفظ الحركات. سجّل العطلة قبل 12:00 بتوقيت بغداد؛ '
            'الإشعارات التي أُرسلت لا تُسحب.',
        confirmLabel: pause ? 'تأكيد إيقاف الدوام' : 'تأكيد وإنشاء العطلة',
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
        // يذكر العقد معرّف الإغلاق المتعارض في الرسالة.
        final match = RegExp(
          r'closure\s+(\d+)',
          caseSensitive: false,
        ).firstMatch(e.serverMessage ?? e.message);
        final id = match == null ? null : int.tryParse(match.group(1)!);
        final conflict = _items.where((h) => h.id == id).firstOrNull;
        if (conflict != null &&
            await showConfirmDialog(
              context,
              title: 'تداخل مع عطلة مسجّلة',
              message:
                  '${e.serverMessage ?? e.message}\nفتح إلغاء ${conflict.title}؟',
              confirmLabel: 'فتح الإلغاء',
            )) {
          if (mounted) await _cancel(conflict);
        } else if (mounted && conflict == null) {
          await showConfirmDialog(
            context,
            title: 'تداخل مع عطلة مسجّلة',
            message:
                '${e.serverMessage ?? e.message}\nاختر تواريخ أخرى أو ألغِ العطلة المتداخلة من القائمة.',
            confirmLabel: 'حسناً',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _items.where((h) => h.active).firstOrNull;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_busy)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        if (_error != null)
          Tooltip(
            message: _error!,
            child: Pill.tone(_error!, BadgeTone.bad, icon: LucideIcons.circleAlert),
          ),
        if (active != null)
          Pill.tone(
            active.kind == 'pause'
                ? 'الدوام متوقف: ${active.title}'
                : 'عطلة جارية: ${active.title}',
            BadgeTone.warn,
          ),
        AppButton(
          label: 'إدارة العطل',
          icon: LucideIcons.calendarDays,
          style: AppButtonStyle.outline,
          small: true,
          onPressed: _busy ? null : () => _manage('day'),
        ),
        AppButton(
          label: 'إيقاف الدوام',
          icon: LucideIcons.pause,
          style: AppButtonStyle.outline,
          small: true,
          onPressed: _busy ? null : () => _manage('pause'),
        ),
      ],
    );
  }
}

class _ManageResult {
  final Map<String, dynamic>? draft;
  final Holiday? cancel;
  const _ManageResult({this.draft, this.cancel});
}

/// نافذة «إدارة العطل وإيقاف الدوام» (D4): نموذج الإنشاء يميناً والعطل الحالية يساراً.
class _ManageDialog extends StatefulWidget {
  final String mode;
  final List<Holiday> items;
  const _ManageDialog({required this.mode, required this.items});
  @override
  State<_ManageDialog> createState() => _ManageDialogState();
}

class _ManageDialogState extends State<_ManageDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  late String _mode = widget.mode;
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
        : _mode == 'pause'
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
          if (_end != null && _end!.isBefore(_start)) _end = null;
        }
      });
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    if (_mode == 'range' && _end == null) {
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
    if (_mode != 'pause' && days > 60) {
      setState(
        () => _error =
            'العطلة بحد أقصى 60 يوماً؛ استخدم إيقاف الدوام لفترة أطول.',
      );
      return;
    }
    Navigator.pop(
      context,
      _ManageResult(
        draft: <String, dynamic>{
          'kind': _mode == 'pause' ? 'pause' : 'holiday',
          'start_date': BaghdadTime.apiDate(_start),
          if (_mode != 'day' && _end != null)
            'end_date': BaghdadTime.apiDate(_end!),
          'title': _title.text.trim(),
          'notes': _notes.text.trim(),
          'notify': _notify,
        },
      ),
    );
  }

  Widget _dateField(String label, String value, VoidCallback onTap) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FieldLabel(label),
      const SizedBox(height: 6),
      InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                LucideIcons.calendar,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SegTabs<String>(
              items: const [
                ('day', 'عطلة ليوم'),
                ('range', 'عطلة لفترة'),
                ('pause', 'إيقاف الدوام'),
              ],
              value: _mode,
              onChanged: (v) => setState(() {
                _mode = v;
                _error = null;
                if (v == 'day') _end = null;
              }),
            ),
          ),
          const SizedBox(height: 16),
          const FieldLabel('العنوان', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _title,
            maxLength: 80,
            style: const TextStyle(fontSize: 14),
            decoration: appInputDecoration(
              hint: _mode == 'pause' ? 'مثال: العطلة الصيفية' : 'مثال: عطلة رسمية',
            ).copyWith(counterText: ''),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'أدخل العنوان' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _dateField(
                  'من',
                  BaghdadTime.apiDate(_start),
                  () => _pick(false),
                ),
              ),
              if (_mode != 'day') ...[
                const SizedBox(width: 14),
                Expanded(
                  child: _dateField(
                    'إلى',
                    _end == null
                        ? (_mode == 'pause' ? 'مفتوح' : 'غير محددة')
                        : BaghdadTime.apiDate(_end!),
                    () => _pick(true),
                  ),
                ),
              ],
            ],
          ),
          if (_mode == 'pause' && _end != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => _end = null),
                child: const Text('إيقاف مفتوح المدة'),
              ),
            ),
          const SizedBox(height: 14),
          const FieldLabel('ملاحظات', hint: 'اختياري'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _notes,
            maxLength: 500,
            minLines: 2,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: appInputDecoration(
              hint: 'اختياري',
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: 14),
          _NotifyToggle(
            value: _notify,
            onChanged: (v) => setState(() => _notify = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            DialogNote(_error!, tone: NoteTone.bad),
          ],
          const SizedBox(height: 16),
          DialogActions(
            children: [
              AppButton(
                label: 'إلغاء',
                style: AppButtonStyle.outline,
                onPressed: () => Navigator.pop(context),
              ),
              AppButton(
                label: 'معاينة الأثر',
                icon: LucideIcons.eye,
                style: AppButtonStyle.amber,
                onPressed: _submit,
              ),
            ],
          ),
        ],
      ),
    );

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'العطل الحالية',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 10),
        if (widget.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'لا توجد عطل جارية أو قادمة.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        for (final h in widget.items) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        h.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Pill.tone(
                      h.kind == 'pause'
                          ? (h.active ? 'متوقف' : 'إيقاف قادم')
                          : (h.active ? 'نشطة' : 'قادمة'),
                      h.active
                          ? (h.kind == 'pause' ? BadgeTone.warn : BadgeTone.ok)
                          : BadgeTone.tint,
                    ),
                  ],
                ),
                Text(
                  '${h.startDate} — ${h.endDate ?? 'حتى إلغاء الإيقاف'}${h.notes == null ? '' : '\n${h.notes}'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppButton(
                    label: h.kind == 'pause' && h.active
                        ? 'استئناف الدوام'
                        : 'إلغاء/تقصير',
                    icon: h.kind == 'pause' && h.active
                        ? LucideIcons.play
                        : LucideIcons.trash2,
                    style: h.kind == 'pause' && h.active
                        ? AppButtonStyle.amber
                        : AppButtonStyle.dangerSoft,
                    small: true,
                    onPressed: () =>
                        Navigator.pop(context, _ManageResult(cancel: h)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );

    return AppDialog(
      icon: LucideIcons.calendarDays,
      title: 'إدارة العطل وإيقاف الدوام',
      subtitle: 'أنشئ عطلة أو أوقف الدوام، وراجع الأثر قبل التنفيذ',
      maxWidth: 880,
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 700
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: form),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: list),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [form, const SizedBox(height: 20), list],
              ),
      ),
    );
  }
}

/// مفتاح «إشعار أولياء الأمور» بصندوق رمادي كما في Figma.
class _NotifyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifyToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إشعار أولياء الأمور',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'إرسال إشعار للتطبيق عند التنفيذ',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) => AppDialog(
    icon: LucideIcons.calendarX,
    title: 'إنهاء / إلغاء ${widget.holiday.title}',
    subtitle: 'الإلغاء من اليوم فصاعداً؛ تبقى الأيام الماضية عطلة.',
    maxWidth: 520,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel('ملاحظات الإلغاء', hint: 'اختياري'),
        const SizedBox(height: 6),
        TextField(
          controller: _notes,
          maxLength: 500,
          minLines: 2,
          maxLines: 3,
          decoration: appInputDecoration(
            hint: 'اختياري',
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: 12),
        _NotifyToggle(
          value: _notify,
          onChanged: (v) => setState(() => _notify = v),
        ),
        const SizedBox(height: 20),
        DialogActions(
          children: [
            AppButton(
              label: 'تراجع',
              style: AppButtonStyle.outline,
              onPressed: () => Navigator.pop(context),
            ),
            AppButton(
              label: 'معاينة الإلغاء',
              icon: LucideIcons.eye,
              style: AppButtonStyle.amber,
              onPressed: () => Navigator.pop(context, <String, dynamic>{
                'notify': _notify,
                'notes': _notes.text.trim(),
              }),
            ),
          ],
        ),
      ],
    ),
  );
}
