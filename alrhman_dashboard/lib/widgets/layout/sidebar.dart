import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../../core/assets.dart';
import '../../core/responsive.dart';
import '../../models/navigation_tab.dart';
import '../common/app_toast.dart';
import 'app_header.dart' show supportPhone;

class _NavItem {
  final NavigationTab tab;
  final String label;
  final IconData icon;
  const _NavItem(this.tab, this.label, this.icon);
}

const _navItems = [
  _NavItem(NavigationTab.dashboard, 'نظرة عامة', LucideIcons.layoutGrid),
  _NavItem(NavigationTab.students, 'الطلاب', LucideIcons.graduationCap),
  _NavItem(
    NavigationTab.attendance,
    'الحضور والإجازات',
    LucideIcons.clipboardCheck,
  ),
  _NavItem(NavigationTab.devices, 'الأجهزة', LucideIcons.cpu),
  _NavItem(NavigationTab.banners, 'التواصل والإعلانات', LucideIcons.megaphone),
  _NavItem(NavigationTab.schedule, 'الجداول الأسبوعية', LucideIcons.calendar),
  _NavItem(
    NavigationTab.settings,
    'إعدادات المدرسة',
    LucideIcons.slidersHorizontal,
  ),
  _NavItem(NavigationTab.activityLog, 'سجل النشاط', LucideIcons.fileText),
];

/// الشريط الجانبي الكحلي كما في Figma: الهوية، بطاقة المدير، القائمة مع
/// عنصرين فرعيين للتواصل، بطاقة الدعم الفني وحالة الخادم.
/// يقع يمين الشاشة تلقائياً بحكم اتجاه RTL.
class Sidebar extends StatelessWidget {
  final NavigationTab currentTab;
  final ValueChanged<NavigationTab> onSelectTab;
  final String? username;

  /// null = لم تُفحص بعد، true = الخادم يستجيب.
  final bool? serverOnline;

  const Sidebar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    this.username,
    this.serverOnline,
  });

  bool get _commsActive =>
      currentTab == NavigationTab.banners ||
      currentTab == NavigationTab.broadcasts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Breakpoints.sidebarWidth,
      color: AppColors.primary,
      child: LayoutBuilder(
        // على الشاشات القصيرة يتمرّر الشريط كاملاً بدل قصّ القائمة.
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 22, 16, 14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 36).clamp(0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Brand(),
                  const SizedBox(height: 26),
                  _Profile(username: username),
                  const SizedBox(height: 26),
                  for (final item in _navItems) ...[
                    _NavTile(
                      label: item.label,
                      icon: item.icon,
                      active: item.tab == NavigationTab.banners
                          ? _commsActive
                          : item.tab == currentTab,
                      onTap: () => onSelectTab(item.tab),
                    ),
                    if (item.tab == NavigationTab.banners)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 24,
                          top: 2,
                          bottom: 6,
                        ),
                        child: Column(
                          children: [
                            _SubTile(
                              label: 'البنرات',
                              dot: const Color(0xFF8FA7FE),
                              current: currentTab == NavigationTab.banners,
                              onTap: () => onSelectTab(NavigationTab.banners),
                            ),
                            _SubTile(
                              label: 'الإشعارات الجماعية',
                              dot: AppColors.green,
                              current: currentTab == NavigationTab.broadcasts,
                              onTap: () =>
                                  onSelectTab(NavigationTab.broadcasts),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const Spacer(),
                  const SizedBox(height: 16),
                  const _SupportCard(),
                  const SizedBox(height: 12),
                  _ServerStatus(online: serverOnline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(4),
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
                'مدرسة الرحمن',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'الابتدائية للبنين',
                style: TextStyle(fontSize: 12, color: Color(0xB3FFFFFF)),
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
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.amber,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x2EFFFFFF), width: 4),
          ),
          child: Text(
            name.characters.first,
            style: const TextStyle(
              fontSize: 34,
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
            fontSize: 15,
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

class _NavTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavTile({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final fg = active
        ? AppColors.text
        : (_hover ? Colors.white : const Color(0xB8FFFFFF));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.amber
                  : (_hover ? const Color(0x17FFFFFF) : Colors.transparent),
              borderRadius: BorderRadius.circular(AppRadius.control),
              boxShadow: active ? AppShadows.amberGlow : null,
            ),
            child: Row(
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  offset: _hover && !active
                      ? const Offset(-.12, 0)
                      : Offset.zero,
                  child: Icon(widget.icon, size: 20, color: fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
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
    );
  }
}

class _SubTile extends StatefulWidget {
  final String label;
  final Color dot;
  final bool current;
  final VoidCallback onTap;

  const _SubTile({
    required this.label,
    required this.dot,
    required this.current,
    required this.onTap,
  });

  @override
  State<_SubTile> createState() => _SubTileState();
}

class _SubTileState extends State<_SubTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final strong = widget.current || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          height: 34,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: strong ? 11 : 9,
                height: strong ? 11 : 9,
                decoration: BoxDecoration(
                  color: widget.current ? AppColors.amber : widget.dot,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.current
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: strong ? Colors.white : const Color(0xB8FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة الدعم الفني بحد متقطع (ثابتة في أسفل الشريط الجانبي).
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: supportPhone));
    if (context.mounted) showAppToast(context, 'تم نسخ رقم الدعم الفني');
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: const Color(0x59FFFFFF),
        radius: AppRadius.card,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              'للمساعدة اتصل بنا',
              style: TextStyle(fontSize: 11, color: Color(0xB3FFFFFF)),
            ),
            const SizedBox(height: 6),
            const SelectableText(
              '0774 907 8969',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _PhoneButton(onTap: () => _copy(context)),
          ],
        ),
      ),
    );
  }
}

class _PhoneButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PhoneButton({required this.onTap});

  @override
  State<_PhoneButton> createState() => _PhoneButtonState();
}

class _PhoneButtonState extends State<_PhoneButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'نسخ رقم الدعم',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            scale: _hover ? 1.12 : 1,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: _hover ? -0.04 : 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _hover ? AppColors.amber : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.phone,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServerStatus extends StatelessWidget {
  final bool? online;
  const _ServerStatus({required this.online});

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (online) {
      true => (AppColors.green, 'خادم المدرسة: متصل'),
      false => (AppColors.red, 'خادم المدرسة: غير متصل'),
      null => (const Color(0x99FFFFFF), 'خادم المدرسة: جارٍ الفحص'),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xBFFFFFFF)),
        ),
      ],
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
