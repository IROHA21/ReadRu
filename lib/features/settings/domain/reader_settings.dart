import 'package:flutter/material.dart';
import 'package:read_ru/features/settings/domain/reader_font.dart';

// Shared swatch palette for both the highlight and translation-text color
// pickers - kept small and named so users pick from meaningfully different
// choices instead of an infinite color wheel.
const List<Color> readerColorOptions = [
  Color(0xFFFFD54F), // yellow (default highlight)
  Color(0xFFFF8A65), // orange
  Color(0xFF81C784), // green
  Color(0xFF4FC3F7), // blue
  Color(0xFFBA68C8), // purple
  Color(0xFFE57373), // red
  Color(0xFF4DB6AC), // teal
  Color(0xFF2F5D4F), // app accent green
];

// Which physical swipe advances to the next page. leftToRight (default)
// matches standard LTR reading apps: swipe left (drag right-to-left) to
// advance. rightToLeft flips both swipes, for readers who prefer it.
enum PageSwipeDirection { leftToRight, rightToLeft }

// system (default) follows the phone's own light/dark setting live: main.dart
// maps this straight to Flutter's ThemeMode.system, which already tracks
// platform brightness changes with no polling of our own needed. light/dark
// are an explicit override for anyone who wants the app to ignore the OS.
enum AppThemeMode { system, light, dark }

class ReaderSettings {
  final double fontSize;
  final ReaderFont font;
  final AppThemeMode themeMode;
  final bool highlightEnabled;
  final Color highlightColor;
  final double translationFontSize;
  final Color translationColor;
  final PageSwipeDirection pageSwipeDirection;

  const ReaderSettings({
    this.fontSize = 16,
    this.font = ReaderFont.roboto,
    this.themeMode = AppThemeMode.system,
    this.highlightEnabled = true,
    this.highlightColor = const Color(0xFFFFD54F),
    this.translationFontSize = 12,
    this.translationColor = const Color(0xFF2F5D4F),
    this.pageSwipeDirection = PageSwipeDirection.leftToRight,
  });

  static const defaults = ReaderSettings();

  ReaderSettings copyWith({
    double? fontSize,
    ReaderFont? font,
    AppThemeMode? themeMode,
    bool? highlightEnabled,
    Color? highlightColor,
    double? translationFontSize,
    Color? translationColor,
    PageSwipeDirection? pageSwipeDirection,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      font: font ?? this.font,
      themeMode: themeMode ?? this.themeMode,
      highlightEnabled: highlightEnabled ?? this.highlightEnabled,
      highlightColor: highlightColor ?? this.highlightColor,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      translationColor: translationColor ?? this.translationColor,
      pageSwipeDirection: pageSwipeDirection ?? this.pageSwipeDirection,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'font': font.name,
      'themeMode': themeMode.name,
      'highlightEnabled': highlightEnabled,
      'highlightColor': highlightColor.toARGB32(),
      'translationFontSize': translationFontSize,
      'translationColor': translationColor.toARGB32(),
      'pageSwipeDirection': pageSwipeDirection.name,
    };
  }

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    return ReaderSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? defaults.fontSize,
      font: ReaderFont.values.firstWhere(
        (f) => f.name == json['font'],
        orElse: () => defaults.font,
      ),
      // Legacy installs only ever persisted the old isDarkMode bool - map
      // that explicit choice across so existing users don't get switched
      // to "system" (and a possibly different theme) out from under them.
      // A fresh install with neither key present gets the new system
      // default, which is the whole point of this change.
      themeMode: json['themeMode'] != null
          ? AppThemeMode.values.firstWhere(
              (m) => m.name == json['themeMode'],
              orElse: () => defaults.themeMode,
            )
          : (json['isDarkMode'] is bool
              ? (json['isDarkMode'] as bool ? AppThemeMode.dark : AppThemeMode.light)
              : defaults.themeMode),
      highlightEnabled: json['highlightEnabled'] as bool? ?? defaults.highlightEnabled,
      highlightColor: json['highlightColor'] is int
          ? Color(json['highlightColor'] as int)
          : defaults.highlightColor,
      translationFontSize:
          (json['translationFontSize'] as num?)?.toDouble() ?? defaults.translationFontSize,
      translationColor: json['translationColor'] is int
          ? Color(json['translationColor'] as int)
          : defaults.translationColor,
      pageSwipeDirection: PageSwipeDirection.values.firstWhere(
        (d) => d.name == json['pageSwipeDirection'],
        orElse: () => defaults.pageSwipeDirection,
      ),
    );
  }
}
