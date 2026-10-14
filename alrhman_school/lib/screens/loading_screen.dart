import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../app_scope.dart';
import '../app_shell.dart';
import '../data/parent_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import '../widgets/fade_route.dart';
import '../widgets/school_logo.dart';

/// يُحمّل بيانات ولي الأمر بعد الدخول (أو عند استعادة جلسة محفوظة)، ثم يفتح التطبيق.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final data = ParentData(AppScope.of(context).api);
    try {
      await data.loadAll();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(FadeRoute(page: AppShell(data: data)));
    } on ApiException catch (e) {
      // 401/403 يعيد لشاشة الدخول تلقائياً عبر onUnauthorized.
      if (!mounted || e.needsLogin) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Pulse(child: LogoGlow()),
                    SchoolLogo(size: SchoolLogoSize.lg),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'مدرسة الرحمن الابتدائية',
                textAlign: TextAlign.center,
                style: AppText.style(
                  size: 24,
                  weight: AppText.extrabold,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'بوابة متابعة ولي الأمر الأهلية',
                textAlign: TextAlign.center,
                style: AppText.style(
                  size: 12,
                  weight: AppText.medium,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 32),

              if (_error != null)
                _ErrorCard(message: _error!, onRetry: _load)
              else
                // Spinner card
                Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.purple50),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Column(
                    children: [
                      const Spin(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CustomPaint(painter: _RingSpinnerPainter()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'جاري تحميل بيانات الطالب والجداول...',
                        textAlign: TextAlign.center,
                        style: AppText.style(size: 12, weight: AppText.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'مزامنة سجل الحضور والأنشطة اليومية',
                        textAlign: TextAlign.center,
                        style: AppText.style(
                          size: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Progress bar (2/3 filled, pulsing gradient)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 6,
                          color: AppColors.gray100,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: 2 / 3,
                              child: Pulse(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    // `bg-gradient-to-r` is physical left → right
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        AppColors.brandBlue,
                                        AppColors.brandPurple,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `border-3 border-purple-100 border-t-[#A91FAF] rounded-full`:
/// a light ring with a purple quarter on top.
class _RingSpinnerPainter extends CustomPainter {
  const _RingSpinnerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = AppColors.purple100
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final head = Paint()
      ..color = AppColors.brandPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawOval(arcRect, track);
    // CSS paints the top side as the arc between the two diagonals (-135° → -45°).
    canvas.drawArc(arcRect, -3 * math.pi / 4, math.pi / 2, false, head);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// بطاقة فشل التحميل مع زر إعادة المحاولة.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.rose100),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.wifiOff, size: 28, color: AppColors.rose600),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.style(size: 12, weight: AppText.bold),
          ),
          const SizedBox(height: 14),
          Tap(
            onTap: onRetry,
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'إعادة المحاولة',
                style: AppText.style(
                  size: 12,
                  weight: AppText.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
