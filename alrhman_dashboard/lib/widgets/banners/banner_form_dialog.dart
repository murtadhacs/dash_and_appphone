import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/admin_api.dart';
import '../../api/api_exception.dart';
import '../../core/app_colors.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';
import '../common/app_text_field.dart';
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
      setState(() => _error = 'ارفع صورة البانر أولاً');
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
    child: AppDialog(
      icon: LucideIcons.image,
      title: widget.editing == null ? 'إضافة بانر' : 'تعديل البانر',
      subtitle: 'يظهر في تطبيق ولي الأمر بنسبة 16:7',
      maxWidth: 580,
      onClose: _busy ? () {} : () => Navigator.pop(context, false),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: _bytes != null
                    ? Image.memory(_bytes!, fit: BoxFit.cover)
                    : widget.image != null
                    ? BannerImage(image: widget.image!)
                    : const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.slate],
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.imagePlus,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppButton(
                  label: _picking
                      ? 'جارٍ قراءة الصورة…'
                      : (_bytes == null && widget.image == null
                            ? 'رفع الصورة'
                            : 'استبدال الصورة'),
                  icon: LucideIcons.upload,
                  style: AppButtonStyle.outline,
                  small: true,
                  onPressed: _busy ? null : _pick,
                ),
                Text(
                  '${_name == null ? '' : '$_name · '}JPG أو PNG أو WebP · حتى 2 MB',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ValueListenableBuilder(
              valueListenable: _title,
              builder: (_, v, _) => FieldLabel(
                'عنوان البانر',
                hint: '(${v.text.runes.length}/255)',
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _title,
              enabled: !_busy,
              maxLength: 255,
              style: const TextStyle(fontSize: 14),
              decoration: appInputDecoration(
                hint: 'مثال: بداية الفصل الدراسي الثاني',
              ).copyWith(counterText: ''),
              validator: (value) => (value?.trim().runes.length ?? 0) > 255
                  ? 'الحد الأقصى 255 حرفاً'
                  : null,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عرض في تطبيق ولي الأمر',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'يمكن إيقافه دون حذف البانر',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _active,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _active = v),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              DialogNote(_error!, tone: NoteTone.bad),
            ],
            const SizedBox(height: 20),
            DialogActions(
              children: [
                AppButton(
                  label: 'إلغاء',
                  style: AppButtonStyle.outline,
                  onPressed: _busy ? null : () => Navigator.pop(context, false),
                ),
                AppButton(
                  label: _saving ? 'جارٍ الحفظ…' : 'حفظ البانر',
                  icon: LucideIcons.check,
                  style: AppButtonStyle.amber,
                  onPressed: _busy ? null : _save,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
