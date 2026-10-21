import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../api/app_services.dart';
import '../api/api_exception.dart';
import '../core/app_colors.dart';
import '../models/broadcast.dart';
import '../models/student.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/pill.dart';
import '../widgets/layout/app_header.dart';
import '../widgets/ui/hover.dart';
import '../widgets/ui/seg_tabs.dart';

/// قسم «الإشعارات الجماعية»: نموذج إرسال بمعاينة عدد المستلمين، وسجل الإشعارات.
class BroadcastsScreen extends StatefulWidget {
  /// مفتاح «البنرات / الإشعارات الجماعية» من الشاشة الأم (اختياري).
  final Widget? tabs;
  const BroadcastsScreen({super.key, this.tabs});
  @override
  State<BroadcastsScreen> createState() => _BroadcastsScreenState();
}

class _BroadcastsScreenState extends State<BroadcastsScreen> {
  final _title = TextEditingController(), _body = TextEditingController();
  final _form = GlobalKey<FormState>();
  List<Student> _students = [];
  final List<BroadcastItem> _items = [];
  String _audience = 'all';
  String? _phone, _grade, _section, _error, _logError, _studentsError, _success;
  bool _started = false,
      _sending = false,
      _loading = false,
      _studentsLoading = true,
      _hasMore = false;
  int? _before;
  int? _previewCount;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _loadStudents();
    _loadLog();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _studentsLoading = true;
      _studentsError = null;
    });
    try {
      final students = await AppScope.of(context).api.students();
      if (mounted) setState(() => _students = students);
    } on ApiException catch (e) {
      if (mounted) setState(() => _studentsError = e.message);
    } finally {
      if (mounted) setState(() => _studentsLoading = false);
    }
  }

  Future<void> _loadLog({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _logError = null;
    });
    try {
      final page = await AppScope.of(
        context,
      ).api.broadcasts(before: more ? _before : null);
      if (mounted) {
        setState(() {
          if (!more) _items.clear();
          final ids = _items.map((i) => i.id).toSet();
          _items.addAll(page.items.where((i) => !ids.contains(i.id)));
          _hasMore = page.hasMore && page.nextBefore != null;
          _before = page.nextBefore;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _logError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _sendError(ApiException e) => switch (e.statusCode) {
    409 => 'الإشعار نفسه أُرسل قبل أقل من دقيقة. لم يُرسل مرة أخرى.',
    404 => 'ولي الأمر غير موجود. حدّث قائمة الطلاب واختر ولي الأمر مجدداً.',
    400 =>
      e.serverMessage == 'No parents match this audience'
          ? 'لا يوجد أولياء أمور ضمن الجمهور المحدد.'
          : 'تعذر إرسال الإشعار. راجع العنوان والنص والجمهور المحدد.',
    _ => e.message,
  };

  Future<void> _send() async {
    if (_sending || !_form.currentState!.validate()) return;
    final draft = BroadcastDraft(
      title: _title.text,
      body: _body.text,
      type: _audience == 'all' || _audience == 'parent' ? _audience : 'class',
      phone: _phone,
      grade: _audience == 'grade' || _audience == 'class' ? _grade : null,
      section: _audience == 'section' || _audience == 'class' ? _section : null,
    );
    final api = AppScope.of(context).api;
    setState(() {
      _sending = true;
      _error = null;
      _success = null;
    });
    try {
      final count = await api.sendBroadcast(draft, dryRun: true);
      if (!mounted) return;
      if (count < 1) {
        setState(() => _error = 'لا يوجد أولياء أمور ضمن الجمهور المحدد.');
        return;
      }
      setState(() => _previewCount = count);
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AppDialog(
          icon: LucideIcons.send,
          title: 'تأكيد إرسال الإشعار',
          subtitle: 'راجع النص قبل الإرسال؛ لا يمكن تعديله بعد ذلك',
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogNote(
                'سيصل الإشعار إلى $count من أولياء الأمور ولا يمكن سحبه',
                tone: NoteTone.warn,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      draft.body,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.7,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DialogActions(
                children: [
                  AppButton(
                    label: 'إلغاء',
                    style: AppButtonStyle.outline,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  AppButton(
                    label: 'إرسال الإشعار',
                    icon: LucideIcons.send,
                    style: AppButtonStyle.amber,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      final received = await api.sendBroadcast(draft, dryRun: false);
      if (!mounted) return;
      setState(() {
        _success = 'تم إرسال الإشعار إلى $received من أولياء الأمور.';
        _title.clear();
        _body.clear();
      });
      // Refresh only after a successful send; failures never trigger a resend.
      while (_loading && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (mounted) await _loadLog();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _sendError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? _validateText(String? value, int limit) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'هذا الحقل مطلوب';
    if (text.runes.length > limit || text.codeUnits.contains(0)) {
      return 'أدخل نصاً صالحاً بحد أقصى $limit حرفاً';
    }
    return null;
  }

  Widget _select(
    String label,
    String? value,
    Iterable<String> choices,
    ValueChanged<String?> change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FieldLabel(label),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        key: ValueKey('$_audience-$label'),
        initialValue: value,
        isExpanded: true,
        borderRadius: BorderRadius.circular(AppRadius.control),
        decoration: appInputDecoration(hint: 'اختر $label'),
        items: [
          for (final v in choices.toSet().toList()..sort())
            DropdownMenuItem(
              value: v,
              child: Text(v, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _sending ? null : change,
        validator: (v) => v == null ? 'اختر $label' : null,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final parents = <String, Student>{
      for (final s in _students)
        if (s.parentPhone.isNotEmpty) s.parentPhone: s,
    };
    final grades = _students
        .map((s) => s.grade)
        .whereType<String>()
        .where((v) => v.trim().isNotEmpty);
    final sections = _students
        .where((s) => _audience != 'class' || s.grade == _grade)
        .map((s) => s.section)
        .whereType<String>()
        .where((v) => v.trim().isNotEmpty);

    final form = AppCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CardTitle('إشعار جماعي جديد'),
            const SizedBox(height: 18),
            ValueListenableBuilder(
              valueListenable: _title,
              builder: (_, v, _) => FieldLabel(
                'العنوان',
                hint: '(${v.text.runes.length}/100)',
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _title,
              enabled: !_sending,
              maxLength: 100,
              style: const TextStyle(fontSize: 14),
              decoration: appInputDecoration(
                hint: 'مثال: تذكير بموعد الاجتماع',
              ).copyWith(counterText: ''),
              validator: (v) => _validateText(v, 100),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: _body,
              builder: (_, v, _) => FieldLabel(
                'نص الإشعار',
                hint: '(${v.text.runes.length}/500)',
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _body,
              enabled: !_sending,
              maxLength: 500,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(fontSize: 14, height: 1.7),
              decoration: appInputDecoration(
                hint: 'اكتب نص الرسالة هنا…',
              ).copyWith(counterText: ''),
              validator: (v) => _validateText(v, 500),
            ),
            const SizedBox(height: 16),
            const FieldLabel('الجمهور'),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SegTabs<String>(
                items: const [
                  ('all', 'الجميع'),
                  ('parent', 'ولي أمر'),
                  ('grade', 'صف'),
                  ('section', 'شعبة'),
                  ('class', 'صف وشعبة'),
                ],
                value: _audience,
                onChanged: (v) {
                  if (_sending) return;
                  setState(() {
                    _audience = v;
                    _phone = _grade = _section = null;
                    _previewCount = null;
                  });
                },
              ),
            ),
            if (_audience != 'all') ...[
              const SizedBox(height: 16),
              if (_studentsLoading) const LinearProgressIndicator(),
              if (_studentsError != null) ...[
                DialogNote(_studentsError!, tone: NoteTone.bad),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: _sending ? null : _loadStudents,
                    child: const Text('تحديث قائمة الطلاب'),
                  ),
                ),
              ],
              if (_audience == 'parent') ...[
                const FieldLabel('ولي الأمر من قائمة الطلاب'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: const ValueKey('broadcast-parent'),
                  initialValue: _phone,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  decoration: appInputDecoration(hint: 'اختر ولي الأمر'),
                  items: [
                    for (final entry in parents.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          '${entry.value.parentName} • ${entry.key} • ${entry.value.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _sending ? null : (v) => setState(() => _phone = v),
                  validator: (v) => v == null ? 'اختر ولي الأمر' : null,
                ),
              ],
              if (_audience == 'grade' || _audience == 'class')
                _select(
                  'المرحلة',
                  _grade,
                  grades,
                  (v) => setState(() {
                    _grade = v;
                    _section = null;
                  }),
                ),
              if (_audience == 'class') const SizedBox(height: 16),
              if (_audience == 'section' || _audience == 'class')
                KeyedSubtree(
                  key: ValueKey('$_audience-$_grade'),
                  child: _select(
                    'الشعبة',
                    _section,
                    sections,
                    (v) => setState(() => _section = v),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'عدد المستلمين المتوقع',
                      style: TextStyle(fontSize: 13, color: AppColors.brand),
                    ),
                  ),
                  Text(
                    _previewCount == null
                        ? 'يظهر عند المعاينة'
                        : '$_previewCount ولي أمر',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              DialogNote(_error!, tone: NoteTone.bad),
            ],
            if (_success != null) ...[
              const SizedBox(height: 12),
              DialogNote(_success!, tone: NoteTone.ok),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: _sending ? 'جارٍ التحقق والإرسال…' : 'معاينة وإرسال',
              icon: LucideIcons.send,
              style: AppButtonStyle.amber,
              height: 50,
              expand: true,
              onPressed:
                  _sending ||
                      (_audience != 'all' &&
                          (_studentsLoading || _studentsError != null))
                  ? null
                  : _send,
            ),
          ],
        ),
      ),
    );

    final history = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            'سجل الإشعارات',
            trailing: [
              AppButton(
                label: 'تحديث',
                icon: LucideIcons.refreshCw,
                style: AppButtonStyle.outline,
                small: true,
                onPressed: _loading ? null : _loadLog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          if (_logError != null) ...[
            const SizedBox(height: 8),
            DialogNote(_logError!, tone: NoteTone.bad),
          ],
          if (!_loading && _logError == null && _items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text(
                  'لم يُرسل أي إشعار بعد',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          for (var i = 0; i < _items.length; i++)
            _HistoryItem(item: _items[i], last: i == _items.length - 1),
          if (_hasMore) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: 'تحميل إشعارات أقدم',
                icon: LucideIcons.clock,
                style: AppButtonStyle.outline,
                small: true,
                onPressed: _loading ? null : () => _loadLog(more: true),
              ),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'التواصل والإعلانات',
          cta: AppButton(
            label: 'تحديث السجل',
            icon: LucideIcons.refreshCw,
            style: AppButtonStyle.outline,
            onPressed: _loading ? null : _loadLog,
          ),
        ),
        if (widget.tabs != null) ...[
          const SizedBox(height: 24),
          Align(alignment: AlignmentDirectional.centerStart, child: widget.tabs),
        ],
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 1000
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 480, child: form),
                    const SizedBox(width: 20),
                    Expanded(child: history),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [form, const SizedBox(height: 20), history],
                ),
        ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final BroadcastItem item;
  final bool last;
  const _HistoryItem({required this.item, required this.last});

  @override
  Widget build(BuildContext context) {
    final ratio = item.recipients == 0 ? 0.0 : item.readers / item.recipients;
    return HoverLift(
      lift: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(child: Pill.tone(item.audienceLabel, BadgeTone.tint)),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              item.body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.7,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ratio),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        color: AppColors.green,
                        backgroundColor: AppColors.canvas,
                      ),
                    ),
                  ),
                ),
                Text(
                  'قرأه ${item.readers} من ${item.recipients} من أولياء الأمور',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm', 'en').format(
                    item.createdAt.toUtc().add(const Duration(hours: 3)),
                  ),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
