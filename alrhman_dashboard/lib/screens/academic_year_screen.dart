import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/accounts_errors.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../widgets/accounts/accounts_widgets.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/pill.dart';
import '../widgets/layout/app_header.dart';

/// سنتان متتاليتان مثل 2027-2028، وإلا رسالة الخطأ.
String? validateAcademicYear(String? v) {
  final m = RegExp(r'^(20\d\d)-(20\d\d)$').firstMatch((v ?? '').trim());
  if (m == null) return 'اكتب سنتين متتاليتين مثل 2027-2028';
  if (int.parse(m.group(2)!) != int.parse(m.group(1)!) + 1) {
    return 'السنتان يجب أن تكونا متتاليتين';
  }
  return null;
}

/// تغيير السنة الدراسية. إجراء نادر: يجمّد أرصدة كل الطلاب في السنة القديمة
/// ويبدأ السنة الجديدة بلا أقساط ولا دفعات، لذا له شاشة منفصلة بتأكيد صريح
/// ولا يظهر كحقل عادي في إعدادات المدرسة.
class AcademicYearScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AcademicYearScreen({super.key, required this.onBack});

  @override
  State<AcademicYearScreen> createState() => _AcademicYearScreenState();
}

class _AcademicYearScreenState extends State<AcademicYearScreen> {
  final _form = GlobalKey<FormState>();
  final _year = TextEditingController();
  String? _current, _loadError, _error;
  bool _understoodFreeze = false, _understoodReprice = false;
  bool _saving = false, _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final fees = await AppScope.of(context).api.tuitionFees();
      if (mounted) setState(() => _current = fees.academicYear);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.accountsMessage);
    }
  }

  bool get _ready =>
      _understoodFreeze &&
      _understoodReprice &&
      validateAcademicYear(_year.text) == null &&
      _year.text.trim() != _current;

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate() || !_ready) return;
    final next = _year.text.trim();
    final sure = await showConfirmDialog(
      context,
      title: 'تأكيد تغيير السنة الدراسية',
      message:
          'ستنتقل السنة الدراسية من $_current إلى $next ولا يمكن التراجع تلقائياً.\n'
          'تُجمَّد أرصدة السنة القديمة، وتبدأ الجديدة بلا أقساط ولا دفعات.',
      confirmLabel: 'نعم، غيّر السنة',
      danger: true,
      icon: LucideIcons.calendarRange,
    );
    if (!sure || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppScope.of(context).api.changeAcademicYear(next);
      if (!mounted) return;
      showAppToast(context, 'تم الانتقال إلى السنة الدراسية $next');
      widget.onBack();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'تغيير السنة الدراسية',
          badge: _current == null
              ? null
              : Pill.tone('الحالية $_current', BadgeTone.tint, ltr: false),
          actions: [
            AppButton(
              label: 'رجوع إلى الأقساط',
              icon: LucideIcons.arrowRight,
              style: AppButtonStyle.outline,
              onPressed: _saving ? null : widget.onBack,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_current == null)
          _loadError != null
              ? ErrorView(message: _loadError!, onRetry: _load)
              : const LoadingView()
        else
          AppCard(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DialogNote(
                    'عند التغيير يُنشأ حساب لكل طالب فعّال لصفه قسط في السنة القديمة وليس له '
                    'حساب بعد، ليجمّد ذلك القسط فلا تتغير أرصدة السنة القديمة بعدها. السنة '
                    'الجديدة تبدأ بلا أقساط ولا دفعات، ولا يُعدَّل ولا يُحذف أي سجل.',
                    tone: NoteTone.warn,
                  ),
                  const SizedBox(height: 12),
                  const DialogNote(
                    'غيّر السنة قبل تغيير صفوف الطلاب (الترفيع)، وبعدها حدّد أقساط الصفوف للسنة الجديدة.',
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    DialogNote(_error!, tone: NoteTone.bad),
                    const SizedBox(height: 16),
                  ],
                  const FieldLabel('السنة الدراسية الجديدة', required: true),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 280,
                    child: AppTextField(
                      controller: _year,
                      ltr: true,
                      maxLength: 9,
                      hint: '2027-2028',
                      validator: validateAcademicYear,
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConfirmCheck(
                    value: _understoodFreeze,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _understoodFreeze = v),
                    label:
                        'أفهم أن أرصدة السنة الحالية ستُجمَّد وتبقى للمراجعة فقط.',
                  ),
                  ConfirmCheck(
                    value: _understoodReprice,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _understoodReprice = v),
                    label:
                        'أفهم أن السنة الجديدة تبدأ بلا أقساط ولا دفعات حتى أحدّدها.',
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppButton(
                      label: _saving
                          ? 'جارٍ التغيير...'
                          : 'تغيير السنة الدراسية',
                      icon: LucideIcons.calendarRange,
                      style: AppButtonStyle.danger,
                      onPressed: _saving || !_ready ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
