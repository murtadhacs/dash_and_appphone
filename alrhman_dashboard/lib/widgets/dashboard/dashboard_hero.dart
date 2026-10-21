import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../ui/hover.dart';

/// قسم الترحيب وبطاقات الإجراءات السريعة كما في Figma:
/// العنوان الكبير يميناً، ثم بطاقة «+» المنقطة، ثم خمس بطاقات ملوّنة طويلة.
class DashboardHero extends StatelessWidget {
  final VoidCallback onAddStudent, onGrantLeave, onAddSchedule, onAddBanner;
  final VoidCallback? onExport;

  const DashboardHero({
    super.key,
    required this.onAddStudent,
    required this.onGrantLeave,
    required this.onExport,
    required this.onAddSchedule,
    required this.onAddBanner,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _QuickCard(
        index: 1,
        label: 'إضافة طالب',
        hint: 'سجل طالباً جديداً',
        icon: LucideIcons.userPlus,
        background: AppColors.green,
        onTap: onAddStudent,
      ),
      _QuickCard(
        index: 2,
        label: 'منح إجازة',
        hint: 'إجازة رسمية لطالب',
        icon: LucideIcons.calendarX,
        background: AppColors.brand,
        onTap: onGrantLeave,
      ),
      _QuickCard(
        index: 3,
        label: 'تصدير الحضور',
        hint: 'ملف Excel لليوم',
        icon: LucideIcons.download,
        background: AppColors.amber,
        foreground: AppColors.text,
        onTap: onExport,
      ),
      _QuickCard(
        index: 4,
        label: 'إضافة جدول',
        hint: 'جدول أسبوعي لصف',
        icon: LucideIcons.calendar,
        background: AppColors.slate,
        onTap: onAddSchedule,
      ),
      _QuickCard(
        index: 5,
        label: 'إضافة بانر',
        hint: 'إعلان لتطبيق الأهل',
        icon: LucideIcons.image,
        background: AppColors.textSub,
        onTap: onAddBanner,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        if (w >= 1060) {
          return SizedBox(
            height: 196,
            child: Row(
              children: [
                const SizedBox(width: 300, child: _Intro()),
                const SizedBox(width: 28),
                _AddCard(onTap: onAddStudent),
                const SizedBox(width: 14),
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        }
        final columns = w >= 700 ? 3 : 2;
        final cardWidth = (w - (columns - 1) * 14) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Intro(),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final card in cards)
                  SizedBox(width: cardWidth, height: 176, child: card),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'إدارة المدرسة\nبكل سهولة',
          style: TextStyle(
            fontSize: 38,
            height: 1.3,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'تابع حضور الطلاب لحظياً، وأنجز المهام اليومية من الإجراءات السريعة دون التنقل بين الصفحات.',
          style: TextStyle(fontSize: 14, height: 1.7, color: AppColors.textSub),
        ),
      ],
    );
  }
}

/// بطاقة «+» المنقطة (مختصر إضافة طالب).
class _AddCard extends StatefulWidget {
  final VoidCallback onTap;
  const _AddCard({required this.onTap});

  @override
  State<_AddCard> createState() => _AddCardState();
}

class _AddCardState extends State<_AddCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'إضافة طالب',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            decoration: BoxDecoration(
              color: _hover ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: CustomPaint(
              painter: _DashPainter(
                color: _hover ? AppColors.brand : const Color(0xFFB9BECA),
              ),
              child: Center(
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: _hover ? .25 : 0,
                  child: Icon(
                    LucideIcons.plus,
                    size: 24,
                    color: _hover ? AppColors.brand : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.75),
          const Radius.circular(28),
        ),
      );
    for (final PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// بطاقة إجراء سريع: رقم ونقاط، مربع أيقونة، ثم العنوان والتلميح أسفلها.
class _QuickCard extends StatelessWidget {
  final int index;
  final String label;
  final String hint;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const _QuickCard({
    required this.index,
    required this.label,
    required this.hint,
    required this.icon,
    required this.background,
    required this.onTap,
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final soft = foreground.withValues(alpha: .85);
    return Opacity(
      opacity: onTap == null ? .55 : 1,
      child: HoverLift(
        lift: 8,
        scale: 1.02,
        borderRadius: BorderRadius.circular(28),
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        hoverShadow: [
          BoxShadow(
            color: background.withValues(alpha: .45),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x29142337),
                  blurRadius: 30,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '0$index',
                      style: TextStyle(fontSize: 12, color: soft),
                    ),
                    const Spacer(),
                    Icon(LucideIcons.ellipsisVertical, size: 18, color: soft),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: foreground == Colors.white
                        ? Colors.white.withValues(alpha: .22)
                        : AppColors.text.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Icon(icon, size: 22, color: foreground),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, height: 1.5, color: soft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
