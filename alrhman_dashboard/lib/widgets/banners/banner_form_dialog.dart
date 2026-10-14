import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api/admin_api.dart';
import '../../api/api_exception.dart';
import '../../core/app_colors.dart';
import '../../models/school_banner.dart';
import 'banner_image.dart';

class BannerFormDialog extends StatefulWidget {
  const BannerFormDialog({
    super.key,
    required this.api,
    this.editing,
    this.image,
  });
  final AdminApi api;
  final SchoolBanner? editing;
  final Future<Uint8List>? image;

  static Future<bool> show(
    BuildContext context, {
    required AdminApi api,
    SchoolBanner? editing,
    Future<Uint8List>? image,
  }) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            BannerFormDialog(api: api, editing: editing, image: image),
      ) ??
      false;

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.editing?.title ?? '');
  late bool _active = widget.editing?.isActive ?? true;
  Uint8List? _bytes;
  String? _name;
  String? _error;
  bool _saving = false;
  bool _picking = false;
  bool get _busy => _saving || _picking;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result.isEmpty || !mounted) return;
      final file = result.single;
      final length = await file.length();
      if (length != null && length > 2097152) {
        throw const FormatException('حجم الصورة يجب ألا يتجاوز 2 ميجابايت');
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 2097152) {
        throw const FormatException(
          'اختر صورة غير فارغة بحجم لا يتجاوز 2 ميجابايت',
        );
      }
      bool starts(List<int> signature, [int offset = 0]) =>
          bytes.length >= offset + signature.length &&
          List.generate(
            signature.length,
            (i) => bytes[offset + i] == signature[i],
          ).every((v) => v);
      final supported =
          starts([0xff, 0xd8, 0xff]) ||
          starts([137, 80, 78, 71, 13, 10, 26, 10]) ||
          (starts([82, 73, 70, 70]) && starts([87, 69, 66, 80], 8));
      if (!supported) {
        throw const FormatException('الصيغ المسموحة هي JPEG وPNG وWebP');
      }
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 800);
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _name = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : 'تعذر قراءة الصورة، اختر ملف صورة صالحاً',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (widget.editing == null && _bytes == null) {
      setState(() => _error = 'ارفع صورة الإعلان أولاً');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.saveBanner(
        id: widget.editing?.id,
        title: _title.text,
        isActive: _active,
        image: _bytes,
        fileName: _name,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(widget.editing == null ? 'إضافة إعلان جديد' : 'تعديل الإعلان'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: _bytes != null
                        ? Image.memory(_bytes!, fit: BoxFit.cover)
                        : widget.image != null
                        ? BannerImage(image: widget.image!)
                        : const ColoredBox(
                            color: AppColors.surfaceMuted,
                            child: Center(
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.upload_outlined),
                  label: Text(
                    _picking
                        ? 'جارٍ قراءة الصورة…'
                        : _name ?? 'رفع / استبدال الصورة',
                  ),
                ),
                const Text(
                  'JPEG، PNG، WebP • حتى 2 ميجابايت • يُفضّل مقاس بنسبة 16:7',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _title,
                  enabled: !_busy,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الإعلان (اختياري)',
                  ),
                  validator: (value) => (value?.trim().runes.length ?? 0) > 255
                      ? 'الحد الأقصى 255 حرفاً'
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('عرض في تطبيق ولي الأمر'),
                  subtitle: const Text('يمكن إخفاء الإعلان مع الاحتفاظ بالصورة'),
                  value: _active,
                  onChanged: _busy ? null : (v) => setState(() => _active = v),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_saving ? 'جارٍ الحفظ…' : 'حفظ الإعلان'),
        ),
      ],
    ),
  );
}
