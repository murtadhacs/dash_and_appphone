import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/app_services.dart';
import '../../core/app_colors.dart';

/// حقول الدخول المدمجة في خلفية الصفحة مع الحفاظ على المصادقة.
class LoginFormPanel extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginFormPanel({super.key, required this.onLoginSuccess});

  @override
  State<LoginFormPanel> createState() => _LoginFormPanelState();
}

class _LoginFormPanelState extends State<LoginFormPanel> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    final api = AppScope.of(context).api;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await api.login(_username.text.trim(), _password.text);
      if (!mounted) return;
      widget.onLoginSuccess();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أهلاً بعودتك',
          style: TextStyle(
            fontSize: 36,
            height: 1.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'مرحباً بك مجدداً في بوابة الإدارة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'سجّل دخولك وابدأ إدارة يومك المدرسي.',
          style: TextStyle(fontSize: 13, color: Colors.white60),
        ),
        const SizedBox(height: 36),
        if (_error != null) _errorBanner(),
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('اسم المستخدم'),
                const SizedBox(height: 10),
                _field(
                  controller: _username,
                  hint: 'أدخل اسم المستخدم',
                  icon: Icons.person_outline_rounded,
                  autofillHints: const [AutofillHints.username],
                ),
                const SizedBox(height: 24),
                _label('كلمة المرور'),
                const SizedBox(height: 10),
                _field(
                  controller: _password,
                  hint: 'أدخل كلمة المرور',
                  icon: Icons.lock_outline_rounded,
                  password: true,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 32),
                _submitButton(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 15, color: Colors.white60),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'وصول مخصص لإدارة المدرسة',
                style: TextStyle(fontSize: 11, color: Colors.white60),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Iterable<String> autofillHints,
    bool password = false,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return TextFormField(
      controller: controller,
      enabled: !_loading,
      textDirection: TextDirection.ltr,
      obscureText: password && !_showPassword,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: autofillHints,
      textInputAction: password ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: password ? (_) => _submit() : null,
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      cursorColor: AppColors.amber,
      decoration: InputDecoration(
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 19,
        ),
        prefixIcon: Icon(icon, size: 20, color: Colors.white60),
        suffixIcon: password
            ? IconButton(
                tooltip: _showPassword
                    ? 'إخفاء كلمة المرور'
                    : 'إظهار كلمة المرور',
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                  color: Colors.white60,
                ),
              )
            : null,
        enabledBorder: border(Colors.white.withValues(alpha: .2)),
        disabledBorder: border(Colors.white.withValues(alpha: .1)),
        focusedBorder: border(AppColors.amber, 1.5),
        errorBorder: border(AppColors.red),
        focusedErrorBorder: border(AppColors.red, 1.5),
        errorStyle: const TextStyle(color: Color(0xFFFFCACA)),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.redBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.redDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.redDark,
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _error = null),
            child: const Icon(Icons.close, size: 16, color: AppColors.redDark),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() => SizedBox(
    height: 54,
    child: FilledButton(
      onPressed: _loading ? null : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.amber.withValues(alpha: .6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'تسجيل الدخول للنظام',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
    ),
  );
}
