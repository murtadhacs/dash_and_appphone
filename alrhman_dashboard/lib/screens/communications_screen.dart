import 'package:flutter/material.dart';
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
      Text(
        'الإعلانات والإشعارات',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      SegmentedButton<bool>(
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
