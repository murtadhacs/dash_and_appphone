import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../models/device.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/pill.dart';
import '../widgets/layout/app_header.dart';
import '../widgets/ui/kpi_tile.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/responsive_grid.dart';
import '../widgets/devices/device_card.dart';
import '../widgets/devices/device_form_dialog.dart';

/// شاشة الأجهزة وبوابات الحضور (`/api/admin/devices`).
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<Device>? _devices;
  String? _error;
  bool _refreshing = false;
  bool _started = false;

  /// الأجهزة التي يجري تعديلها الآن (لتعطيل أزرارها ومنع الضغط المزدوج).
  final _busy = <String>{};

  AdminApi get _api => AppScope.of(context).api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final list = await _api.devices();
      if (!mounted) return;
      setState(() {
        _devices = list;
        _refreshing = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        if (_devices == null) _error = e.message;
      });
      if (_devices != null) _toastError(e.message);
    }
  }

  Future<void> _add() async {
    final saved = await DeviceFormDialog.show(
      context,
      onSubmit: (serial, location) =>
          _api.createDevice(serialNumber: serial, locationName: location),
    );
    if (!saved || !mounted) return;
    showAppToast(context, 'تمت إضافة الجهاز بنجاح');
    _load();
  }

  Future<void> _editLocation(Device d) async {
    final saved = await DeviceFormDialog.show(
      context,
      editing: d,
      onSubmit: (_, location) => _api.updateDevice(
        serialNumber: d.serialNumber,
        locationName: location,
      ),
    );
    if (!saved || !mounted) return;
    showAppToast(context, 'تم تحديث موقع الجهاز');
    _load();
  }

  Future<void> _toggle(Device d) async {
    final next = !d.isActive;
    if (!next) {
      // تحذير قبل التعطيل.
      final ok = await showConfirmDialog(
        context,
        title: 'تعطيل الجهاز',
        message:
            'لن تُحفظ بصمات هذا الجهاز أثناء تعطيله.\n\n'
            '${d.locationName.isEmpty ? d.serialNumber : d.locationName}',
        confirmLabel: 'نعم، عطّل الجهاز',
        danger: true,
        icon: LucideIcons.pause,
      );
      if (!ok || !mounted) return;
    }

    setState(() => _busy.add(d.serialNumber));
    try {
      await _api.updateDevice(serialNumber: d.serialNumber, isActive: next);
      if (!mounted) return;
      showAppToast(context, next ? 'تم تفعيل الجهاز' : 'تم تعطيل الجهاز');
      await _load();
    } on ApiException catch (e) {
      if (mounted) _toastError(e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(d.serialNumber));
    }
  }

  void _toastError(String message) => showAppToast(
    context,
    message,
    icon: LucideIcons.circleAlert,
    iconColor: AppColors.red,
  );

  @override
  Widget build(BuildContext context) {
    final devices = _devices;
    final active = devices?.where((d) => d.isActive).length ?? 0;
    final disabled = (devices?.length ?? 0) - active;
    final unsynced = devices?.where((d) => d.lastSync == null).length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الأجهزة',
          badge: devices == null
              ? null
              : Pill.tone('${devices.length} أجهزة', BadgeTone.tint),
          actions: [
            AppButton(
              label: _refreshing ? 'جارٍ التحديث…' : 'تحديث',
              icon: LucideIcons.refreshCw,
              style: AppButtonStyle.outline,
              onPressed: _refreshing ? null : _load,
            ),
          ],
          cta: AppButton(
            label: 'إضافة جهاز',
            icon: LucideIcons.plus,
            style: AppButtonStyle.amber,
            onPressed: _add,
          ),
        ),
        const SizedBox(height: 24),
        if (devices == null)
          _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : const LoadingView()
        else ...[
          KpiGrid(
            children: [
              KpiTile(
                label: 'أجهزة مفعّلة إدارياً',
                value: '$active',
                icon: LucideIcons.wifi,
              ),
              KpiTile(
                label: 'أجهزة معطلة',
                value: '$disabled',
                icon: LucideIcons.pause,
              ),
              KpiTile(
                label: 'بدون مزامنة',
                value: '$unsynced',
                icon: LucideIcons.clock,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (devices.isEmpty)
            const EmptyView(
              message:
                  'لا توجد أجهزة مسجّلة. اضغط "إضافة جهاز" لتسجيل أول جهاز بصمة.',
              icon: LucideIcons.cpu,
            )
          else
            ResponsiveGrid(
              columns: const {0: 1, 700: 2, 1200: 3},
              gap: 20,
              children: [
                for (final d in devices)
                  DeviceCard(
                    device: d,
                    busy: _busy.contains(d.serialNumber),
                    onEditLocation: () => _editLocation(d),
                    onToggle: () => _toggle(d),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          const Text(
            'التفعيل حالة إدارية وليس اختبار اتصال لحظياً؛ «آخر مزامنة» هي القيمة المُرجعة من السيرفر.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
