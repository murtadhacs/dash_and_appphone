import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'banners_screen.dart';
import 'broadcasts_screen.dart';

class CommunicationsScreen extends StatefulWidget {
  final bool openAddOnStart;
  final VoidCallback? onStartHandled;
  const CommunicationsScreen({
    super.key,
    this.openAddOnStart = false,
    this.onStartHandled,
  });
  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> {
  bool _notifications = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SegmentedButton<bool>(
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textSub,
          selectedBackgroundColor: AppColors.primary,
          selectedForegroundColor: Colors.white,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: false,
            label: Text('الإعلانات'),
            icon: Icon(Icons.photo_library_outlined),
          ),
          ButtonSegment(
            value: true,
            label: Text('الإشعارات'),
            icon: Icon(Icons.notifications_outlined),
          ),
        ],
        selected: {_notifications},
        onSelectionChanged: (v) => setState(() => _notifications = v.first),
      ),
      const SizedBox(height: 24),
      if (_notifications)
        const BroadcastsScreen()
      else
        BannersScreen(
          openAddOnStart: widget.openAddOnStart,
          onStartHandled: widget.onStartHandled,
        ),
    ],
  );
}
