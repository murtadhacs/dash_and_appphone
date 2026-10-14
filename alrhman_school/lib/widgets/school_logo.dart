import 'package:flutter/material.dart';

enum SchoolLogoSize { sm, md, lg, xl }

/// شعار المدرسة المعتمد، من الصورة التي أرسلها المستخدم.
class SchoolLogo extends StatelessWidget {
  const SchoolLogo({
    super.key,
    this.size = SchoolLogoSize.md,
    this.withContainer = true,
  });

  static const asset = 'assets/images/school_logo.png';
  final SchoolLogoSize size;
  final bool withContainer;

  double get _size => switch (size) {
    SchoolLogoSize.sm => 40,
    SchoolLogoSize.md => 56,
    SchoolLogoSize.lg => 112,
    SchoolLogoSize.xl => 128,
  };

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: _size,
      height: _size,
      fit: BoxFit.contain,
      semanticLabel: 'شعار مدرسة الرحمن الابتدائية',
    );
    if (!withContainer) return image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_size / 4),
      child: image,
    );
  }
}
