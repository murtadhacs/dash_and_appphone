import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/dashboard_stats.dart';
import '../common/app_card.dart';
import '../common/pill.dart';
import '../ui/hover.dart';

/// بطاقة «توزيع الحضور اليوم» كما في Figma: حلقة بثلاثة ألوان ونسبة الحضور
/// في الوسط، وتحتها ثلاث بطاقات صغيرة (حضور، غياب، إجازة).
class AttendanceDonutCard extends StatelessWidget {
  final DashboardStats stats;
  const AttendanceDonutCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalStudents;
    double f(int v) => total == 0 ? 0 : v / total;
    String pct(int v) => '${stats.percentOf(v).toStringAsFixed(1)}%';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            'توزيع الحضور اليوم',
            trailing: [Pill.tone('$total طالب', BadgeTone.gray)],
          ),
          const SizedBox(height: 18),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(200),
                      painter: _DonutPainter(
                        progress: t,
                        segments: [
                          _Segment(f(stats.presentToday), AppColors.green),
                          _Segment(f(stats.absentToday), AppColors.red),
                          _Segment(f(stats.excusedToday), AppColors.amber),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pct(stats.presentToday),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 34,
                            height: 1.3,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const Text(
                          'نسبة الحضور',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _LegendTile(
                label: 'حضور',
                color: AppColors.green,
                value: stats.presentToday,
                percent: pct(stats.presentToday),
              ),
              const SizedBox(width: 10),
              _LegendTile(
                label: 'غياب',
                color: AppColors.red,
                value: stats.absentToday,
                percent: pct(stats.absentToday),
              ),
              const SizedBox(width: 10),
              _LegendTile(
                label: 'إجازة',
                color: AppColors.amber,
                value: stats.excusedToday,
                percent: pct(stats.excusedToday),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendTile extends StatelessWidget {
  final String label;
  final Color color;
  final int value;
  final String percent;

  const _LegendTile({
    required this.label,
    required this.color,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: HoverLift(
        lift: 3,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.45,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Text(
                percent,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment {
  final double fraction;
  final Color color;
  const _Segment(this.fraction, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_Segment> segments;
  final double progress;
  _DonutPainter({required this.segments, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 28.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.canvas,
    );

    const gap = 0.035;
    final split = segments.where((x) => x.fraction > 0).length > 1;
    var start = -math.pi / 2;
    for (final s in segments) {
      if (s.fraction <= 0) continue;
      final sweep = math.pi * 2 * s.fraction * progress;
      canvas.drawArc(
        rect,
        start + (split ? gap / 2 : 0),
        math.max(0, sweep - (split ? gap : 0)),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = s.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.progress != progress;
}
