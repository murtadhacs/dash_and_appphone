import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../../core/baghdad_time.dart';
import '../../core/school_day_info.dart';
import '../common/pill.dart';
import '../ui/hover.dart';
import 'shell_scope.dart';

/// رقم دعم النظام الظاهر في بطاقة الدعم الفني بالشريط الجانبي.
const supportPhone = '07749078969';

/// رأس الصفحة كما في Figma: العنوان وشارته يميناً، ثم البحث والأزرار،
/// ثم حالة الدوام وساعة بغداد وزر الخروج، وأخيراً زر الإجراء الأساسي يساراً.
class PageHeader extends StatelessWidget {
  final String title;
  final Widget? badge;
  final Widget? search;
  final List<Widget> actions;
  final Widget? cta;

  const PageHeader({
    super.key,
    required this.title,
    this.badge,
    this.search,
    this.actions = const [],
    this.cta,
  });

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    Widget titleRow({required bool withBadge}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shell?.showMenuButton ?? false) ...[
          HeaderSquareButton(
            tooltip: 'القائمة',
            icon: LucideIcons.menu,
            onTap: shell!.onOpenMenu,
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
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
        if (withBadge && badge != null) ...[const SizedBox(width: 12), badge!],
      ],
    );

    final tools = <Widget>[
      ?search,
      ...actions,
      if (shell != null) const _DayStatusChip(),
      const _BaghdadClock(),
      if (shell != null)
        HeaderSquareButton(
          tooltip: 'تسجيل الخروج',
          icon: LucideIcons.logOut,
          onTap: shell.onLogout,
          hoverColor: AppColors.redSoft,
          hoverIconColor: AppColors.red,
        ),
      ?cta,
    ];

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 1100) {
          return Row(
            children: [
              Expanded(child: titleRow(withBadge: true)),
              const SizedBox(width: 16),
              for (var i = 0; i < tools.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                tools[i],
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            titleRow(withBadge: c.maxWidth >= 600),
            if (c.maxWidth < 600 && badge != null) ...[
              const SizedBox(height: 8),
              Align(alignment: AlignmentDirectional.centerStart, child: badge),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: tools,
            ),
          ],
        );
      },
    );
  }
}

/// حقل البحث الموجود في رأس الصفحة (عرض 300 كما في Figma).
class HeaderSearch extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final double width;

  const HeaderSearch({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(
            LucideIcons.search,
            size: 20,
            color: AppColors.textMuted,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(LucideIcons.x, size: 18),
                  color: AppColors.textMuted,
                ),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// زر مربع 44×44 أبيض بحد خفيف (القائمة، الخروج، التحديث...).
class HeaderSquareButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? hoverColor;
  final Color? hoverIconColor;
  final Widget? child;

  const HeaderSquareButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.hoverColor,
    this.hoverIconColor,
    this.child,
  });

  @override
  State<HeaderSquareButton> createState() => _HeaderSquareButtonState();
}

class _HeaderSquareButtonState extends State<HeaderSquareButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final on = _hover && enabled;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: on ? 1.06 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: on
                    ? (widget.hoverColor ?? AppColors.canvas)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.line),
              ),
              child: Center(
                child:
                    widget.child ??
                    Icon(
                      widget.icon,
                      size: 20,
                      color: on
                          ? (widget.hoverIconColor ?? AppColors.text)
                          : AppColors.textSub,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// شارة الرأس البيضاء بارتفاع 44 (حالة الدوام، الساعة).
class HeaderChip extends StatelessWidget {
  final Widget leading;
  final String label;
  final bool ltrLabel;

  const HeaderChip({
    super.key,
    required this.leading,
    required this.label,
    this.ltrLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      lift: 2,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 8),
            Text(
              label,
              textDirection: ltrLabel ? TextDirection.ltr : null,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة اليوم: «الدوام الرسمي قائم» أو العطلة/الإيقاف كما يرجعها الخادم.
class _DayStatusChip extends StatelessWidget {
  const _DayStatusChip();

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.maybeOf(context)!;
    return ValueListenableBuilder<SchoolDayInfo?>(
      valueListenable: shell.dayInfo,
      builder: (context, info, _) {
        if (info == null) return const SizedBox.shrink();
        final (label, color) = info.isSchool
            ? ('الدوام الرسمي قائم', AppColors.green)
            : info.type == 'weekend'
            ? ('عطلة نهاية الأسبوع', AppColors.textMuted)
            : (info.label, AppColors.amber);
        return HeaderChip(
          leading: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          label: label,
        );
      },
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
    return Tooltip(
      message: 'توقيت بغداد',
      child: HeaderChip(
        leading: const Icon(
          LucideIcons.clock,
          size: 18,
          color: AppColors.textSub,
        ),
        label: _fmt.format(_now),
        ltrLabel: true,
      ),
    );
  }
}

/// شارة بجانب العنوان (مثل «للقراءة فقط»).
Widget headerBadge(String label, BadgeTone tone) => Pill.tone(label, tone);
