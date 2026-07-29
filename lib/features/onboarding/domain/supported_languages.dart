import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Display name for a language ML Kit can translate on-device - every enum
/// value is a single capitalized English word (Afrikaans, Chinese, Welsh,
/// ...), so this just title-cases the enum's own name instead of hand-
/// transcribing 59 names that would only drift out of sync later.
String translateLanguageName(TranslateLanguage language) {
  final name = language.name;
  return name[0].toUpperCase() + name.substring(1);
}

// PROVISIONAL - the spec calls for the "7 most popular" languages based on
// target-market research that hasn't happened yet. This is a placeholder
// so onboarding has something to show; swap it out once that research
// lands (see project handoff, "still open" section).
const List<TranslateLanguage> popularSpokenLanguages = [
  TranslateLanguage.english,
  TranslateLanguage.spanish,
  TranslateLanguage.french,
  TranslateLanguage.german,
  TranslateLanguage.portuguese,
  TranslateLanguage.russian,
  TranslateLanguage.chinese,
];

// The book/learning-language screen offers the full on-device-translatable
// set, sorted for a picker - this is the "any language" half of the pitch,
// not limited to the 7 the UI itself is localized into.
List<TranslateLanguage> get allSupportedLanguages =>
    List<TranslateLanguage>.of(TranslateLanguage.values)
      ..sort((a, b) => translateLanguageName(a).compareTo(translateLanguageName(b)));

/// Maps a BCP-47 tag (from Document.language, or the device locale) to a
/// TranslateLanguage - null means ML Kit doesn't support it, which is the
/// single source of truth for "translation isn't available for this book".
/// Only matches the primary subtag, since metadata/locales often come as
/// "en-US" or "ru-RU" while TranslateLanguage only distinguishes the base
/// language.
TranslateLanguage? translateLanguageFromCode(String? bcpTag) {
  if (bcpTag == null || bcpTag.trim().isEmpty) return null;
  final primary = bcpTag.trim().toLowerCase().split(RegExp(r'[-_]')).first;
  return BCP47Code.fromRawValue(primary);
}
