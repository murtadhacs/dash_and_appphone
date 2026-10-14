import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/student.dart';
import '../common/app_button.dart';
import '../common/icon_tile.dart';

/// نافذة تأكيد تعطيل الطالب. تُرجع true عند التأكيد.
/// (الحذف في النظام تعطيل: سجلات الحضور وحساب ولي الأمر تبقى.)
class DeleteStudentDialog extends StatelessWidget {
  final Student student;
  const DeleteStudentDialog({super.key, required this.student});

  static Future<bool> show(BuildContext context, Student student) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteStudentDialog(student: student),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconTile(
                icon: Icons.warning_amber_rounded,
                background: AppColors.redSoft,
                foreground: AppColors.red,
                size: 64,
                iconSize: 32,
                circle: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'تأكيد تعطيل الطالب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: 'هل تريد تعطيل الطالب ',
                  children: [
                    TextSpan(
                      text: '"${student.name}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
                    ),
                    const TextSpan(text: '؟'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'سيختفي من القوائم، وتبقى سجلات حضوره وحساب ولي أمره محفوظة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'تراجع',
                      style: AppButtonStyle.soft,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'نعم، عطّل الطالب',
                      icon: Icons.person_off_outlined,
                      style: AppButtonStyle.danger,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
