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

class ReaderSettings {
  final double fontSize;
  final ReaderFont font;
  final bool isDarkMode;
  final bool highlightEnabled;
  final Color highlightColor;
  final double translationFontSize;
  final Color translationColor;
  final PageSwipeDirection pageSwipeDirection;

  const ReaderSettings({
    this.fontSize = 16,
    this.font = ReaderFont.roboto,
    this.isDarkMode = false,
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
    bool? isDarkMode,
    bool? highlightEnabled,
    Color? highlightColor,
    double? translationFontSize,
    Color? translationColor,
    PageSwipeDirection? pageSwipeDirection,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      font: font ?? this.font,
      isDarkMode: isDarkMode ?? this.isDarkMode,
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
      'isDarkMode': isDarkMode,
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
      isDarkMode: json['isDarkMode'] as bool? ?? defaults.isDarkMode,
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
