import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// محتوى الهوية دون لوحة أو خلفية منفصلة عن صفحة الدخول.
class LoginBrandPanel extends StatelessWidget {
  final bool compact;
  const LoginBrandPanel({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 24, height: 2, color: AppColors.amber),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'منظومة القيادة المدرسية',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'كل تفاصيل مدرستك،',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 28 : 40,
            height: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'في مكان واحد.',
          style: TextStyle(
            color: AppColors.amber,
            fontSize: compact ? 28 : 40,
            height: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'مساحة عمل متكاملة تمنحك رؤية أوضح ليومك المدرسي، وتساعدك على التركيز على ما يهم: طلابك.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.9),
        ),
        if (!compact) ...[
          const SizedBox(height: 32),
          const _SchoolIllustration(),
        ],
        const SizedBox(height: 28),
        Wrap(
          spacing: 20,
          runSpacing: 14,
          children: const [
            _Feature(Icons.fact_check_outlined, 'متابعة الحضور'),
            _Feature(Icons.people_outline_rounded, 'إدارة الطلاب'),
            _Feature(Icons.fingerprint_rounded, 'أجهزة البصمة'),
          ],
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.amber, size: 18),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );
}

class _SchoolIllustration extends StatelessWidget {
  const _SchoolIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 220,
    child: Center(
      child: SizedBox(
        width: 360,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .09)),
              ),
            ),
            Container(
              width: 158,
              height: 158,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .04),
                border: Border.all(color: Colors.white.withValues(alpha: .12)),
              ),
            ),
            Transform.rotate(
              angle: -.08,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: .2)),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 62,
                  color: AppColors.amber,
                ),
              ),
            ),
            PositionedDirectional(
              top: 18,
              start: 24,
              child: _badge(Icons.check_circle_outline, 'حضور ومتابعة'),
            ),
            PositionedDirectional(
              bottom: 20,
              end: 12,
              child: _badge(Icons.auto_stories_outlined, 'بيئة تعليمية أفضل'),
            ),
            const PositionedDirectional(
              top: 44,
              end: 52,
              child: Icon(Icons.add, color: AppColors.amber, size: 18),
            ),
            PositionedDirectional(
              bottom: 42,
              start: 70,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _badge(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppColors.brand,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.amber, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    ),
  );
}
