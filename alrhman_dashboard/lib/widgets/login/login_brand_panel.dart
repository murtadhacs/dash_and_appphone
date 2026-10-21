import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../ui/hover.dart';

/// لوحة الهوية في صفحة الدخول كما في Figma: الشعار، عنوان كبير، وصف،
/// وثلاث ميزات بخلفية شفافة.
class LoginBrandPanel extends StatelessWidget {
  final bool compact;
  const LoginBrandPanel({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'لوحة إدارة\nمدرسة الرحمن',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 30 : 46,
            height: 1.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: const Text(
            'تابع الحضور والغياب لحظة بلحظة، وأدر الطلاب والجداول والإشعارات لأولياء الأمور من مكان واحد.',
            style: TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 16,
              height: 1.75,
            ),
          ),
        ),
        SizedBox(height: compact ? 24 : 40),
        const SizedBox(
          width: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Feature(LucideIcons.clipboardCheck, 'حضور لحظي عبر بطاقات RFID'),
              SizedBox(height: 12),
              _Feature(
                LucideIcons.megaphone,
                'إشعارات وبنرات لتطبيق ولي الأمر',
              ),
              SizedBox(height: 12),
              _Feature(LucideIcons.calendar, 'جداول أسبوعية لكل صف وشعبة'),
            ],
          ),
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
  Widget build(BuildContext context) => HoverLift(
    lift: 3,
    scale: 1.02,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );
}
