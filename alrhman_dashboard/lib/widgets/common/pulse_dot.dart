import 'package:flutter/material.dart';

/// نقطة نابضة (مؤشر "مباشر").
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;

  /// عند true تظهر حلقة تتوسع (ping)، وإلا يتغير الشفاف فقط (pulse).
  final bool ping;

  const PulseDot({
    super.key,
    required this.color,
    this.size = 8,
    this.ping = false,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;
          if (widget.ping) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (1 - t) * 0.75,
                  child: Transform.scale(
                    scale: 1 + t,
                    child: _dot(widget.color),
                  ),
                ),
                _dot(widget.color),
              ],
            );
          }
          // pulse: 1 → 0.5 → 1
          final o = 1 - (t < 0.5 ? t : 1 - t);
          return Opacity(opacity: o, child: _dot(widget.color));
        },
      ),
    );
  }

  Widget _dot(Color c) => DecoratedBox(
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    child: const SizedBox.expand(),
  );
}

/// أيقونة تدور أثناء التحميل.
class SpinningIcon extends StatefulWidget {
  final IconData icon;
  final bool spinning;
  final Color color;
  final double size;

  const SpinningIcon({
    super.key,
    required this.icon,
    required this.spinning,
    required this.color,
    this.size = 16,
  });

  @override
  State<SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant SpinningIcon old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.spinning && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
