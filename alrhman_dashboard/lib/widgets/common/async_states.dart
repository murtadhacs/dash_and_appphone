import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'app_button.dart';

/// مؤشر تحميل في منتصف المساحة.
class LoadingView extends StatelessWidget {
  final double height;
  const LoadingView({super.key, this.height = 240});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

/// رسالة خطأ مع زر إعادة المحاولة.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final double height;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSub),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'إعادة المحاولة',
              icon: Icons.refresh,
              style: AppButtonStyle.soft,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة فارغة بسيطة.
class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.outline),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
