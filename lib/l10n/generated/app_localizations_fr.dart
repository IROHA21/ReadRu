// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get back => 'Retour';

  @override
  String get continueButton => 'Continuer';

  @override
  String get download => 'Télécharger';

  @override
  String get downloading => 'Téléchargement...';

  @override
  String get close => 'Fermer';

  @override
  String get title => 'Titre';

  @override
  String get searchLanguages => 'Rechercher des langues';

  @override
  String get showMoreLanguages => 'Afficher plus';

  @override
  String get chapters => 'Chapitres';

  @override
  String get format => 'Format';

  @override
  String get fileSize => 'Taille du fichier';

  @override
  String get progress => 'Progression';

  @override
  String get description => 'Description';

  @override
  String get author => 'Auteur';

  @override
  String get later => 'Plus tard';

  @override
  String get libraryTitle => 'Bibliothèque';

  @override
  String get wordBucketTooltip => 'Panier de mots';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get libraryEmptyState =>
      'Ajoutez votre premier document pour commencer à lire.';

  @override
  String get downloadLanguagePackTitle => 'Télécharger le pack de langue ?';

  @override
  String downloadLanguagePackContent(Object title, Object language) {
    return '«$title» est en $language. Télécharger le pack de traduction hors ligne maintenant pour que la traduction au toucher fonctionne sans internet ?';
  }

  @override
  String get infoMenuItem => 'Infos';

  @override
  String get renameMenuItem => 'Renommer';

  @override
  String get renameBookTitle => 'Renommer le livre';

  @override
  String get deleteDocumentTitle => 'Supprimer le document ?';

  @override
  String deleteDocumentContent(Object title) {
    return '«$title» sera retiré de votre bibliothèque.';
  }

  @override
  String bookAlreadyExists(Object title) {
    return 'Un livre nommé «$title» existe déjà';
  }

  @override
  String get chaptersTooltip => 'Chapitres';

  @override
  String get readingSettingsTooltip => 'Paramètres de lecture';

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
  String get cancelSelectionTooltip => 'Annuler la sélection';

  @override
  String wordsSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots sélectionnés',
      one: '1 mot sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get translateButton => 'Traduire';

  @override
  String get saved => 'Enregistré';

  @override
  String get saveToWordBucket => 'Enregistrer dans le panier de mots';

  @override
  String get translationFailed => '(échec)';

  @override
  String get translationUnsupported => '(langue non prise en charge)';

  @override
  String get offlineTranslationWarning =>
      'Aucune connexion internet - les traductions peuvent être moins précises.';

  @override
  String get readingFolderTitle => 'Lecture';

  @override
  String get readingFolderSubtitle =>
      'Police, taille, mode nuit, couleur de surlignage, changement de page';

  @override
  String get languageFolderTitle => 'Langue';

  @override
  String get languageFolderSubtitle =>
      'Langue de l\'app, langue(s) cible, packs hors ligne';

  @override
  String get textSizeLabel => 'Taille du texte';

  @override
  String get letterA => 'A';

  @override
  String get fontLabel => 'Police';

  @override
  String get nightModeLabel => 'Mode nuit';

  @override
  String get darkThemeLabel => 'Thème sombre';

  @override
  String get tapHighlightLabel => 'Surlignage au toucher pour traduire';

  @override
  String get highlightTappedWordsLabel => 'Surligner les mots touchés';

  @override
  String get translationTextLabel => 'Texte de traduction';

  @override
  String get sizeLabel => 'Taille';

  @override
  String get pageTurnDirectionLabel => 'Sens de changement de page';

  @override
  String get leftToRight => 'Gauche à droite';

  @override
  String get rightToLeft => 'Droite à gauche';

  @override
  String get appLanguageLabel => 'Langue de l\'app';

  @override
  String get appLanguageDescription =>
      'Les traductions se feront dans cette langue.';

  @override
  String get goalLanguageLabel => 'Langue(s) cible';

  @override
  String get goalLanguageDescription => 'La ou les langues de vos livres.';

  @override
  String get addLanguageChip => 'Ajouter une langue';

  @override
  String get offlinePacksLabel => 'Packs de langues hors ligne';

  @override
  String get offlinePacksDescription =>
      'Les langues étoilées sont vos langues actuelles d\'app/cible. Téléchargez ou supprimez n\'importe quel pack.';

  @override
  String get addLanguageSheetTitle => 'Ajouter une langue';

  @override
  String packsReadySummary(Object ready, Object total, Object mb) {
    return '$ready sur $total prêt(s) · ~$mb Mo au total (estimé)';
  }

  @override
  String get checkingStatus => 'Vérification...';

  @override
  String downloadingStatus(Object seconds) {
    return 'Téléchargement... ${seconds}s';
  }

  @override
  String get downloadedStatus => 'Téléchargé';

  @override
  String get downloadFailedStatus =>
      'Échec du téléchargement - touchez pour réessayer';

  @override
  String notDownloadedStatus(Object mb) {
    return '~$mb Mo · non téléchargé';
  }

  @override
  String get deletePackTooltip => 'Supprimer le pack téléchargé';

  @override
  String get spokenLanguageStepTitle => 'Quelle langue parlez-vous ?';

  @override
  String get spokenLanguageStepSubtitle =>
      'Nous traduirons les livres dans cette langue.';

  @override
  String get bookLanguageStepTitle => 'Dans quelles langues sont vos livres ?';

  @override
  String get bookLanguageStepSubtitle =>
      'Choisissez toutes les langues que vous lisez - vous pourrez changer cela par livre plus tard.';

  @override
  String get downloadStepTitle => 'Télécharger la traduction hors ligne';

  @override
  String get downloadStepSubtitle =>
      'Téléchargez ces packs de langue pour que la traduction fonctionne entièrement hors ligne ensuite. Vous pouvez ignorer cette étape et le faire plus tard dans Paramètres.';

  @override
  String get skipForNow => 'Ignorer pour l\'instant';

  @override
  String get downloadPackScreenTitle => 'Télécharger le pack de langue';

  @override
  String get wordBucketTitle => 'Panier de mots';

  @override
  String get showAllWords => 'Afficher tous les mots';

  @override
  String get groupByBook => 'Grouper par livre';

  @override
  String get wordBucketEmptyState =>
      'Touchez des mots pendant la lecture pour enregistrer leurs traductions ici.';

  @override
  String get bookInfoTitle => 'Infos du livre';

  @override
  String get languageNotSet => 'Non défini - touchez pour choisir';

  @override
  String languageNotSupported(Object flag, Object code) {
    return '$flag $code (traduction non prise en charge)';
  }

  @override
  String get languageOfBookLabel => 'Langue du livre';
}
