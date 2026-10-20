import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/app_services.dart';
import '../../core/app_colors.dart';
import '../common/app_button.dart';

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
          'تسجيل الدخول',
          style: TextStyle(
            fontSize: 28,
            height: 1.4,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'أدخل بيانات حساب الإدارة للمتابعة',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        if (_error != null) _errorBanner(),
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('اسم المستخدم'),
                const SizedBox(height: 6),
                _field(
                  controller: _username,
                  hint: 'أدخل اسم المستخدم',
                  icon: Icons.person_outline_rounded,
                  autofillHints: const [AutofillHints.username],
                ),
                const SizedBox(height: 20),
                _label('كلمة المرور'),
                const SizedBox(height: 6),
                _field(
                  controller: _password,
                  hint: 'أدخل كلمة المرور',
                  icon: Icons.lock_outline_rounded,
                  password: true,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 24),
                _submitButton(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'في حال نسيان كلمة المرور تواصل مع الدعم الفني',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSub,
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
          borderRadius: BorderRadius.circular(AppRadius.control),
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
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      cursorColor: AppColors.brand,
      decoration: InputDecoration(
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
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
                  color: AppColors.textMuted,
                ),
              )
            : null,
        enabledBorder: border(AppColors.border),
        disabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.brand, 1.5),
        errorBorder: border(AppColors.red),
        focusedErrorBorder: border(AppColors.red, 1.5),
        errorStyle: const TextStyle(color: AppColors.redDark),
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

  Widget _submitButton() => _loading
      ? Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.text,
            ),
          ),
        )
      : AppButton(
          label: 'دخول إلى اللوحة',
          icon: Icons.login_rounded,
          style: AppButtonStyle.amber,
          height: 50,
          expand: true,
          onPressed: _submit,
        );
}
