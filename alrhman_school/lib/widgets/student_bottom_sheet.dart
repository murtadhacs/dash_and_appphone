import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'common.dart';

/// Modal sheet for switching between the parent's children.
/// Rendered as an overlay inside the app shell (above the bottom nav).
class StudentBottomSheet extends StatefulWidget {
  const StudentBottomSheet({
    super.key,
    required this.students,
    required this.currentStudent,
    required this.onSelectStudent,
    required this.onClose,
  });

  final List<Student> students;
  final Student? currentStudent;
  final ValueChanged<Student> onSelectStudent;
  final VoidCallback onClose;

  @override
  State<StudentBottomSheet> createState() => _StudentBottomSheetState();
}

class _StudentBottomSheetState extends State<StudentBottomSheet>
    with SingleTickerProviderStateMixin {
  // `animate-in fade-in slide-in-from-bottom duration-200`
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..forward();

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Positioned.fill(
      child: Stack(
        children: [
          // Scrim
          Positioned.fill(
            child: Tap(
              onTap: widget.onClose,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _controller,
              child: SlideTransition(
                position: _slide,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 32 + bottomInset),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 50,
                        offset: Offset(0, 25),
                        spreadRadius: -12,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Grab handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.gray300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.gray100),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'قائمة الأبناء',
                                  style: AppText.style(
                                    size: 12,
                                    weight: AppText.bold,
                                  ),
                                ),
                                Text(
                                  'اختر الطالب لعرض سجل حضوره وجداوله',
                                  style: AppText.style(
                                    size: 10,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            Tap(
                              onTap: widget.onClose,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColors.gray100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.x,
                                  size: 14,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Student rows
                      if (widget.students.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              const Icon(
                                LucideIcons.users,
                                size: 28,
                                color: AppColors.gray300,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'لا يوجد طلاب مرتبطون بحسابك',
                                textAlign: TextAlign.center,
                                style: AppText.style(
                                  size: 11,
                                  weight: AppText.bold,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        for (int i = 0; i < widget.students.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _StudentRow(
                            student: widget.students[i],
                            isSelected:
                                widget.students[i].id ==
                                widget.currentStudent?.id,
                            onTap: () {
                              widget.onSelectStudent(widget.students[i]);
                              widget.onClose();
                            },
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.isSelected,
    required this.onTap,
  });

  final Student student;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPurple.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.brandPurple : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.style(size: 12, weight: AppText.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandPurple.withValues(alpha: 0.1)
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isSelected ? 'محدد حالياً' : student.todayLabel,
                          style: AppText.style(
                            size: 8,
                            weight: AppText.bold,
                            color: isSelected
                                ? AppColors.brandPurple
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    student.classLabel,
                    style: AppText.style(size: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandPurple : null,
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.gray300),
              ),
              child: isSelected
                  ? const Icon(
                      LucideIcons.check600,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
