import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../../core/responsive.dart';

/// رقم دعم النظام الظاهر في بطاقة الدعم الفني بالشريط الجانبي.
const supportPhone = '07749078969';

/// الشريط العلوي داخل اللوحة العائمة: عنوان الصفحة، توقيت بغداد، وتسجيل الخروج.
/// في RTL يبدأ العنوان من اليمين وتنتهي الأزرار عند اليسار.
class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback onToggleSidebar;
  final VoidCallback onLogout;

  const AppHeader({
    super.key,
    required this.title,
    required this.onToggleSidebar,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = Breakpoints.isDesktop(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        width >= Breakpoints.md ? 32 : 16,
        24,
        width >= Breakpoints.md ? 32 : 16,
        0,
      ),
      child: Row(
        children: [
          if (!desktop) ...[
            _SquareButton(
              tooltip: 'القائمة',
              icon: Icons.menu,
              onTap: onToggleSidebar,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                height: 1.4,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ),
          if (width >= Breakpoints.sm) ...[
            const _BaghdadClock(),
            const SizedBox(width: 12),
          ],
          _SquareButton(
            tooltip: 'تسجيل الخروج',
            icon: Icons.logout,
            onTap: onLogout,
            hoverColor: AppColors.redSoft,
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;

  const _SquareButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.hoverColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          hoverColor: hoverColor,
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 20, color: AppColors.textSub),
          ),
        ),
      ),
    );
  }
}

/// ساعة بتوقيت بغداد تُحدَّث كل نصف دقيقة.
class _BaghdadClock extends StatefulWidget {
  const _BaghdadClock();

  @override
  State<_BaghdadClock> createState() => _BaghdadClockState();
}

class _BaghdadClockState extends State<_BaghdadClock> {
  static final _fmt = DateFormat('hh:mm a', 'en');
  late DateTime _now = BaghdadTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = BaghdadTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 18, color: AppColors.textSub),
          const SizedBox(width: 8),
          const Text(
            'توقيت بغداد',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Text(
            '\u2066${_fmt.format(_now)}\u2069',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
