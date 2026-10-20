import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../common/pill.dart';

/// قسم الترحيب وبطاقات الإجراءات السريعة في أعلى لوحة التحكم.
///
/// في RTL يقع النص الترحيبي على اليمين وتمتد بطاقات الإجراءات نحو اليسار.
class DashboardHero extends StatelessWidget {
  final String dayLabel;
  final VoidCallback onAddStudent, onGrantLeave, onAddSchedule, onAddBanner;
  final VoidCallback? onExport;

  const DashboardHero({
    super.key,
    required this.dayLabel,
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
        label: 'تسجيل طالب',
        hint: 'سجّل طالباً جديداً',
        icon: Icons.person_add_alt,
        background: AppColors.green,
        onTap: onAddStudent,
      ),
      _QuickCard(
        index: 2,
        label: 'تسجيل إجازة',
        hint: 'إجازة رسمية لطالب',
        icon: Icons.event_busy_outlined,
        background: AppColors.brand,
        onTap: onGrantLeave,
      ),
      _QuickCard(
        index: 3,
        label: 'تصدير كشف اليوم',
        hint: 'ملف Excel للحضور',
        icon: Icons.download_outlined,
        background: AppColors.amber,
        foreground: AppColors.text,
        onTap: onExport,
      ),
      _QuickCard(
        index: 4,
        label: 'إضافة جدول سريع',
        hint: 'جدول أسبوعي لصف',
        icon: Icons.calendar_month_outlined,
        background: const Color(0xFF425AA6),
        onTap: onAddSchedule,
      ),
      _QuickCard(
        index: 5,
        label: 'إضافة بنر',
        hint: 'إعلان لتطبيق ولي الأمر',
        icon: Icons.add_photo_alternate_outlined,
        background: AppColors.textSub,
        onTap: onAddBanner,
      ),
    ];

    final intro = _Intro(dayLabel: dayLabel);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 300, child: intro),
              const SizedBox(width: 28),
              Expanded(
                child: SizedBox(
                  height: 196,
                  child: Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 14),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        final columns = w >= 640 ? 3 : 2;
        final cardWidth = (w - (columns - 1) * 14) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            intro,
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final c in cards)
                  SizedBox(width: cardWidth, height: 172, child: c),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Intro extends StatelessWidget {
  final String dayLabel;
  const _Intro({required this.dayLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Pill(
          label: '$dayLabel • ${BaghdadTime.apiDate(BaghdadTime.today())}',
          background: AppColors.accentSoft,
          foreground: AppColors.brand,
        ),
        const SizedBox(height: 12),
        const Text(
          'إدارة المدرسة\nبكل سهولة',
          style: TextStyle(
            fontSize: 34,
            height: 1.4,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'تابع حضور الطلاب لحظياً، وأنجز المهام اليومية من الإجراءات السريعة دون التنقل بين الصفحات.',
          style: TextStyle(fontSize: 13, height: 1.8, color: AppColors.textSub),
        ),
      ],
    );
  }
}

/// بطاقة إجراء سريع بألوان التصميم (رقم، قائمة نقاط، أيقونة، عنوان وتلميح).
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
    final soft = foreground.withValues(alpha: 0.8);
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29142337),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      Icon(Icons.more_vert, size: 18, color: soft),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: 0.2),
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
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                      color: foreground,
                    ),
                  ),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: soft),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
