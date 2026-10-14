import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/dashboard_stats.dart';
import '../common/app_card.dart';
import '../common/pill.dart';
import '../common/section_title.dart';

/// بطاقة تحليل الحضور اللحظي بمخطط دائري (من أرقام اليوم الفعلية).
class AttendanceDonutCard extends StatelessWidget {
  final DashboardStats stats;
  const AttendanceDonutCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalStudents;
    double f(int v) => total == 0 ? 0 : v / total;
    String pct(int v) => '(${stats.percentOf(v).toStringAsFixed(1)}%)';

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  icon: Icons.auto_awesome_outlined,
                  title: 'تحليل الحضور اللحظي',
                  subtitle: 'توزيع الطلاب لليوم الدراسي الحالي',
                ),
              ),
              const SizedBox(width: 8),
              Pill(
                label: 'إجمالي: $total طالب',
                background: AppColors.surfaceMuted,
                foreground: AppColors.textMuted,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 224,
            height: 224,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(224),
                  painter: _DonutPainter(
                    segments: [
                      _Segment(f(stats.presentToday), AppColors.green),
                      _Segment(f(stats.absentToday), AppColors.red),
                      _Segment(f(stats.excusedToday), AppColors.warn),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.percentOf(stats.presentToday).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'نسبة الحضور اليوم',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _LegendRow(
                  color: AppColors.green,
                  label: 'حاضرون',
                  count: '${stats.presentToday} طالب',
                  countColor: AppColors.text,
                  percent: pct(stats.presentToday),
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  color: AppColors.red,
                  label: 'غائبون',
                  count: '${stats.absentToday} طالب',
                  countColor: AppColors.red,
                  percent: pct(stats.absentToday),
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  color: AppColors.warn,
                  label: 'مجازون',
                  count: '${stats.excusedToday} طالب',
                  countColor: AppColors.warnDeep,
                  percent: pct(stats.excusedToday),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String count;
  final Color countColor;
  final String percent;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.countColor,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: countColor,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            percent,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
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
  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 17.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2 - 4,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surfaceMuted;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    var start = -math.pi / 2;
    for (final s in segments) {
      if (s.fraction <= 0) continue;
      final sweep = math.pi * 2 * s.fraction;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = s.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}
