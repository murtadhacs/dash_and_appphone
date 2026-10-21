import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../../models/student.dart';
import '../common/app_button.dart';
import '../common/app_dialog.dart';

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
    return AppDialog(
      icon: LucideIcons.userX,
      iconBackground: AppColors.badBg,
      iconForeground: AppColors.red,
      title: 'تأكيد تعطيل الطالب',
      subtitle: student.name,
      maxWidth: 480,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
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
            style: const TextStyle(
              fontSize: 14,
              height: 1.8,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 12),
          const DialogNote(
            'سيختفي من القوائم، وتبقى سجلات حضوره وحساب ولي أمره محفوظة.',
          ),
          const SizedBox(height: 20),
          DialogActions(
            children: [
              AppButton(
                label: 'تراجع',
                style: AppButtonStyle.outline,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              AppButton(
                label: 'نعم، عطّل الطالب',
                icon: LucideIcons.userX,
                style: AppButtonStyle.danger,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
