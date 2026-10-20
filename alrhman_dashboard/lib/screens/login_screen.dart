import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/assets.dart';
import '../widgets/login/login_brand_panel.dart';
import '../widgets/login/login_form_panel.dart';

/// صفحة الدخول: إطار كحلي يضم لوحة الهوية (يمين في RTL) وبطاقة الدخول
/// البيضاء على لوحة محتوى عائمة، بنفس لغة تصميم لوحة الإدارة.
class LoginScreen extends StatelessWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.viewport,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1024;
          return Padding(
            padding: EdgeInsets.all(wide ? 16 : 0),
            child: Container(
              padding: EdgeInsets.all(wide ? 12 : 0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(
                  wide ? AppRadius.shell : 0,
                ),
              ),
              child: wide ? _wide() : _narrow(),
            ),
          );
        },
      ),
    );
  }

  Widget _wide() => Row(
    children: [
      Expanded(flex: 5, child: _brandColumn(wide: true)),
      Expanded(
        flex: 6,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.canvas),
          child: ColoredBox(
            color: AppColors.background,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
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
            children: [
              _header(),
              const SizedBox(height: 28),
              _formCard(),
              const SizedBox(height: 28),
              const LoginBrandPanel(compact: true),
              const SizedBox(height: 24),
              const Text(
                '© 2026 الرحمن الابتدائية',
                style: TextStyle(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _formCard() => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      boxShadow: AppShadows.card,
    ),
    child: LoginFormPanel(onLoginSuccess: onLoginSuccess),
  );

  Widget _brandColumn({required bool wide}) => Stack(
    children: [
      PositionedDirectional(
        bottom: -110,
        start: -110,
        child: _circle(340, AppColors.amber.withValues(alpha: .16)),
      ),
      PositionedDirectional(
        bottom: 70,
        start: 220,
        child: _circle(92, const Color(0x388FA7FE)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(48, 40, 48, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const Spacer(),
            const LoginBrandPanel(),
            const Spacer(),
            const Text(
              '© 2026 الرحمن الابتدائية • إدارة أقرب. تعليم أفضل.',
              style: TextStyle(fontSize: 11, color: Colors.white60),
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

  Widget _header() => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Image.asset(
          appLogoAsset,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
      const SizedBox(width: 14),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الرحمن الابتدائية',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'نظام الإدارة المدرسية الموحد',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );
}
