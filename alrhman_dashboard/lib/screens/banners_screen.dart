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
import '../widgets/common/app_toast.dart';
import '../widgets/common/async_states.dart';
import '../widgets/common/responsive_grid.dart';

class BannersScreen extends StatefulWidget {
  final bool openAddOnStart;
  final VoidCallback? onStartHandled;
  const BannersScreen({
    super.key,
    this.openAddOnStart = false,
    this.onStartHandled,
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
    showAppToast(context, 'تم حفظ الإعلان بنجاح');
    await _load(); // GET بعد رفع الصورة أو تعديلها، لتحديث القائمة والمعاينة.
  }

  Future<void> _delete(SchoolBanner banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text(
          'سيتم حذف الإعلان وصورته نهائياً. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _action(banner, () async {
      await _api.deleteBanner(banner.id);
      if (mounted) showAppToast(context, 'تم حذف الإعلان');
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
    builder: (ctx) => AlertDialog(
      title: Text(banner.title.isEmpty ? 'معاينة الإعلان' : banner.title),
      content: SizedBox(
        width: 800,
        child: AspectRatio(
          aspectRatio: 16 / 7,
          child: BannerImage(image: _image(banner), fit: BoxFit.contain),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final banners = _banners;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'الإعلانات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'أضف صور إعلانات المدرسة لتظهر في الصفحة الرئيسية لتطبيق ولي الأمر.',
          style: TextStyle(color: AppColors.textSub),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AppButton(
              label: 'إضافة إعلان',
              icon: Icons.add_photo_alternate_outlined,
              onPressed: _loading ? null : () => _edit(),
            ),
            AppButton(
              label: _loading ? 'جارٍ التحديث…' : 'تحديث',
              icon: Icons.refresh,
              style: AppButtonStyle.outline,
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          color: AppColors.surfaceMuted,
          child: Text(
            'الإعلانات للعرض فقط • ${banners?.length ?? 0} إعلان • '
            '${banners?.where((b) => b.isActive).length ?? 0} ظاهر لولي الأمر',
            style: const TextStyle(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        if (_error != null) ErrorView(message: _error!, onRetry: _load),
        if (banners == null && _error == null) const LoadingView(),
        if (banners != null && banners.isEmpty)
          const EmptyView(
            message: 'لا توجد إعلانات بعد. أضف أول صورة لإعلانات المدرسة.',
            icon: Icons.photo_library_outlined,
          ),
        if (banners != null && banners.isNotEmpty)
          ResponsiveGrid(
            columns: const {0: 1, 768: 2, 1280: 3},
            gap: 20,
            children: [for (final banner in banners) _card(banner)],
          ),
      ],
    );
  }

  Widget _card(SchoolBanner banner) {
    final busy = _busy.contains(banner.id) || _loading;
    return AppCard(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title.isEmpty ? 'إعلان بدون عنوان' : banner.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  banner.isActive ? 'ظاهر لولي الأمر' : 'مخفي',
                  style: TextStyle(
                    color: banner.isActive
                        ? AppColors.greenDark
                        : AppColors.textMuted,
                  ),
                ),
                if (banner.sizeBytes != null)
                  Text(
                    '${(banner.sizeBytes! / 1024).ceil()} كيلوبايت',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: busy ? null : () => _preview(banner),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('معاينة'),
                    ),
                    TextButton.icon(
                      onPressed: busy ? null : () => _edit(banner),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('تعديل'),
                    ),
                    TextButton.icon(
                      onPressed: busy ? null : () => _download(banner),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('تحميل'),
                    ),
                    TextButton.icon(
                      onPressed: busy ? null : () => _delete(banner),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.red,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('حذف'),
                    ),
                  ],
                ),
                if (_busy.contains(banner.id)) const LinearProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
