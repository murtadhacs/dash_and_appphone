import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import '../widgets/fade_route.dart';
import '../widgets/school_logo.dart';
import '../app_scope.dart';
import 'loading_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // `logoFadeIn 1.2s cubic-bezier(0.16, 1, 0.3, 1)`
  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _logoCurve = CurvedAnimation(
    parent: _logoController,
    curve: const Cubic(0.16, 1, 0.3, 1),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _route();
  }

  /// جلسة محفوظة ← تحميل البيانات مباشرة، وإلا ← شاشة الدخول.
  /// ننتظر مدة الشعار الأصلية (2.2 ثانية) أو استعادة الجلسة، أيهما أطول.
  Future<void> _route() async {
    final api = AppScope.of(context).api;
    final results = await Future.wait([
      api.restoreSession(),
      Future<void>.delayed(const Duration(milliseconds: 2200)),
    ]);
    if (!mounted) return;
    final hasSession = results[0] as bool;
    Navigator.of(context).pushReplacement(
      FadeRoute(page: hasSession ? const LoadingScreen() : const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
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
              FadeTransition(
                opacity: _logoCurve,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(_logoCurve),
                  child: const SizedBox(
                    width: 112,
                    height: 112,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        LogoGlow(),
                        SchoolLogo(size: SchoolLogoSize.lg),
                      ],
                    ),
                  ),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: AppShadows.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PingDot(size: 8, color: AppColors.brandPurple),
                    const SizedBox(width: 8),
                    Text(
                      'جاري تهيئة النظام والمصادقة...',
                      style: AppText.style(
                        size: 12,
                        weight: AppText.semibold,
                        color: AppColors.textMuted,
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
