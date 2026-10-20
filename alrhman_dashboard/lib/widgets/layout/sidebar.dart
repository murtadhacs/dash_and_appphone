import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/assets.dart';
import '../../core/responsive.dart';
import '../../models/navigation_tab.dart';
import 'app_header.dart' show supportPhone;

class _NavItem {
  final NavigationTab tab;
  final String label;
  final IconData icon;
  const _NavItem(this.tab, this.label, this.icon);
}

const _navItems = [
  _NavItem(NavigationTab.dashboard, 'لوحة التحكم', Icons.dashboard_outlined),
  _NavItem(
    NavigationTab.students,
    'الطلاب وأولياء الأمور',
    Icons.school_outlined,
  ),
  _NavItem(
    NavigationTab.attendance,
    'الحضور والاجازات',
    Icons.event_available_outlined,
  ),
  _NavItem(NavigationTab.devices, 'الأجهزة وبوابات الحضور', Icons.fingerprint),
  _NavItem(
    NavigationTab.schedule,
    'الجدول الدراسي',
    Icons.calendar_view_week_outlined,
  ),
  _NavItem(
    NavigationTab.banners,
    'الإعلانات والإشعارات',
    Icons.photo_library_outlined,
  ),
  _NavItem(NavigationTab.settings, 'الإعدادات العامة', Icons.settings_outlined),
  _NavItem(NavigationTab.activityLog, 'سجل النشاط', Icons.history_outlined),
];

/// الشريط الجانبي: كحلي عائم داخل الإطار العام، ثابت على الشاشات الكبيرة
/// وداخل Drawer على الصغيرة. يقع على يمين الشاشة تلقائياً بحكم اتجاه RTL.
class Sidebar extends StatelessWidget {
  final NavigationTab currentTab;
  final ValueChanged<NavigationTab> onSelectTab;
  final String? username;

  const Sidebar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Breakpoints.sidebarWidth,
      color: AppColors.primary,
      child: LayoutBuilder(
        // على الشاشات القصيرة يتمرّر الشريط كاملاً بدل قصّ القائمة.
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 20, 18, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  _brand(),
                  const SizedBox(height: 22),
                  _Profile(username: username),
                  const SizedBox(height: 22),
                  for (final item in _navItems)
                    _NavTile(
                      item: item,
                      active: item.tab == currentTab,
                      onTap: () => onSelectTab(item.tab),
                    ),
                  const Spacer(),
                  const SizedBox(height: 12),
                  const _SupportCard(),
                  const SizedBox(height: 10),
                  const Text(
                    'الرحمن الابتدائية • الإصدار 1.0',
                    style: TextStyle(fontSize: 11, color: Color(0xB3FFFFFF)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Image.asset(appLogoAsset, fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الرحمن الابتدائية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              Text(
                'نظام الإدارة المدرسية',
                style: TextStyle(fontSize: 11, color: Color(0xB3FFFFFF)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Profile extends StatelessWidget {
  final String? username;
  const _Profile({required this.username});

  @override
  Widget build(BuildContext context) {
    final name = (username == null || username!.isEmpty) ? 'المدير' : username!;
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.amber,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x2EFFFFFF), width: 4),
          ),
          child: Text(
            name.characters.first,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDeep,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Text(
          'مدير النظام',
          style: TextStyle(fontSize: 12, color: Color(0xB3FFFFFF)),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.text : const Color(0xB8FFFFFF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.control),
          boxShadow: active ? AppShadows.amberGlow : null,
        ),
        child: Material(
          color: active ? AppColors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.control),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            hoverColor: const Color(0x14FFFFFF),
            onTap: onTap,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(item.icon, size: 20, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.bold : FontWeight.w500,
                        color: fg,
                      ),
                    ),
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

/// بطاقة الدعم الفني بحد متقطع (ثابتة في أسفل الشريط الجانبي).
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: const Color(0x59FFFFFF),
        radius: AppRadius.card,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          children: [
            const Text(
              'الدعم الفني',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'لأي استفسار تواصل على الرقم',
              style: TextStyle(fontSize: 11, color: Color(0xB3FFFFFF)),
            ),
            const SizedBox(height: 6),
            const SelectableText(
              supportPhone,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
