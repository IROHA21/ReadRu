// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get back => 'Back';

  @override
  String get continueButton => 'Continue';

  @override
  String get download => 'Download';

  @override
  String get downloading => 'Downloading...';

  @override
  String get close => 'Close';

  @override
  String get title => 'Title';

  @override
  String get searchLanguages => 'Search languages';

  @override
  String get showMoreLanguages => 'Show more';

  @override
  String get chapters => 'Chapters';

  @override
  String get format => 'Format';

  @override
  String get fileSize => 'File size';

  @override
  String get progress => 'Progress';

  @override
  String get description => 'Description';

  @override
  String get author => 'Author';

  @override
  String get later => 'Later';

  @override
  String get libraryTitle => 'Library';

  @override
  String get wordBucketTooltip => 'Word Bucket';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get libraryEmptyState => 'Add your first document to begin reading.';

  @override
  String get downloadLanguagePackTitle => 'Download language pack?';

  @override
  String downloadLanguagePackContent(Object title, Object language) {
    return '\"$title\" is in $language. Download the offline translation pack now so tap-to-translate works without internet?';
  }

  @override
  String get infoMenuItem => 'Info';

  @override
  String get renameMenuItem => 'Rename';

  @override
  String get renameBookTitle => 'Rename book';

  @override
  String get deleteDocumentTitle => 'Delete document?';

  @override
  String deleteDocumentContent(Object title) {
    return '\"$title\" will be removed from your library.';
  }

  @override
  String bookAlreadyExists(Object title) {
    return 'A book named \"$title\" already exists';
  }

  @override
  String get chaptersTooltip => 'Chapters';

  @override
  String get readingSettingsTooltip => 'Reading settings';

  @override
  String get pageCounterUnknown => '- / -';

  @override
  String pageCounter(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String chapterPageLabel(Object page) {
    return 'p. $page';
  }

  @override
  String get cancelSelectionTooltip => 'Cancel selection';

  @override
  String wordsSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words selected',
      one: '1 word selected',
    );
    return '$_temp0';
  }

  @override
  String get translateButton => 'Translate';

  @override
  String get saved => 'Saved';

  @override
  String get saveToWordBucket => 'Save to Word Bucket';

  @override
  String get translationFailed => '(failed)';

  @override
  String get translationUnsupported => '(language not supported)';

  @override
  String get readingFolderTitle => 'Reading';

  @override
  String get readingFolderSubtitle =>
      'Font, size, night mode, highlight color, page turns';

  @override
  String get languageFolderTitle => 'Language';

  @override
  String get languageFolderSubtitle =>
      'App language, goal language(s), offline packs';

  @override
  String get textSizeLabel => 'Text size';

  @override
  String get letterA => 'A';

  @override
  String get fontLabel => 'Font';

  @override
  String get nightModeLabel => 'Night mode';

  @override
  String get darkThemeLabel => 'Dark theme';

  @override
  String get tapHighlightLabel => 'Tap-to-translate highlight';

  @override
  String get highlightTappedWordsLabel => 'Highlight tapped words';

  @override
  String get translationTextLabel => 'Translation text';

  @override
  String get sizeLabel => 'Size';

  @override
  String get pageTurnDirectionLabel => 'Page turn direction';

  @override
  String get leftToRight => 'Left to right';

  @override
  String get rightToLeft => 'Right to left';

  @override
  String get appLanguageLabel => 'App language';

  @override
  String get appLanguageDescription => 'Translations go into this language.';

  @override
  String get goalLanguageLabel => 'Goal language(s)';

  @override
  String get goalLanguageDescription => 'The language(s) your books are in.';

  @override
  String get addLanguageChip => 'Add language';

  @override
  String get offlinePacksLabel => 'Offline language packs';

  @override
  String get offlinePacksDescription =>
      'Starred languages are your current app/goal languages. Download or delete any pack.';

  @override
  String get addLanguageSheetTitle => 'Add a language';

  @override
  String packsReadySummary(Object ready, Object total, Object mb) {
    return '$ready of $total ready · ~$mb MB total (estimated)';
  }

  @override
  String get checkingStatus => 'Checking...';

  @override
  String downloadingStatus(Object seconds) {
    return 'Downloading... ${seconds}s';
  }

  @override
  String get downloadedStatus => 'Downloaded';

  @override
  String get downloadFailedStatus => 'Download failed - tap to retry';

  @override
  String notDownloadedStatus(Object mb) {
    return '~$mb MB · not downloaded';
  }

  @override
  String get deletePackTooltip => 'Delete downloaded pack';

  @override
  String get spokenLanguageStepTitle => 'What language do you speak?';

  @override
  String get spokenLanguageStepSubtitle =>
      'We\'ll translate books into this language.';

  @override
  String get bookLanguageStepTitle => 'What languages are your books in?';

  @override
  String get bookLanguageStepSubtitle =>
      'Pick every language you read in - you can change this per book later.';

  @override
  String get downloadStepTitle => 'Download offline translation';

  @override
  String get downloadStepSubtitle =>
      'Download these language packs so translation works fully offline afterward. You can skip this and do it later in Settings.';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get downloadPackScreenTitle => 'Download Language Pack';

  @override
  String get wordBucketTitle => 'Word Bucket';

  @override
  String get showAllWords => 'Show all words';

  @override
  String get groupByBook => 'Group by book';

  @override
  String get wordBucketEmptyState =>
      'Tap words while reading to save their translations here.';

  @override
  String get bookInfoTitle => 'Book Info';

  @override
  String get languageNotSet => 'Not set - tap to choose';

  @override
  String languageNotSupported(Object flag, Object code) {
    return '$flag $code (not supported for translation)';
  }

  @override
  String get languageOfBookLabel => 'Language of the book';
}
