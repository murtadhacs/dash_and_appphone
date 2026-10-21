import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/assets.dart';
import '../widgets/login/login_brand_panel.dart';
import '../widgets/login/login_form_panel.dart';

/// صفحة الدخول بعرض الشاشة كاملة كما في Figma: لوحة الهوية الكحلية يميناً
/// (في RTL) وبطاقة الدخول البيضاء على لوحة رمادية يساراً.
class LoginScreen extends StatelessWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1024;
          return wide ? _wide(context) : _narrow();
        },
      ),
    );
  }

  Widget _wide(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(flex: 5, child: _brandColumn()),
      Expanded(
        flex: 6,
        child: ClipRRect(
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(AppRadius.canvas),
            bottomStart: Radius.circular(AppRadius.canvas),
          ).resolve(Directionality.of(context)),
          child: ColoredBox(
            color: AppColors.background,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _formCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _narrow() => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Logo(),
              const SizedBox(height: 28),
              _formCard(),
              const SizedBox(height: 32),
              const LoginBrandPanel(compact: true),
              const SizedBox(height: 24),
              const Text(
                '© مدرسة الرحمن الابتدائية للبنين',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _formCard() => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutCubic,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
    ),
    child: Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: LoginFormPanel(onLoginSuccess: onLoginSuccess),
    ),
  );

  Widget _brandColumn() => Stack(
    children: [
      PositionedDirectional(
        bottom: -90,
        end: -90,
        child: _circle(320, AppColors.amber.withValues(alpha: .18)),
      ),
      PositionedDirectional(
        bottom: 40,
        end: 300,
        child: _circle(90, const Color(0x388FA7FE)),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(48, 44, 48, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Logo(),
            Spacer(),
            LoginBrandPanel(),
            Spacer(),
            Text(
              '© مدرسة الرحمن الابتدائية للبنين',
              style: TextStyle(fontSize: 12, color: Color(0xA6FFFFFF)),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _circle(double size, Color color) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ),
  );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Image.asset(appLogoAsset, fit: BoxFit.contain),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مدرسة الرحمن',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'الابتدائية للبنين',
              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}
