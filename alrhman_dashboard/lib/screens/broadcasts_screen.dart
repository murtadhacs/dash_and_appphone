import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/app_services.dart';
import '../api/api_exception.dart';
import '../models/broadcast.dart';
import '../models/student.dart';

class BroadcastsScreen extends StatefulWidget {
  const BroadcastsScreen({super.key});
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
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('تأكيد إرسال الإشعار'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('سيصل الإشعار إلى $count من أولياء الأمور ولا يمكن سحبه'),
                const SizedBox(height: 16),
                Text(
                  draft.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(draft.body),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إرسال الإشعار'),
            ),
          ],
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
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$_audience-$label'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: [
      for (final v in choices.toSet().toList()..sort())
        DropdownMenuItem(
          value: v,
          child: Text(v, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: _sending ? null : change,
    validator: (v) => v == null ? 'اختر $label' : null,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'إرسال إشعار لأولياء الأمور',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'تظهر الرسالة في إشعارات ولي الأمر. الإشعار المرسل لا يمكن تعديله أو سحبه.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    enabled: !_sending,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الإشعار',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _validateText(v, 100),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _body,
                    enabled: !_sending,
                    maxLength: 500,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'نص الإشعار',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _validateText(v, 500),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _audience,
                    decoration: const InputDecoration(
                      labelText: 'الجمهور',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('جميع أولياء الأمور'),
                      ),
                      DropdownMenuItem(
                        value: 'parent',
                        child: Text('ولي أمر واحد'),
                      ),
                      DropdownMenuItem(
                        value: 'grade',
                        child: Text('مرحلة كاملة'),
                      ),
                      DropdownMenuItem(
                        value: 'section',
                        child: Text('شعبة في جميع المراحل'),
                      ),
                      DropdownMenuItem(
                        value: 'class',
                        child: Text('مرحلة وشعبة'),
                      ),
                    ],
                    onChanged: _sending
                        ? null
                        : (v) => setState(() {
                            _audience = v!;
                            _phone = _grade = _section = null;
                          }),
                  ),
                  if (_audience != 'all') ...[
                    const SizedBox(height: 16),
                    if (_studentsLoading) const LinearProgressIndicator(),
                    if (_studentsError != null) ...[
                      Text(_studentsError!),
                      TextButton(
                        onPressed: _sending ? null : _loadStudents,
                        child: const Text('تحديث قائمة الطلاب'),
                      ),
                    ],
                    if (_audience == 'parent')
                      DropdownButtonFormField<String>(
                        key: const ValueKey('broadcast-parent'),
                        initialValue: _phone,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'ولي الأمر من قائمة الطلاب',
                          border: OutlineInputBorder(),
                        ),
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
                        onChanged: _sending
                            ? null
                            : (v) => setState(() => _phone = v),
                        validator: (v) => v == null ? 'اختر ولي الأمر' : null,
                      ),
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
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_success != null)
                    Text(
                      _success!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      onPressed:
                          _sending ||
                              (_audience != 'all' &&
                                  (_studentsLoading || _studentsError != null))
                          ? null
                          : _send,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(
                        _sending
                            ? 'جارٍ التحقق والإرسال…'
                            : 'معاينة عدد المستلمين',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'سجل الإشعارات المرسلة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed: _loading ? null : _loadLog,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث السجل'),
            ),
          ],
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_logError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _logError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (!_loading && _logError == null && _items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('لم يُرسل أي إشعار بعد'),
          ),
        for (final item in _items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(item.body),
                  const SizedBox(height: 12),
                  Text(item.audienceLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text(
                        'قرأه ${item.readers} من ${item.recipients} من أولياء الأمور',
                      ),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm', 'en').format(
                          item.createdAt.toUtc().add(const Duration(hours: 3)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (_hasMore)
          Align(
            child: OutlinedButton(
              onPressed: _loading ? null : () => _loadLog(more: true),
              child: const Text('تحميل إشعارات أقدم'),
            ),
          ),
      ],
    );
  }
}
