import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';

OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.control),
  borderSide: BorderSide(color: c, width: w),
);

InputDecoration appInputDecoration({
  String? hint,
  Widget? prefix,
  Widget? suffix,
  Color fill = Colors.white,
  EdgeInsetsGeometry? padding,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
    prefixIcon: prefix,
    suffixIcon: suffix,
    isDense: true,
    filled: true,
    fillColor: fill,
    contentPadding:
        padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: _border(AppColors.border),
    enabledBorder: _border(AppColors.border),
    focusedBorder: _border(AppColors.brand, 2),
    errorBorder: _border(AppColors.red),
    focusedErrorBorder: _border(AppColors.red, 2),
  );
}

/// عنوان حقل: نص غامق + علامة إلزامي + تلميح اختياري على الطرف الآخر.
class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  final String? hint;
  final Color? hintColor;
  final Widget? leading;
  final Widget? trailing;

  const FieldLabel(
    this.text, {
    super.key,
    this.required = false,
    this.hint,
    this.hintColor,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 4)],
        Flexible(
          child: Text.rich(
            TextSpan(
              text: text,
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.red),
                  ),
              ],
            ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ),
        const Spacer(),
        ?trailing,
        if (hint != null)
          Text(
            hint!,
            style: TextStyle(
              fontSize: 11,
              color: hintColor ?? AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool ltr;
  final bool mono;
  final bool obscure;
  final bool password;
  final bool requiredField;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextAlign textAlign;
  final double fontSize;
  final FontWeight? fontWeight;
  final double height;
  final Color fill;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.ltr = false,
    this.mono = false,
    this.obscure = false,
    this.password = false,
    this.requiredField = false,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.textAlign = TextAlign.start,
    this.fontSize = 12,
    this.fontWeight,
    this.height = 40,
    this.fill = Colors.white,
    this.validator,
    this.formatters,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      autocorrect: !password,
      enableSuggestions: !password,
      smartDashesType: password ? SmartDashesType.disabled : null,
      smartQuotesType: password ? SmartQuotesType.disabled : null,
      maxLength: maxLength,
      maxLines: obscure ? 1 : maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      inputFormatters: formatters,
      textAlign: ltr && textAlign == TextAlign.start
          ? TextAlign.left
          : textAlign,
      textDirection: ltr ? TextDirection.ltr : null,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: AppColors.text,
        fontFamily: mono ? 'monospace' : null,
      ),
      validator:
          validator ??
          (requiredField
              ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
              : null),
      decoration: appInputDecoration(
        hint: hint,
        fill: fill,
        suffix: suffix,
        padding: contentPadding,
        prefix: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 16, color: AppColors.textMuted),
      ).copyWith(counterText: ''),
    );

    if (maxLines > 1) return field;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: field,
    );
  }
}
