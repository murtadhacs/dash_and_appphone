import 'package:flutter/material.dart';

import '../widgets/ui/seg_tabs.dart';
import 'banners_screen.dart';
import 'broadcasts_screen.dart';

/// شاشة «التواصل والإعلانات» بقسمين: البنرات والإشعارات الجماعية.
/// القسم يتحدد من الشريط الجانبي أو من مفتاح التبويبات أعلى الصفحة.
class CommunicationsScreen extends StatelessWidget {
  final bool showBroadcasts;
  final ValueChanged<bool>? onSwitch;
  final bool openAddOnStart;
  final VoidCallback? onStartHandled;

  const CommunicationsScreen({
    super.key,
    this.showBroadcasts = false,
    this.onSwitch,
    this.openAddOnStart = false,
    this.onStartHandled,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = SegTabs<bool>(
      items: const [(false, 'البنرات'), (true, 'الإشعارات الجماعية')],
      value: showBroadcasts,
      onChanged: (v) => onSwitch?.call(v),
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: showBroadcasts
          ? BroadcastsScreen(key: const ValueKey('broadcasts'), tabs: tabs)
          : BannersScreen(
              key: const ValueKey('banners'),
              tabs: tabs,
              openAddOnStart: openAddOnStart,
              onStartHandled: onStartHandled,
            ),
    );
  }
}
