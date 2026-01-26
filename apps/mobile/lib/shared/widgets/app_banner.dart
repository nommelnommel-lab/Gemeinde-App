import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

enum AppBannerSeverity {
  info,
  warning,
  critical,
}

class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.title,
    this.description,
    this.severity = AppBannerSeverity.info,
    this.onTap,
    this.action,
  });

  final String title;
  final String? description;
  final AppBannerSeverity severity;
  final VoidCallback? onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _BannerColors.fromSeverity(theme, severity);
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(colors.icon, color: colors.iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.textColor,
                ),
              ),
              if (description != null && description!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textColor.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: colors.borderColor),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: content,
      ),
    );
  }
}

class _BannerColors {
  const _BannerColors({
    required this.background,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.iconBackground,
    required this.icon,
  });

  final Color background;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final Color iconBackground;
  final IconData icon;

  factory _BannerColors.fromSeverity(ThemeData theme, AppBannerSeverity severity) {
    switch (severity) {
      case AppBannerSeverity.info:
        return _BannerColors(
          background: const Color(0xFFE6F4F1),
          borderColor: const Color(0xFFBFE5DF),
          textColor: theme.colorScheme.onSurface,
          iconColor: AppTheme.primaryTeal,
          iconBackground: const Color(0xFFCCE9E5),
          icon: Icons.info_outline,
        );
      case AppBannerSeverity.warning:
        return _BannerColors(
          background: const Color(0xFFFFF2E5),
          borderColor: const Color(0xFFFAD8B0),
          textColor: theme.colorScheme.onSurface,
          iconColor: const Color(0xFFB8561B),
          iconBackground: const Color(0xFFFBE0C2),
          icon: Icons.warning_amber_outlined,
        );
      case AppBannerSeverity.critical:
        return _BannerColors(
          background: const Color(0xFFFCE8E6),
          borderColor: const Color(0xFFF5B8B2),
          textColor: theme.colorScheme.onSurface,
          iconColor: const Color(0xFFB42318),
          iconBackground: const Color(0xFFF8C9C4),
          icon: Icons.report,
        );
    }
  }
}
