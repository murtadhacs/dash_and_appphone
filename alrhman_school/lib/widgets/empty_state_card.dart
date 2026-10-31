import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Generic "nothing to show yet" card.
///
/// Used wherever a screen's data comes back empty from the backend (no
/// student linked to the account, no schedule published yet, ...) instead
/// of the previous hardcoded placeholder content.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor = AppColors.brandPurple,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.style(size: 12, weight: AppText.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppText.style(
                size: 10,
                color: AppColors.textMuted,
                height: 1.625,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
