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
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(AppRadius.control),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.amber, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    ),
  );
}
