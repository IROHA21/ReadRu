// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get back => 'Zurück';

  @override
  String get continueButton => 'Weiter';

  @override
  String get download => 'Herunterladen';

  @override
  String get downloading => 'Wird heruntergeladen...';

  @override
  String get close => 'Schließen';

  @override
  String get title => 'Titel';

  @override
  String get searchLanguages => 'Sprachen suchen';

  @override
  String get showMoreLanguages => 'Mehr anzeigen';

  @override
  String get chapters => 'Kapitel';

  @override
  String get format => 'Format';

  @override
  String get fileSize => 'Dateigröße';

  @override
  String get progress => 'Fortschritt';

  @override
  String get description => 'Beschreibung';

  @override
  String get author => 'Autor';

  @override
  String get later => 'Später';

  @override
  String get libraryTitle => 'Bibliothek';

  @override
  String get wordBucketTooltip => 'Wortkorb';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get libraryEmptyState =>
      'Füge dein erstes Dokument hinzu, um mit dem Lesen zu beginnen.';

  @override
  String get downloadLanguagePackTitle => 'Sprachpaket herunterladen?';

  @override
  String downloadLanguagePackContent(Object title, Object language) {
    return '„$title\" ist auf $language. Jetzt das Offline-Übersetzungspaket herunterladen, damit die Tipp-Übersetzung ohne Internet funktioniert?';
  }

  @override
  String get infoMenuItem => 'Info';

  @override
  String get renameMenuItem => 'Umbenennen';

  @override
  String get renameBookTitle => 'Buch umbenennen';

  @override
  String get deleteDocumentTitle => 'Dokument löschen?';

  @override
  String deleteDocumentContent(Object title) {
    return '„$title\" wird aus deiner Bibliothek entfernt.';
  }

  @override
  String bookAlreadyExists(Object title) {
    return 'Ein Buch namens „$title\" existiert bereits';
  }

  @override
  String get chaptersTooltip => 'Kapitel';

  @override
  String get readingSettingsTooltip => 'Leseeinstellungen';

  @override
  String get pageCounterUnknown => '- / -';

  @override
  String pageCounter(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String chapterPageLabel(Object page) {
    return 'S. $page';
  }

  @override
  String get cancelSelectionTooltip => 'Auswahl abbrechen';

  @override
  String wordsSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter ausgewählt',
      one: '1 Wort ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get translateButton => 'Übersetzen';

  @override
  String get saved => 'Gespeichert';

  @override
  String get saveToWordBucket => 'Im Wortkorb speichern';

  @override
  String get translationFailed => '(fehlgeschlagen)';

  @override
  String get translationUnsupported => '(Sprache nicht unterstützt)';

  @override
  String get offlineTranslationWarning =>
      'Keine Internetverbindung - Übersetzungen sind möglicherweise weniger genau.';

  @override
  String get readingFolderTitle => 'Lesen';

  @override
  String get readingFolderSubtitle =>
      'Schrift, Größe, Nachtmodus, Markierungsfarbe, Seitenwechsel';

  @override
  String get languageFolderTitle => 'Sprache';

  @override
  String get languageFolderSubtitle =>
      'App-Sprache, Zielsprache(n), Offline-Pakete';

  @override
  String get textSizeLabel => 'Textgröße';

  @override
  String get letterA => 'A';

  @override
  String get fontLabel => 'Schriftart';

  @override
  String get nightModeLabel => 'Nachtmodus';

  @override
  String get darkThemeLabel => 'Dunkles Design';

  @override
  String get tapHighlightLabel => 'Markierung bei Tipp-Übersetzung';

  @override
  String get highlightTappedWordsLabel => 'Angetippte Wörter markieren';

  @override
  String get translationTextLabel => 'Übersetzungstext';

  @override
  String get sizeLabel => 'Größe';

  @override
  String get pageTurnDirectionLabel => 'Seitenwechselrichtung';

  @override
  String get leftToRight => 'Links nach rechts';

  @override
  String get rightToLeft => 'Rechts nach links';

  @override
  String get appLanguageLabel => 'App-Sprache';

  @override
  String get appLanguageDescription =>
      'Übersetzungen erfolgen in diese Sprache.';

  @override
  String get goalLanguageLabel => 'Zielsprache(n)';

  @override
  String get goalLanguageDescription => 'Die Sprache(n) deiner Bücher.';

  @override
  String get addLanguageChip => 'Sprache hinzufügen';

  @override
  String get offlinePacksLabel => 'Offline-Sprachpakete';

  @override
  String get offlinePacksDescription =>
      'Markierte Sprachen sind deine aktuellen App-/Zielsprachen. Lade beliebige Pakete herunter oder lösche sie.';

  @override
  String get addLanguageSheetTitle => 'Eine Sprache hinzufügen';

  @override
  String packsReadySummary(Object ready, Object total, Object mb) {
    return '$ready von $total bereit · ~$mb MB insgesamt (geschätzt)';
  }

  @override
  String get checkingStatus => 'Wird geprüft...';

  @override
  String downloadingStatus(Object seconds) {
    return 'Wird heruntergeladen... ${seconds}s';
  }

  @override
  String get downloadedStatus => 'Heruntergeladen';

  @override
  String get downloadFailedStatus =>
      'Download fehlgeschlagen - zum Wiederholen tippen';

  @override
  String notDownloadedStatus(Object mb) {
    return '~$mb MB · nicht heruntergeladen';
  }

  @override
  String get deletePackTooltip => 'Heruntergeladenes Paket löschen';

  @override
  String get spokenLanguageStepTitle => 'Welche Sprache sprichst du?';

  @override
  String get spokenLanguageStepSubtitle =>
      'Wir übersetzen Bücher in diese Sprache.';

  @override
  String get bookLanguageStepTitle => 'In welchen Sprachen sind deine Bücher?';

  @override
  String get bookLanguageStepSubtitle =>
      'Wähle jede Sprache, die du liest - du kannst dies später pro Buch ändern.';

  @override
  String get downloadStepTitle => 'Offline-Übersetzung herunterladen';

  @override
  String get downloadStepSubtitle =>
      'Lade diese Sprachpakete herunter, damit die Übersetzung danach vollständig offline funktioniert. Du kannst dies überspringen und später in den Einstellungen erledigen.';

  @override
  String get skipForNow => 'Vorerst überspringen';

  @override
  String get downloadPackScreenTitle => 'Sprachpaket herunterladen';

  @override
  String get wordBucketTitle => 'Wortkorb';

  @override
  String get showAllWords => 'Alle Wörter anzeigen';

  @override
  String get groupByBook => 'Nach Buch gruppieren';

  @override
  String get wordBucketEmptyState =>
      'Tippe beim Lesen auf Wörter, um ihre Übersetzungen hier zu speichern.';

  @override
  String get bookInfoTitle => 'Buchinfo';

  @override
  String get languageNotSet => 'Nicht festgelegt - zum Auswählen tippen';

  @override
  String languageNotSupported(Object flag, Object code) {
    return '$flag $code (Übersetzung nicht unterstützt)';
  }

  @override
  String get languageOfBookLabel => 'Sprache des Buchs';
}
