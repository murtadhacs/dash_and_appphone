import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// البطاقة البيضاء العائمة (ظل ناعم بلا حد) المستخدمة في كل الشاشات.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final bool clip;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = AppColors.surface,
    this.radius = AppRadius.card,
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.card,
      ),
      padding: padding,
      child: child,
    );
  }
}
