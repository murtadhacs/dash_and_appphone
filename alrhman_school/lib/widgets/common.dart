import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Minimal tap surface: no ripple, click cursor on desktop/web —
/// equivalent to a plain `<button>` / `onClick` div in the original.
class Tap extends StatelessWidget {
  const Tap({super.key, required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Hides scrollbars (`no-scrollbar`) and removes the Android glow.
class NoScrollbar extends StatelessWidget {
  const NoScrollbar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false, overscroll: false),
      child: child,
    );
  }
}

/// Top inset of every main tab page: the design reserves 40px (`pt-10`)
/// for the notch; on devices with a taller status bar we honour that instead.
double pageTopInset(BuildContext context) =>
    math.max(MediaQuery.paddingOf(context).top, 40);

/// Bottom inset of the floating nav bar: `bottom-4` (16px) in the design,
/// pushed up on devices with a home-indicator inset.
double navBottomInset(BuildContext context) =>
    math.max(MediaQuery.paddingOf(context).bottom + 4, 16);

/// Scrollable body used by every tab page:
/// `flex-1 overflow-y-auto no-scrollbar pt-10 pb-20 bg-[#F8F9FC]`.
class TabPageScroll extends StatelessWidget {
  const TabPageScroll({
    super.key,
    required this.children,
    this.horizontalPadding = 0,
    this.onRefresh,
  });

  final List<Widget> children;
  final double horizontalPadding;

  /// عند تمريره: السحب للأسفل يحدّث البيانات.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: NoScrollbar(
        child: _maybeRefresh(
          SingleChildScrollView(
            physics: onRefresh == null
                ? null
                : const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: pageTopInset(context),
              bottom: 80 + (navBottomInset(context) - 16),
              left: horizontalPadding,
              right: horizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _maybeRefresh(Widget child) {
    final refresh = onRefresh;
    if (refresh == null) return child;
    return RefreshIndicator(
      color: AppColors.brandPurple,
      onRefresh: refresh,
      child: child,
    );
  }
}

/// Tailwind `animate-pulse`: opacity 1 → 0.5 → 1 over 2s.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});

  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 0.5), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.5, end: 1), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// Tailwind `animate-ping`: a copy of the dot scales to 2× while fading out,
/// every 1s, on top of the static dot.
class PingDot extends StatefulWidget {
  const PingDot({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<PingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeOut.transform(_controller.value);
              return Opacity(
                opacity: (1 - t).clamp(0, 1),
                child: Transform.scale(scale: 1 + t, child: child),
              );
            },
            child: dot,
          ),
          dot,
        ],
      ),
    );
  }
}

/// Tailwind `animate-spin`: one full rotation per second, linear.
class Spin extends StatefulWidget {
  const Spin({super.key, required this.child});

  final Widget child;

  @override
  State<Spin> createState() => _SpinState();
}

class _SpinState extends State<Spin> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(turns: _controller, child: widget.child);
  }
}

/// Soft purple glow behind the logo:
/// `absolute inset-0 rounded-3xl bg-[#A91FAF]/15 blur-xl`.
class LogoGlow extends StatelessWidget {
  const LogoGlow({super.key, this.size = 112});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.15),
            blurRadius: 40,
          ),
        ],
      ),
    );
  }
}
