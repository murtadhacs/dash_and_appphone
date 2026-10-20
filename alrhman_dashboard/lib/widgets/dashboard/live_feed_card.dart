import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/attendance_entry.dart';
import '../../models/student.dart';
import '../common/app_button.dart';
import '../common/app_card.dart';
import '../common/async_states.dart';
import '../common/pill.dart';
import '../common/pulse_dot.dart';
import '../ui/letter_avatar.dart';

/// بطاقة «آخر الوصولات» كما في Figma: أحدث ستة طلاب سجّلوا دخولاً اليوم.
class LiveFeedCard extends StatelessWidget {
  final List<AttendanceEntry> arrivals;
  final Map<int, Student> students;
  final String lastUpdated;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onOpenFullLog;

  const LiveFeedCard({
    super.key,
    required this.arrivals,
    required this.students,
    required this.lastUpdated,
    required this.refreshing,
    required this.onRefresh,
    required this.onOpenFullLog,
  });

  @override
  Widget build(BuildContext context) {
    final shown = arrivals.take(6).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            'آخر الوصولات',
            afterTitle: [
              Tooltip(
                message: 'آخر تحديث $lastUpdated',
                child: Pill.tone(
                  'تحديث كل 20 ثانية',
                  BadgeTone.ok,
                  leading: const PulseDot(
                    color: AppColors.green,
                    size: 6,
                    ping: true,
                  ),
                ),
              ),
            ],
            trailing: [
              AppButton(
                label: 'عرض سجل الحضور',
                icon: Icons.chevron_left_rounded,
                style: AppButtonStyle.outline,
                small: true,
                onPressed: onOpenFullLog,
              ),
              Tooltip(
                message: 'تحديث الآن',
                child: IconActionButton(
                  icon: Icons.refresh_rounded,
                  size: 36,
                  background: Colors.white,
                  hoverBackground: AppColors.canvas,
                  onPressed: refreshing ? null : onRefresh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            const EmptyView(
              message: 'لا توجد بصمات دخول مسجّلة اليوم بعد',
              icon: Icons.fingerprint,
            )
          else
            for (var i = 0; i < shown.length; i++)
              _ArrivalRow(
                key: ValueKey(shown[i].studentId),
                entry: shown[i],
                student: students[shown[i].studentId],
                last: i == shown.length - 1,
              ),
        ],
      ),
    );
  }
}

class _ArrivalRow extends StatefulWidget {
  final AttendanceEntry entry;
  final Student? student;
  final bool last;

  const _ArrivalRow({
    super.key,
    required this.entry,
    required this.student,
    required this.last,
  });

  @override
  State<_ArrivalRow> createState() => _ArrivalRowState();
}

class _ArrivalRowState extends State<_ArrivalRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: _hover ? 10 : 0),
        decoration: BoxDecoration(
          color: _hover ? AppColors.rowHover : Colors.transparent,
          borderRadius: BorderRadius.circular(_hover ? 14 : 0),
          border: widget.last || _hover
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            LetterAvatar(name: e.fullName, size: 40, radius: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    widget.student?.gradeSection ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Pill.tone(e.checkInTime ?? '—', BadgeTone.ok, ltr: true),
          ],
        ),
      ),
    );
  }
}
