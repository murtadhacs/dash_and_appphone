import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/admin_api.dart';
import '../api/api_exception.dart';
import '../api/app_services.dart';
import '../core/app_colors.dart';
import '../models/school_banner.dart';
import '../widgets/banners/banner_form_dialog.dart';
import '../widgets/banners/banner_image.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/pill.dart';
import '../widgets/layout/app_header.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/responsive_grid.dart';

class BannersScreen extends StatefulWidget {
  final bool openAddOnStart;
  final VoidCallback? onStartHandled;

  /// مفتاح «البنرات / الإشعارات الجماعية» من الشاشة الأم (اختياري).
  final Widget? tabs;
  const BannersScreen({
    super.key,
    this.openAddOnStart = false,
    this.onStartHandled,
    this.tabs,
  });
  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  List<SchoolBanner>? _banners;
  String? _error;
  bool _loading = false;
  bool _started = false;
  final _images = <int, Future<Uint8List>>{};
  final _busy = <int>{};
  AdminApi get _api => AppScope.of(context).api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
      if (widget.openAddOnStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onStartHandled?.call();
          _edit();
        });
      }
    }
  }

  Future<Uint8List> _image(SchoolBanner banner) =>
      _images.putIfAbsent(banner.id, () => _api.bannerImage(banner));

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final banners = await _api.banners();
      if (mounted) {
        setState(() {
          _banners = banners;
          _images.clear();
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([SchoolBanner? banner]) async {
    final saved = await BannerFormDialog.show(
      context,
      api: _api,
      editing: banner,
      image: banner == null ? null : _image(banner),
    );
    if (!saved || !mounted) return;
    showAppToast(context, 'تم حفظ البانر بنجاح');
    await _load(); // GET بعد رفع الصورة أو تعديلها، لتحديث القائمة والمعاينة.
  }

  Future<void> _delete(SchoolBanner banner) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف البانر',
      message:
          'سيتم حذف البانر وصورته نهائياً من تطبيق ولي الأمر. هل تريد المتابعة؟',
      confirmLabel: 'حذف',
      danger: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;
    await _action(banner, () async {
      await _api.deleteBanner(banner.id);
      if (mounted) showAppToast(context, 'تم حذف البانر');
      await _load();
    });
  }

  Future<void> _download(SchoolBanner banner) => _action(banner, () async {
    final bytes = await _image(banner);
    final extension = banner.hasUploadedImage
        ? banner.extension
        : bytes.length >= 8 && bytes[0] == 137 && bytes[1] == 80
        ? 'png'
        : bytes.length >= 12 && bytes[8] == 87 && bytes[9] == 69
        ? 'webp'
        : 'jpg';
    final saved = await FilePicker.saveFile(
      dialogTitle: 'تحميل صورة الإعلان',
      fileName: 'banner_${banner.id}.$extension',
      bytes: bytes,
      mimeType: extension == 'jpg' ? 'image/jpeg' : 'image/$extension',
      type: FileType.custom,
      allowedExtensions: [extension],
    );
    if (mounted && (kIsWeb || saved != null)) {
      showAppToast(context, 'تم تحميل الصورة');
    }
  });

  Future<void> _action(
    SchoolBanner banner,
    Future<void> Function() action,
  ) async {
    if (_busy.contains(banner.id)) return;
    setState(() => _busy.add(banner.id));
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showAppToast(
          context,
          e is ApiException ? e.message : 'تعذر تنفيذ العملية، حاول مرة أخرى',
          icon: Icons.error_outline,
          iconColor: AppColors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(banner.id));
    }
  }

  Future<void> _preview(SchoolBanner banner) => showDialog<void>(
    context: context,
    builder: (ctx) => AppDialog(
      icon: Icons.image_outlined,
      title: banner.title.isEmpty ? 'معاينة البانر' : banner.title,
      subtitle: 'كما يظهر في تطبيق ولي الأمر بنسبة 16:7',
      maxWidth: 860,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: BannerImage(image: _image(banner), fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 18),
          DialogActions(
            children: [
              AppButton(
                label: 'إغلاق',
                style: AppButtonStyle.outline,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final banners = _banners;
    final active = banners?.where((b) => b.isActive).length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'التواصل والإعلانات',
          cta: AppButton(
            label: 'إضافة بانر',
            icon: Icons.add_rounded,
            style: AppButtonStyle.amber,
            onPressed: _loading ? null : () => _edit(),
          ),
        ),
        if (widget.tabs != null) ...[
          const SizedBox(height: 24),
          Align(alignment: AlignmentDirectional.centerStart, child: widget.tabs),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Pill.tone('${banners?.length ?? 0} بنرات', BadgeTone.tint),
            Pill.tone('$active مفعّلة في تطبيق ولي الأمر', BadgeTone.ok),
            AppButton(
              label: _loading ? 'جارٍ التحديث…' : 'تحديث',
              icon: Icons.refresh_rounded,
              style: AppButtonStyle.outline,
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_error != null) ErrorView(message: _error!, onRetry: _load),
        if (banners == null && _error == null) const LoadingView(),
        if (banners != null && banners.isEmpty)
          const EmptyView(
            message: 'لا توجد إعلانات بعد. أضف أول بانر لتطبيق ولي الأمر.',
            icon: Icons.image_outlined,
          ),
        if (banners != null && banners.isNotEmpty)
          ResponsiveGrid(
            columns: const {0: 1, 700: 2, 1200: 3},
            gap: 20,
            children: [for (final banner in banners) _card(banner)],
          ),
      ],
    );
  }

  Widget _card(SchoolBanner banner) {
    final busy = _busy.contains(banner.id) || _loading;
    final size = banner.sizeBytes == null
        ? null
        : banner.sizeBytes! >= 1024 * 1024
        ? '${(banner.sizeBytes! / 1024 / 1024).toStringAsFixed(1)} MB'
        : '${(banner.sizeBytes! / 1024).ceil()} KB';
    return AppCard(
      hover: true,
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: BannerImage(image: _image(banner)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        banner.title.isEmpty ? 'بانر بدون عنوان' : banner.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Pill.tone(
                      banner.isActive ? 'مفعّل' : 'غير مفعّل',
                      banner.isActive ? BadgeTone.ok : BadgeTone.gray,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  size == null ? 'نسبة 16:7' : 'نسبة 16:7 · $size',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconActionButton(
                      icon: Icons.visibility_outlined,
                      tooltip: 'معاينة',
                      onPressed: busy ? null : () => _preview(banner),
                    ),
                    const SizedBox(width: 8),
                    IconActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'تعديل',
                      onPressed: busy ? null : () => _edit(banner),
                    ),
                    const SizedBox(width: 8),
                    IconActionButton(
                      icon: Icons.download_rounded,
                      tooltip: 'تحميل',
                      onPressed: busy ? null : () => _download(banner),
                    ),
                    const SizedBox(width: 8),
                    IconActionButton.danger(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'حذف',
                      onPressed: busy ? null : () => _delete(banner),
                    ),
                  ],
                ),
                if (_busy.contains(banner.id)) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 3),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
