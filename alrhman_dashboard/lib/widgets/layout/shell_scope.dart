import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../core/school_day_info.dart';

/// ما يحتاجه رأس كل صفحة من الإطار العام: الخروج، فتح القائمة، وحالة اليوم.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.onLogout,
    required this.onOpenMenu,
    required this.showMenuButton,
    required this.dayInfo,
    required this.reportDay,
    required super.child,
  });

  final VoidCallback onLogout;
  final VoidCallback onOpenMenu;
  final bool showMenuButton;

  /// حالة اليوم الدراسي كما أرجعها الخادم آخر مرة (null قبل أول قراءة).
  final ValueListenable<SchoolDayInfo?> dayInfo;

  /// تُبلغ بها الشاشات عن حالة اليوم حين تقرؤها من الخادم.
  final ValueChanged<SchoolDayInfo> reportDay;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) =>
      showMenuButton != old.showMenuButton || dayInfo != old.dayInfo;
}
