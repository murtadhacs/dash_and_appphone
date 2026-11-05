import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'common.dart';

/// الرابط نفسه المسجَّل في Google Play وApp Store Connect.
const privacyPolicyUrl = 'https://alrahman.up.railway.app/privacy.html';

/// يفتح سياسة الخصوصية في المتصفح.
Future<void> openPrivacyPolicy(BuildContext context) async {
  final ok = await launchUrl(
    Uri.parse(privacyPolicyUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر فتح سياسة الخصوصية على هذا الجهاز')),
    );
  }
}

/// سطر الموافقة أسفل شاشة الدخول؛ متاح قبل تسجيل الدخول.
class PrivacyNotice extends StatelessWidget {
  const PrivacyNotice({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    link: true,
    child: Tap(
      onTap: () => openPrivacyPolicy(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text.rich(
          TextSpan(
            text: 'بتسجيل الدخول توافق على ',
            children: [
              TextSpan(
                text: 'سياسة الخصوصية',
                style: AppText.style(
                  size: 11,
                  weight: AppText.bold,
                  color: AppColors.brandPurple,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: AppText.style(size: 11, color: AppColors.textMuted),
        ),
      ),
    ),
  );
}
