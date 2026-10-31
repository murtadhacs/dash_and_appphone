import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';

/// Preview of the empty / error / retry states used across the app.
class SpecialStatesScreen extends StatefulWidget {
  const SpecialStatesScreen({super.key});

  @override
  State<SpecialStatesScreen> createState() => _SpecialStatesScreenState();
}

class _SpecialStatesScreenState extends State<SpecialStatesScreen> {
  bool _retrying = false;
  bool _retrySuccess = false;

  void _handleRetry() {
    if (_retrying) return;
    setState(() => _retrying = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _retrying = false;
        _retrySuccess = true;
      });
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        setState(() => _retrySuccess = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TabPageScroll(
      horizontalPadding: 16,
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: AppShadows.sm,
              ),
              child: Text(
                'معاينة الحالات الاستثنائية والخطأ',
                style: AppText.style(size: 10, weight: AppText.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ---------------- Empty state (attendance) ----------------
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              const Icon(
                LucideIcons.calendar,
                size: 32,
                color: AppColors.brandPurple,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'تنبيه المتابعة',
                  style: AppText.style(
                    size: 9,
                    weight: AppText.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'لا توجد بيانات حضور مسجلة',
                textAlign: TextAlign.center,
                style: AppText.style(size: 12, weight: AppText.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'لم يتم رصد أي سجلات حضور أو غياب لهذا الطالب في الفترة المحددة حتى الآن.',
                textAlign: TextAlign.center,
                style: AppText.style(
                  size: 10,
                  color: AppColors.textMuted,
                  height: 1.625,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ---------------- Error state + retry ----------------
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                size: 32,
                color: AppColors.brandPurple,
              ),
              const SizedBox(height: 10),
              Text(
                'تعذر تحميل البيانات',
                textAlign: TextAlign.center,
                style: AppText.style(size: 12, weight: AppText.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.',
                textAlign: TextAlign.center,
                style: AppText.style(
                  size: 10,
                  color: AppColors.textMuted,
                  height: 1.625,
                ),
              ),
              const SizedBox(height: 10),
              Tap(
                onTap: _retrying ? null : _handleRetry,
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.sm,
                  ),
                  child: _retrying
                      ? const Spin(
                          child: Icon(
                            LucideIcons.rotateCw,
                            size: 14,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _retrySuccess
                                  ? LucideIcons.check
                                  : LucideIcons.rotateCw,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _retrySuccess
                                  ? 'تم استعادة الاتصال بنجاح!'
                                  : 'إعادة المحاولة',
                              style: AppText.style(
                                size: 11,
                                weight: AppText.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ---------------- Empty notifications ----------------
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: [
              const Icon(
                LucideIcons.bellOff,
                size: 32,
                color: AppColors.brandPurple,
              ),
              const SizedBox(height: 6),
              Text(
                'صندوق الإشعارات فارغ',
                textAlign: TextAlign.center,
                style: AppText.style(size: 11, weight: AppText.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'لا توجد تعاميم أو إشعارات غير مقروءة حالياً.',
                textAlign: TextAlign.center,
                style: AppText.style(size: 9, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
