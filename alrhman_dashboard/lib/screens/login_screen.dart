import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/assets.dart';
import '../widgets/login/login_brand_panel.dart';
import '../widgets/login/login_form_panel.dart';

/// صفحة دخول ممتدة، تدمج هوية المدرسة وحقول الدخول في مساحة واحدة.
class LoginScreen extends StatelessWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, AppColors.brand, AppColors.primary],
          ),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -240,
              end: -180,
              child: _glow(AppColors.brand, 700),
            ),
            PositionedDirectional(
              bottom: -280,
              start: -200,
              child: _glow(AppColors.amber.withValues(alpha: .12), 650),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1024;
                  final padding = wide ? 64.0 : 24.0;
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: 28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1280),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _header(wide),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: wide ? 64 : 44,
                                  ),
                                  child: wide
                                      ? Row(
                                          children: [
                                            Expanded(
                                              flex: 5,
                                              child: Align(
                                                alignment: AlignmentDirectional
                                                    .centerStart,
                                                child: ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 400,
                                                      ),
                                                  child: LoginFormPanel(
                                                    onLoginSuccess:
                                                        onLoginSuccess,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 80),
                                            const Expanded(
                                              flex: 6,
                                              child: LoginBrandPanel(),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 440,
                                              ),
                                              child: LoginFormPanel(
                                                onLoginSuccess: onLoginSuccess,
                                              ),
                                            ),
                                            const SizedBox(height: 56),
                                            const LoginBrandPanel(
                                              compact: true,
                                            ),
                                          ],
                                        ),
                                ),
                                _footer(wide),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(Color color, double size) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );

  Widget _header(bool wide) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Image.asset(
          appLogoAsset,
          width: 44,
          height: 44,
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
      if (wide) ...[
        const Icon(Icons.grid_view_rounded, color: AppColors.amber, size: 18),
        const SizedBox(width: 10),
        const Text(
          'بوابة الإدارة',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ],
  );

  Widget _footer(bool wide) {
    const copyright = Text(
      '© 2026 الرحمن الابتدائية',
      style: TextStyle(fontSize: 11, color: Colors.white60),
    );
    const note = Text(
      'إدارة أقرب. تعليم أفضل.',
      style: TextStyle(fontSize: 11, color: Colors.white60),
    );
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: .12)),
        ),
      ),
      child: wide
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [copyright, note],
            )
          : const Column(children: [copyright, SizedBox(height: 8), note]),
    );
  }
}
