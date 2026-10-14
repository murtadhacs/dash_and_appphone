import 'package:flutter/widgets.dart';

/// نقاط التوقف المقابلة لـ Tailwind (sm / md / lg / xl).
class Breakpoints {
  Breakpoints._();
  static const double sm = 640;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;

  /// عرض الشريط الجانبي الثابت.
  static const double sidebarWidth = 256;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= lg;
}
