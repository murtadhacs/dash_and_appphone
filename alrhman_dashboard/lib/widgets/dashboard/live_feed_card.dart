import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/attendance_entry.dart';
import '../../models/student.dart';
import '../common/app_avatar.dart';
import '../common/app_card.dart';
import '../common/app_data_table.dart';
import '../common/async_states.dart';
import '../common/clipped_text.dart';
import '../common/pulse_dot.dart';
import '../common/section_title.dart';

/// بطاقة آخر الحركات: الطلاب الذين لديهم وقت دخول اليوم، الأحدث أولاً.
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  icon: Icons.fingerprint,
                  title: 'آخر حركات الدخول',
                  subtitle: 'الطلاب الذين سجّلوا بصمة دخول اليوم، الأحدث أولاً',
                ),
              ),
              TextButton.icon(
                onPressed: onOpenFullLog,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.arrow_back, size: 14),
                iconAlignment: IconAlignment.end,
                label: const Text('سجل الحضور الكامل'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty)
            const EmptyView(
              message: 'لا توجد بصمات دخول مسجّلة اليوم بعد',
              icon: Icons.fingerprint,
            )
          else
            AppDataTable(
              dataRowHeight: 52,
              columns: [
                tableColumn('الطالب'),
                tableColumn('الصف والشعبة'),
                tableColumn('وقت الدخول'),
              ],
              rows: [
                for (final e in shown)
                  DataRow(
                    key: ValueKey(e.studentId),
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppAvatar(size: 32),
                            const SizedBox(width: 10),
                            ClippedText(
                              e.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          students[e.studentId]?.gradeSection ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          e.checkInTime ?? '—',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSub,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const PulseDot(color: AppColors.green, size: 10, ping: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يتحدّث تلقائياً كل 20 ثانية • آخر تحديث $lastUpdated',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSub,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'تحديث الآن',
                  onPressed: refreshing ? null : onRefresh,
                  style: IconButton.styleFrom(
                    hoverColor: AppColors.border,
                    minimumSize: const Size(32, 32),
                  ),
                  icon: SpinningIcon(
                    icon: Icons.refresh,
                    spinning: refreshing,
                    color: refreshing ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
