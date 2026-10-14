import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/parent_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/common.dart';
import '../widgets/account_controls.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.data,
    this.onLogout,
    this.showModalByDefault = false,
  });

  final ParentData data;
  final VoidCallback? onLogout;
  final bool showModalByDefault;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showLogoutModal = widget.showModalByDefault;

  /// يفتح محادثة واتساب مع رقم الإدارة (`whatsapp_number` من الإعدادات العامة).
  Future<void> _openWhatsapp(String number) async {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    final ok = await launchUrl(
      Uri.parse('https://wa.me/$digits'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب على هذا الجهاز')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parent = widget.data.parent;
    final parentName = parent?.name ?? 'ولي الأمر';
    final whatsapp = widget.data.settings.whatsappNumber;
    final schoolName = widget.data.settings.schoolName;

    return TabPageScroll(
      children: [
        // ---------------- Header ----------------
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإعدادات',
                style: AppText.style(size: 16, weight: AppText.extrabold),
              ),
              Text(
                'خيارات الحساب والتفضيلات',
                style: AppText.style(size: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------- Profile card ----------------
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: AppShadows.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.purple100),
                      ),
                      child: Text(
                        parentName.isEmpty ? '؟' : parentName.substring(0, 1),
                        style: AppText.style(
                          size: 18,
                          weight: AppText.bold,
                          color: AppColors.brandPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purple50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.shieldCheck,
                                  size: 12,
                                  color: AppColors.brandPurple,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ولي أمر معتمد',
                                  style: AppText.style(
                                    size: 8,
                                    weight: AppText.bold,
                                    color: AppColors.brandPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            parentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.style(
                              size: 12,
                              weight: AppText.bold,
                            ),
                          ),
                          // `dir="ltr"`: wrapped in an LTR isolate so the
                          // number keeps its order inside the RTL layout.
                          Text(
                            '\u2066${parent?.localPhone ?? ''}\u2069',
                            textDirection: TextDirection.ltr,
                            style: AppText.style(
                              size: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ---------------- Notifications ----------------
              const SizedBox(height: 8),
              const SettingsGroupLabel('الإشعارات'),
              NotificationsSettings(data: widget.data),

              // ---------------- Contact the school ----------------
              if (whatsapp != null && whatsapp.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SettingsGroupLabel('التواصل'),
                SettingsTile(
                  icon: LucideIcons.messageCircle,
                  iconBackground: AppColors.emerald50,
                  iconColor: AppColors.emerald600,
                  title: 'تواصل مع إدارة المدرسة',
                  subtitle: schoolName == null || schoolName.isEmpty
                      ? 'محادثة واتساب مع الإدارة'
                      : 'واتساب $schoolName',
                  onTap: () => _openWhatsapp(whatsapp),
                ),
              ],

              // ---------------- Account ----------------
              const SizedBox(height: 16),
              const SettingsGroupLabel('الحساب'),
              DeleteAccountTile(data: widget.data),

              // ---------------- Logout confirmation dialog ----------------
              if (_showLogoutModal || widget.showModalByDefault) ...[
                const SizedBox(height: 20),
                _LogoutDialog(
                  onLogout: widget.onLogout,
                  onCancel: () => setState(() => _showLogoutModal = false),
                ),
              ],

              // ---------------- Logout trigger ----------------
              if (!_showLogoutModal) ...[
                const SizedBox(height: 8),
                SettingsTile(
                  icon: LucideIcons.logOut,
                  iconBackground: AppColors.rose50,
                  iconColor: AppColors.rose600,
                  title: 'تسجيل الخروج',
                  titleColor: AppColors.rose600,
                  subtitle: 'الخروج من حساب ولي الأمر على هذا الهاتف',
                  onTap: () => setState(() => _showLogoutModal = true),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog({this.onLogout, required this.onCancel});

  final VoidCallback? onLogout;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.rose100, width: 2),
            boxShadow: AppShadows.lg,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.rose50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  LucideIcons.logOut,
                  size: 20,
                  color: AppColors.rose600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'نافذة تأكيد تسجيل الخروج',
                textAlign: TextAlign.center,
                style: AppText.style(size: 12, weight: AppText.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'هل أنت متأكد من رغبتك في تسجيل الخروج من حساب ولي الأمر؟',
                textAlign: TextAlign.center,
                style: AppText.style(
                  size: 10,
                  color: AppColors.textMuted,
                  height: 1.625,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Tap(
                      onTap: onLogout,
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.rose600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'تسجيل الخروج',
                          style: AppText.style(
                            size: 10,
                            weight: AppText.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Tap(
                      onTap: onCancel,
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppText.style(size: 10, weight: AppText.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
