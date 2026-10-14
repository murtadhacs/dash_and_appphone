import 'package:flutter/material.dart';

import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../core/iraqi_phone.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_text_field.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/async_states.dart';
import '../widgets/settings/settings_action_bar.dart';
import '../widgets/settings/settings_group_header.dart';

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
        icon: Icons.error_outline,
        iconColor: AppColors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : const LoadingView();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 672),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 24),
            AppCard(
              padding: EdgeInsets.zero,
              clip: true,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_saving) const LinearProgressIndicator(minHeight: 4),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SettingsGroupHeader(
                            icon: Icons.apartment_outlined,
                            title: 'الهوية والاتصال',
                            subtitle:
                                'يظهران لأولياء الأمور في تطبيق ولي الأمر',
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('اسم المدرسة'),
                          const SizedBox(height: 6),
                          AppTextField(
                            controller: _name,
                            height: 44,
                            fontWeight: FontWeight.w600,
                            prefixIcon: Icons.school_outlined,
                            requiredField: true,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel(
                            'رقم واتساب إدارة المدرسة',
                            hint: 'يستخدمه ولي الأمر للتواصل مع الإدارة',
                          ),
                          const SizedBox(height: 6),
                          AppTextField(
                            controller: _whatsapp,
                            height: 44,
                            ltr: true,
                            mono: true,
                            hint: '07XXXXXXXXX',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.chat_bubble_outline,
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return null; // اختياري
                              return IraqiPhone.normalize(t) == null
                                  ? 'أدخل رقماً عراقياً صحيحاً مثل 07701234567'
                                  : null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    SettingsActionBar(
                      isDirty: _dirty,
                      isSaving: _saving,
                      onReset: _reset,
                      onSave: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, size: 14, color: AppColors.textMuted),
            SizedBox(width: 8),
            Text(
              'النظام الإداري',
              style: TextStyle(fontSize: 12, color: AppColors.textSub),
            ),
            SizedBox(width: 8),
            Text('/', style: TextStyle(color: AppColors.outline)),
            SizedBox(width: 8),
            Text(
              'الإعدادات العامة',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'إعدادات المدرسة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
