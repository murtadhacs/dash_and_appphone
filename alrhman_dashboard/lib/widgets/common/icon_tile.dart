import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// أيقونة مسطحة بلون العلامة الموحد وبلا خلفية (تتكرر في العناوين والنوافذ).
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;

  const IconTile({super.key, required this.icon, this.size = 22});

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: AppColors.brand);
}
