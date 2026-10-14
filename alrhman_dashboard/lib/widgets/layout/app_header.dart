import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/responsive.dart';

/// رقم دعم النظام الظاهر في قائمة المساعدة.
const supportPhone = '07749078969';

/// الشريط العلوي: المساعدة، اسم المستخدم، وتسجيل الخروج.
class AppHeader extends StatelessWidget {
  final String? username;
  final VoidCallback onToggleSidebar;
  final VoidCallback onLogout;

  const AppHeader({
    super.key,
    required this.username,
    required this.onToggleSidebar,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = Breakpoints.isDesktop(context);

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 24 : 16),
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!desktop)
            IconButton(
              tooltip: 'القائمة',
              onPressed: onToggleSidebar,
              icon: const Icon(Icons.menu, size: 20, color: AppColors.textSub),
            ),
          const Spacer(),
          const _HelpMenu(),
          const SizedBox(width: 12),
          Container(width: 1, height: 24, color: AppColors.border),
          const SizedBox(width: 12),
          if (width >= Breakpoints.sm)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (username == null || username!.isEmpty)
                      ? 'المدير'
                      : username!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const Text(
                  'مدير النظام',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: onLogout,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              hoverColor: AppColors.redSoft,
              minimumSize: const Size(32, 32),
            ),
            icon: const Icon(Icons.logout, size: 16),
          ),
        ],
      ),
    );
  }
}

class _HelpMenu extends StatelessWidget {
  const _HelpMenu();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
      menuChildren: const [
        SizedBox(
          width: 256,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الدعم الفني',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'لأي استفسار أو مشكلة تقنية تواصل على الرقم:',
                style: TextStyle(fontSize: 11, color: AppColors.textSub),
              ),
              SizedBox(height: 6),
              SelectableText(
                supportPhone,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
      builder: (context, controller, _) {
        return Tooltip(
          message: 'المساعدة والدعم',
          child: InkWell(
            customBorder: const CircleBorder(),
            hoverColor: AppColors.accentSoft,
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.help_outline,
                size: 20,
                color: AppColors.textSub,
              ),
            ),
          ),
        );
      },
    );
  }
}
