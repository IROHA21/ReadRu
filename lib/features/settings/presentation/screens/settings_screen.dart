import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/settings/domain/reader_font.dart';
import 'package:read_ru/features/settings/domain/reader_settings.dart';
import 'package:read_ru/features/settings/presentation/cubit/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final settingsCubit = getIt<SettingsCubit>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsCubit, ReaderSettings>(
        bloc: settingsCubit,
        builder: (context, settings) {
          return Column(
            children: [
              Expanded(
                child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _SectionLabel('Text size', colors),
              Row(
                children: [
                  Text('A', style: TextStyle(fontSize: 14, color: colors.textSecondary)),
                  Expanded(
                    child: Slider(
                      value: settings.fontSize,
                      min: 12,
                      max: 28,
                      activeColor: colors.accent,
                      onChanged: (value) => settingsCubit.setFontSize(value),
                    ),
                  ),
                  Text('A', style: TextStyle(fontSize: 24, color: colors.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              _SectionLabel('Font', colors),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final font in ReaderFont.values)
                    ChoiceChip(
                      label: Text(font.label, style: font.apply(const TextStyle())),
                      selected: settings.font == font,
                      selectedColor: colors.accent.withValues(alpha: 0.25),
                      onSelected: (_) => settingsCubit.setFont(font),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel('Night mode', colors),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Dark theme', style: TextStyle(color: colors.textPrimary)),
                value: settings.isDarkMode,
                activeThumbColor: colors.accent,
                onChanged: (value) => settingsCubit.setDarkMode(value),
              ),
              const SizedBox(height: 12),
              _SectionLabel('Tap-to-translate highlight', colors),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Highlight tapped words', style: TextStyle(color: colors.textPrimary)),
                value: settings.highlightEnabled,
                activeThumbColor: colors.accent,
                onChanged: (value) => settingsCubit.setHighlightEnabled(value),
              ),
              AnimatedOpacity(
                opacity: settings.highlightEnabled ? 1 : 0.4,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: !settings.highlightEnabled,
                  child: _ColorSwatchRow(
                    selected: settings.highlightColor,
                    onSelected: settingsCubit.setHighlightColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel('Translation text', colors),
              Row(
                children: [
                  Text('Size', style: TextStyle(color: colors.textSecondary)),
                  Expanded(
                    child: Slider(
                      value: settings.translationFontSize,
                      min: 8,
                      max: 20,
                      activeColor: colors.accent,
                      onChanged: (value) => settingsCubit.setTranslationFontSize(value),
                    ),
                  ),
                ],
              ),
              _ColorSwatchRow(
                selected: settings.translationColor,
                onSelected: settingsCubit.setTranslationColor,
              ),
              const SizedBox(height: 20),
              _SectionLabel('Page turn direction', colors),
              SegmentedButton<PageSwipeDirection>(
                segments: const [
                  ButtonSegment(
                    value: PageSwipeDirection.leftToRight,
                    label: Text('Left to right'),
                  ),
                  ButtonSegment(
                    value: PageSwipeDirection.rightToLeft,
                    label: Text('Right to left'),
                  ),
                ],
                selected: {settings.pageSwipeDirection},
                onSelectionChanged: (selection) =>
                    settingsCubit.setPageSwipeDirection(selection.first),
              ),
                  ],
                ),
              ),
              // Fixed footer, not part of the scrolling list above - always
              // visible so you can see the effect of whatever you're
              // adjusting without scrolling down to check.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: colors.card,
                  border: Border(top: BorderSide(color: colors.progressTrack)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Привет, как дела?',
                        style: settings.font.apply(TextStyle(
                          fontSize: settings.fontSize,
                          color: colors.textPrimary,
                          backgroundColor:
                              settings.highlightEnabled ? settings.highlightColor.withValues(alpha: 0.55) : null,
                        )),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'hello, how are you',
                        style: TextStyle(
                          fontSize: settings.translationFontSize,
                          color: settings.translationColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColors colors;

  const _SectionLabel(this.label, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onSelected;

  const _ColorSwatchRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in readerColorOptions)
          GestureDetector(
            onTap: () => onSelected(color),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected.toARGB32() == color.toARGB32() ? Colors.black : Colors.transparent,
                  width: 2,
                ),
              ),
              child: selected.toARGB32() == color.toARGB32()
                  ? const Icon(Icons.check, size: 18, color: Colors.black)
                  : null,
            ),
          ),
      ],
    );
  }
}
