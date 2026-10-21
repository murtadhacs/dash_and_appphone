import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../core/iraqi_phone.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/pill.dart';
import '../widgets/layout/app_header.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/async_states.dart';

/// مفاتيح الإعدادات التي يقرؤها تطبيق ولي الأمر (`GET /api/mobile/settings`).
const _kSchoolName = 'school_name';
const _kWhatsapp = 'whatsapp_number';

/// شاشة إعدادات المدرسة: اسم المدرسة ورقم واتساب الإدارة (يراهما ولي الأمر).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _whatsapp = TextEditingController();

  /// آخر قيم محفوظة في الخادم.
  String _savedName = '';
  String _savedWhatsapp = '';

  bool _loaded = false;
  bool _saving = false;
  bool _started = false;
  String? _error;

  AdminApi get _api => AppScope.of(context).api;

  bool get _dirty =>
      _name.text.trim() != _savedName || _whatsappValue() != _savedWhatsapp;

  /// الرقم بالصيغة القياسية إن كان صالحاً، وإلا النص كما هو (يرفضه المدقق).
  String _whatsappValue() {
    final t = _whatsapp.text.trim();
    if (t.isEmpty) return '';
    return IraqiPhone.normalize(t) ?? t;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final s = await _api.settings();
      if (!mounted) return;
      setState(() {
        _savedName = s[_kSchoolName] ?? '';
        _savedWhatsapp = s[_kWhatsapp] ?? '';
        _name.text = _savedName;
        _whatsapp.text = _savedWhatsapp.isEmpty
            ? ''
            : IraqiPhone.display(_savedWhatsapp);
        _loaded = true;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _reset() => setState(() {
    _name.text = _savedName;
    _whatsapp.text = _savedWhatsapp.isEmpty
        ? ''
        : IraqiPhone.display(_savedWhatsapp);
  });

  Future<void> _save() async {
    if (!_dirty || _saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final whatsapp = _whatsappValue();
      // نرسل ما تغيّر فقط.
      if (name != _savedName) await _api.saveSetting(_kSchoolName, name);
      if (whatsapp != _savedWhatsapp) {
        await _api.saveSetting(_kWhatsapp, whatsapp);
      }
      if (!mounted) return;
      setState(() {
        _savedName = name;
        _savedWhatsapp = whatsapp;
        _saving = false;
      });
      showAppToast(
        context,
        'تم حفظ إعدادات المدرسة بنجاح',
        background: AppColors.greenDeep,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(
        context,
        e.message,
        icon: LucideIcons.circleAlert,
        iconColor: AppColors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = PageHeader(
      title: 'إعدادات المدرسة',
      badge: !_loaded
          ? null
          : _dirty
          ? Pill.tone('تغييرات غير محفوظة', BadgeTone.warn)
          : Pill.tone('جميع الإعدادات محدثة', BadgeTone.ok),
    );
    if (!_loaded) {
      return Column(
        children: [
          header,
          const SizedBox(height: 24),
          _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : const LoadingView(),
        ],
      );
    }

    const intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'بيانات\nالمدرسة',
          style: TextStyle(
            fontSize: 38,
            height: 1.3,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'اسم المدرسة ورقم واتساب يظهران لأولياء الأمور في التطبيق، ويمكنك تعديلهما وحفظهما في أي وقت.',
          style: TextStyle(fontSize: 14, height: 1.7, color: AppColors.textSub),
        ),
      ],
    );

    final card = AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_saving) const LinearProgressIndicator(minHeight: 3),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.slidersHorizontal,
                        size: 28,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'الإعدادات العامة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const FieldLabel('اسم المدرسة', required: true),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _name,
                    prefixIcon: LucideIcons.graduationCap,
                    requiredField: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 18),
                  const FieldLabel('رقم واتساب المدرسة', hint: '(اختياري)'),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _whatsapp,
                    ltr: true,
                    hint: '07XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    prefixIcon: LucideIcons.messageCircle,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null; // اختياري
                      return IraqiPhone.normalize(t) == null
                          ? 'أدخل رقماً عراقياً صحيحاً مثل 07701234567'
                          : null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'يُطبَّع الرقم تلقائياً بصيغة الهاتف العراقي، ويستخدمه ولي الأمر للتواصل مع الإدارة.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      AppButton(
                        label: _saving ? 'جارٍ الحفظ...' : 'حفظ التغييرات',
                        icon: LucideIcons.save,
                        style: AppButtonStyle.amber,
                        onPressed: (!_dirty || _saving) ? null : _save,
                      ),
                      AppButton(
                        label: 'استعادة القيم المحفوظة',
                        icon: LucideIcons.undo2,
                        style: AppButtonStyle.outline,
                        onPressed: (!_dirty || _saving) ? null : _reset,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 900
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 340, child: intro),
                    const SizedBox(width: 28),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: card,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [intro, const SizedBox(height: 20), card],
                ),
        ),
      ],
    );
  }
}
