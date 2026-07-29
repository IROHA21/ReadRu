import 'package:flutter/material.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:read_ru/features/settings/presentation/screens/reading_settings_screen.dart';
import 'package:read_ru/l10n/generated/app_localizations.dart';

// Settings hub: two folders. Reading covers everything about how the
// reader screen itself looks/behaves; Language covers app/goal language
// and offline pack management - split out since they're pretty different
// concerns and the second one didn't exist until AnyRead needed it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        children: [
          _SettingsFolder(
            icon: Icons.menu_book,
            title: l10n.readingFolderTitle,
            subtitle: l10n.readingFolderSubtitle,
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReadingSettingsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsFolder(
            icon: Icons.translate,
            title: l10n.languageFolderTitle,
            subtitle: l10n.languageFolderSubtitle,
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsFolder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AppColors colors;
  final VoidCallback onTap;

  const _SettingsFolder({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
