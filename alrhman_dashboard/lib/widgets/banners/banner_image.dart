import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/api_exception.dart';
import '../../core/app_colors.dart';

class BannerImage extends StatelessWidget {
  const BannerImage({super.key, required this.image, this.fit = BoxFit.cover});
  final Future<Uint8List> image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surfaceMuted,
    child: FutureBuilder<Uint8List>(
      future: image,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error is ApiException ? error.message : 'تعذر عرض الصورة',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.memory(
          snapshot.data!,
          fit: fit,
          errorBuilder: (_, _, _) =>
              const Center(child: Icon(LucideIcons.imageOff)),
        );
      },
    ),
  );
}
