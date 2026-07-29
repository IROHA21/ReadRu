import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// The user's answers from the 3 onboarding screens - which language they
/// speak (translation target), which language(s) their books are in
/// (translation source, per-book), and whether they've been through
/// onboarding at all yet.
class OnboardingSettings {
  final bool onboardingComplete;
  final TranslateLanguage? spokenLanguage;
  final List<TranslateLanguage> bookLanguages;

  const OnboardingSettings({
    this.onboardingComplete = false,
    this.spokenLanguage,
    this.bookLanguages = const [],
  });

  static const defaults = OnboardingSettings();

  OnboardingSettings copyWith({
    bool? onboardingComplete,
    TranslateLanguage? spokenLanguage,
    List<TranslateLanguage>? bookLanguages,
  }) {
    return OnboardingSettings(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      spokenLanguage: spokenLanguage ?? this.spokenLanguage,
      bookLanguages: bookLanguages ?? this.bookLanguages,
    );
  }

  Map<String, dynamic> toJson() => {
        'onboardingComplete': onboardingComplete,
        'spokenLanguage': spokenLanguage?.name,
        'bookLanguages': bookLanguages.map((l) => l.name).toList(),
      };

  factory OnboardingSettings.fromJson(Map<String, dynamic> json) {
    return OnboardingSettings(
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      spokenLanguage: _languageFromName(json['spokenLanguage'] as String?),
      bookLanguages: (json['bookLanguages'] as List<dynamic>?)
              ?.map((name) => _languageFromName(name as String?))
              .whereType<TranslateLanguage>()
              .toList() ??
          const [],
    );
  }

  static TranslateLanguage? _languageFromName(String? name) {
    if (name == null) return null;
    for (final language in TranslateLanguage.values) {
      if (language.name == name) return language;
    }
    return null;
  }
}
