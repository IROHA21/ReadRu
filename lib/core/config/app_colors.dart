import 'package:flutter/material.dart';

class AppColors {
  final Color background;
  final Color card;
  final Color accent;
  final Color progressTrack;
  final Color textPrimary;
  final Color textSecondary;
  final Color thumbnailPlaceholder;

  const AppColors._({
    required this.background,
    required this.card,
    required this.accent,
    required this.progressTrack,
    required this.textPrimary,
    required this.textSecondary,
    required this.thumbnailPlaceholder,
  });

  static const light = AppColors._(
    background: Color(0xFFF3EEE3),
    card: Color(0xFFEAE3D3),
    accent: Color(0xFF2F5D4F),
    progressTrack: Color(0xFFD9D2C0),
    textPrimary: Color(0xFF1F1B16),
    textSecondary: Color(0xFF6B6459),
    thumbnailPlaceholder: Color(0xFFD3CCBB),
  );

  static const dark = AppColors._(
    background: Color(0xFF16150F),
    card: Color(0xFF232019),
    accent: Color(0xFF6FBF9B),
    progressTrack: Color(0xFF3A362B),
    textPrimary: Color(0xFFEDE7D9),
    textSecondary: Color(0xFFA39C8A),
    thumbnailPlaceholder: Color(0xFF3A362B),
  );

  // Reads brightness off the current Theme, which main.dart drives from
  // SettingsCubit's isDarkMode - so every screen stays in sync with the
  // night-mode setting without needing its own settings lookup.
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
