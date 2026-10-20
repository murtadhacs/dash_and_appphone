import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../ui/hover.dart';

/// البطاقة البيضاء العائمة (ظل ناعم بلا حد) المستخدمة في كل الشاشات.
/// مع [hover] ترتفع قليلاً ويقوى ظلها عند مرور الفأرة.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final bool clip;
  final bool hover;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = AppColors.surface,
    this.radius = AppRadius.card,
    this.clip = false,
    this.hover = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.card,
      ),
      padding: padding,
      child: child,
    );
    if (!hover) return card;
    return HoverLift(
      borderRadius: BorderRadius.circular(radius),
      hoverShadow: hoverCardShadow,
      child: card,
    );
  }
}

/// عنوان بطاقة: نص 18 غامق + عناصر اختيارية بعده.
class CardTitle extends StatelessWidget {
  final String title;
  final List<Widget> trailing;
  final List<Widget> afterTitle;

  const CardTitle(
    this.title, {
    super.key,
    this.trailing = const [],
    this.afterTitle = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                height: 1.45,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            for (final w in afterTitle) ...[const SizedBox(width: 10), w],
          ],
        ),
        if (trailing.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < trailing.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                trailing[i],
              ],
            ],
          ),
      ],
    );
  }
}
