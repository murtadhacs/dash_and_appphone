import 'package:flutter/material.dart';

/// حركة خفيفة عند مرور الفأرة: رفع العنصر وتكبيره قليلاً مع ظل أوضح.
///
/// تُعطَّل تلقائياً عند تفعيل "تقليل الحركة" في النظام، أو حين [enabled] = false.
class HoverLift extends StatefulWidget {
  final Widget child;
  final double lift;
  final double scale;
  final bool enabled;
  final BorderRadius? borderRadius;

  /// ظل يظهر أثناء المرور (للبطاقات). null = بلا ظل إضافي.
  final List<BoxShadow>? hoverShadow;
  final MouseCursor cursor;

  const HoverLift({
    super.key,
    required this.child,
    this.lift = 4,
    this.scale = 1,
    this.enabled = true,
    this.borderRadius,
    this.hoverShadow,
    this.cursor = MouseCursor.defer,
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final active = _hover && widget.enabled && !reduce;
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(0.0, active ? -widget.lift : 0.0, 0.0, 1.0)
          ..scaleByDouble(
            active ? widget.scale : 1.0,
            active ? widget.scale : 1.0,
            1.0,
            1.0,
          ),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: active ? widget.hoverShadow : null,
        ),
        child: widget.child,
      ),
    );
  }
}

/// ظل البطاقة عند المرور: أعمق قليلاً من ظل البطاقة العادي.
const hoverCardShadow = [
  BoxShadow(color: Color(0x24142337), blurRadius: 40, offset: Offset(0, 22)),
];
