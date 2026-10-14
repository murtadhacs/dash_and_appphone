import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/parent_api.dart';
import '../data/parent_data.dart';
import '../screens/login_screen.dart';
import '../services/push_device.dart';
import '../theme/app_colors.dart';
import 'fade_route.dart';
import 'settings_tile.dart';

/// بطاقة «إشعارات» مع مفتاح التفعيل والإيقاف لجميع هواتف الحساب.
class NotificationsSettings extends StatefulWidget {
  const NotificationsSettings({super.key, required this.data});
  final ParentData data;

  @override
  State<NotificationsSettings> createState() =>
      _NotificationsSettingsState();
}

class _NotificationsSettingsState extends State<NotificationsSettings>
    with WidgetsBindingObserver {
  ParentApi get _api => widget.data.api;
  bool? _enabled;
  bool _busy = false;
  String? _loadError;
  PhoneNotificationPermission _permission =
      PhoneNotificationPermission.unavailable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _load() async {
    try {
      final permission = await _api.pushDevice.permission();
      if (mounted) setState(() => _permission = permission);
      final enabled = await _api.notificationSettings();
      if (mounted) {
        setState(() {
          _enabled = enabled;
          _loadError = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted && !e.needsLogin) setState(() => _loadError = e.message);
    }
  }

  Future<void> _register() async {
    final registered = await _api.refreshDeviceRegistration();
    _message(switch (registered) {
      true => 'تم تسجيل هذا الهاتف لاستقبال الإشعارات',
      false => 'إشعارات الحساب متوقفة؛ لم يُسجّل الهاتف',
      null =>
        'تم حفظ الإعداد، لكن تعذر الحصول على رمز الجهاز. تحقق من الاتصال وخدمات Google Play ثم أعد تسجيل الهاتف.',
    });
  }

  Future<void> _toggle(bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!enabled) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('إيقاف إشعارات الهاتف؟'),
            content: const Text(
              'إشعارات وصول الابن وانصرافه لن ترن على هذا الهاتف أو هواتفك الأخرى. ستبقى ظاهرة في قائمة الإشعارات داخل التطبيق.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('إيقاف الإشعارات'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
      final saved = await _api.updateNotificationSettings(enabled);
      if (mounted) setState(() => _enabled = saved);
      if (saved) {
        // Saving true does not register a phone; registration must follow it.
        await _register();
      } else {
        _api.deviceRegistered = false;
      }
    } on ApiException catch (e) {
      if (!e.needsLogin) _message(e.message);
    } catch (_) {
      _message(
        'تم حفظ الإعداد، لكن تعذر تسجيل الهاتف للإشعارات. أعد المحاولة.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _permissionAction() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _api.pushDevice.requestPermission();
      final permission = await _api.pushDevice.permission();
      if (mounted) setState(() => _permission = permission);
      if (permission == PhoneNotificationPermission.denied) {
        await _api.pushDevice.openSettings();
      } else if (_enabled == true) {
        await _register();
      }
    } on ApiException catch (e) {
      if (!e.needsLogin) _message(e.message);
    } catch (_) {
      _message('تعذر تفعيل إشعارات الهاتف، حاول من إعدادات النظام');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsPermission =
        _permission == PhoneNotificationPermission.denied ||
        _permission == PhoneNotificationPermission.notDetermined;
    final needsRegistration =
        _enabled == true &&
        _permission == PhoneNotificationPermission.allowed &&
        _api.deviceRegistered == false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsTile(
          icon: LucideIcons.bell,
          iconBackground: AppColors.purple50,
          iconColor: AppColors.brandPurple,
          title: 'إشعارات',
          subtitle:
              _loadError ??
              (_enabled == null
                  ? 'جارٍ تحميل إعداد الحساب…'
                  : 'إشعارات وصول الأبناء وانصرافهم • لجميع هواتف الحساب'),
          onTap: _loadError != null && !_busy ? _load : null,
          trailing: _loadError != null
              ? const Icon(
                  LucideIcons.rotateCw,
                  size: 16,
                  color: AppColors.textMuted,
                )
              : SettingsSwitch(
                  value: _enabled ?? false,
                  onChanged: _enabled == null || _busy ? null : _toggle,
                ),
        ),
        // تنبيه يظهر فقط عند الحاجة: إذن النظام غير ممنوح أو الهاتف غير مسجّل.
        if (needsPermission || needsRegistration) ...[
          const SizedBox(height: 8),
          SettingsTile(
            icon: LucideIcons.bellOff,
            iconBackground: AppColors.amber50,
            iconColor: AppColors.amber600,
            borderColor: AppColors.amber100,
            title: needsPermission
                ? 'تفعيل إذن الإشعارات في الهاتف'
                : 'إعادة تسجيل هذا الهاتف',
            subtitle: needsPermission
                ? (_permission == PhoneNotificationPermission.denied
                      ? 'الإذن غير مسموح؛ فعّله من إعدادات الهاتف حتى ترن الإشعارات'
                      : 'لم يُمنح الإذن بعد')
                : 'لم يُسجّل الهاتف لاستقبال الإشعارات بعد',
            onTap: _busy ? null : _permissionAction,
          ),
        ],
      ],
    );
  }
}

/// بطاقة حذف حساب ولي الأمر (تفتح نافذة التأكيد برمز PIN).
class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key, required this.data});
  final ParentData data;

  Future<void> _delete(BuildContext context) async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(api: data.api),
    );
    if (deleted != true || !context.mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(FadeRoute(page: const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => SettingsTile(
    icon: LucideIcons.trash2,
    iconBackground: AppColors.rose50,
    iconColor: AppColors.rose600,
    title: 'حذف حساب ولي الأمر',
    titleColor: AppColors.rose600,
    subtitle: 'حذف الحساب وإشعاراته نهائياً',
    onTap: () => _delete(context),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.api});
  final ParentApi api;
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_pin.text.isEmpty) {
      setState(() => _error = 'أدخل رمز PIN لتأكيد حذف الحساب');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.deleteAccount(_pin.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted && !e.needsLogin) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر إتمام العملية، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('حذف الحساب نهائياً'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'الحذف يفصل جميع الأبناء المرتبطين بهذا الرقم عن حسابك، ويحذف الحساب وإشعاراته نهائياً. لا يمكن التراجع. تبقى سجلات الأبناء لدى المدرسة، والإدارة وحدها تستطيع إعادة ربطهم برقم هاتف.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pin,
              enabled: !_busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              decoration: const InputDecoration(labelText: 'رمز PIN الحالي'),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'جارٍ الحذف…' : 'حذف الحساب نهائياً'),
        ),
      ],
    ),
  );
}
