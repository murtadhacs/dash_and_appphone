import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import '../widgets/fade_route.dart';
import '../widgets/school_logo.dart';
import 'loading_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.sessionExpired = false});

  /// يُعرض تنبيه "انتهت الجلسة" عند الوصول بعد 401/403.
  final bool sessionExpired;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;
  String? _error;

  /// عند 429: الزر معطّل حتى ينتهي الانتظار (لا نعيد المحاولة تلقائياً).
  DateTime? _blockedUntil;
  Timer? _unblockTimer;
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _unblockTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _blocked =>
      _blockedUntil != null && DateTime.now().isBefore(_blockedUntil!);

  Future<void> _handleLogin() async {
    if (_loading || _blocked) return;
    final phone = _usernameController.text.trim();
    final pin = _passwordController.text;
    if (phone.isEmpty || pin.isEmpty) {
      setState(() => _error = 'أدخل رقم الهاتف وكلمة المرور');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AppScope.of(context).api.login(phone, pin);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        FadeRoute(
          page: const LoadingScreen(),
          duration: const Duration(milliseconds: 250),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        final wait = e.retryAfterSeconds;
        if (e.statusCode == 429 && wait != null) {
          _blockedUntil = DateTime.now().add(Duration(seconds: wait));
          _unblockTimer?.cancel();
          _unblockTimer = Timer(Duration(seconds: wait), () {
            if (mounted) setState(() => _blockedUntil = null);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: EdgeInsets.fromLTRB(24, topInset + 48, 24, 24),
        child: Column(
          children: [
            Expanded(
              child: NoScrollbar(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo + heading
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.purple50),
                              boxShadow: AppShadows.sm,
                            ),
                            child: const Center(
                              child: SchoolLogo(
                                size: SchoolLogoSize.md,
                                withContainer: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'تسجيل الدخول',
                          textAlign: TextAlign.center,
                          style: AppText.style(
                            size: 24,
                            weight: AppText.extrabold,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'أهلاً بكم في المنصة التعليمية لمدرسة الرحمن',
                          textAlign: TextAlign.center,
                          style: AppText.style(
                            size: 12,
                            weight: AppText.medium,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (widget.sessionExpired && _error == null) ...[
                          const _Notice(
                            text:
                                'انتهت الجلسة أو تغيّرت كلمة المرور، سجّل الدخول من جديد.',
                            error: false,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_error != null) ...[
                          _Notice(text: _error!, error: true),
                          const SizedBox(height: 16),
                        ],

                        // Phone
                        _FieldLabel('رقم الهاتف'),
                        const SizedBox(height: 6),
                        _InputField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          hint: '07XXXXXXXXX',
                          icon: LucideIcons.phone,
                          fontWeight: AppText.medium,
                          keyboardType: TextInputType.phone,
                          ltr: true,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _FieldLabel('كلمة مرور ولي الأمر'),
                        const SizedBox(height: 6),
                        _InputField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          hint: 'كلمة المرور التي سلّمتها لك المدرسة',
                          icon: LucideIcons.lock,
                          obscure: !_showPassword,
                          password: true,
                          onToggleVisibility: () =>
                              setState(() => _showPassword = !_showPassword),
                          keyboardType: TextInputType.visiblePassword,
                          ltr: true,
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),

                        // Submit
                        Tap(
                          onTap: (_loading || _blocked) ? null : _handleLogin,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: (_loading || _blocked)
                                  ? AppColors.brandPurple.withValues(alpha: 0.6)
                                  : AppColors.brandPurple,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFA855F7,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 10),
                                  spreadRadius: -3,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFFA855F7,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'تسجيل الدخول',
                                        style: AppText.style(
                                          size: 14,
                                          weight: AppText.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.35,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        LucideIcons.arrowLeft,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'مدرسة الرحمن الأهلية © جميع الحقوق محفوظة',
                textAlign: TextAlign.center,
                style: AppText.style(size: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.style(size: 12, weight: AppText.bold));
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.fontWeight = AppText.regular,
    this.onSubmitted,
    this.keyboardType,
    this.ltr = false,
    this.password = false,
    this.onToggleVisibility,
  });

  final TextInputType? keyboardType;

  /// للأرقام: اتجاه من اليسار لليمين داخل الواجهة العربية.
  final bool ltr;

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool password;
  final VoidCallback? onToggleVisibility;
  final FontWeight fontWeight;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? AppColors.brandPurple : AppColors.gray200,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              // px-4 pl-10 → 16 on the start (right) side, 40 on the end (left)
              padding: EdgeInsetsDirectional.only(
                start: 16,
                end: onToggleVisibility == null ? 40 : 64,
              ),
              child: Center(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  textDirection: ltr ? TextDirection.ltr : null,
                  textAlign: ltr ? TextAlign.right : TextAlign.start,
                  autocorrect: false,
                  enableSuggestions: !password && !obscure,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  autofillHints: password
                      ? const [AutofillHints.password]
                      : const [AutofillHints.telephoneNumber],
                  cursorColor: AppColors.brandPurple,
                  textAlignVertical: TextAlignVertical.center,
                  style: AppText.style(
                    size: 14,
                    weight: fontWeight,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: AppText.style(
                      size: 14,
                      weight: fontWeight,
                      color: AppColors.gray400,
                      height: 1.2,
                    ),
                  ),
                  onSubmitted: onSubmitted,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 14,
            top: onToggleVisibility == null ? 14 : 0,
            child: onToggleVisibility == null
                ? Icon(icon, size: 20, color: AppColors.textMuted)
                : IconButton(
                    tooltip: obscure
                        ? 'إظهار كلمة المرور'
                        : 'إخفاء كلمة المرور',
                    onPressed: onToggleVisibility,
                    icon: Icon(
                      obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// تنبيه أعلى النموذج: خطأ (أحمر) أو معلومة (بنفسجي).
class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.rose600 : AppColors.brandPurple;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? AppColors.rose50 : AppColors.purple50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: error ? AppColors.rose100 : AppColors.purple100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            error ? LucideIcons.circleAlert : LucideIcons.info,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppText.style(
                size: 12,
                weight: AppText.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
