import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @searchLanguages.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get searchLanguages;

  /// No description provided for @showMoreLanguages.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMoreLanguages;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get fileSize;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @wordBucketTooltip.
  ///
  /// In en, this message translates to:
  /// **'Word Bucket'**
  String get wordBucketTooltip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @libraryEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Add your first document to begin reading.'**
  String get libraryEmptyState;

  /// No description provided for @downloadLanguagePackTitle.
  ///
  /// In en, this message translates to:
  /// **'Download language pack?'**
  String get downloadLanguagePackTitle;

  /// No description provided for @downloadLanguagePackContent.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is in {language}. Download the offline translation pack now so tap-to-translate works without internet?'**
  String downloadLanguagePackContent(Object title, Object language);

  /// No description provided for @infoMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get infoMenuItem;

  /// No description provided for @renameMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameMenuItem;

  /// No description provided for @renameBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename book'**
  String get renameBookTitle;

  /// No description provided for @deleteDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete document?'**
  String get deleteDocumentTitle;

  /// No description provided for @deleteDocumentContent.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed from your library.'**
  String deleteDocumentContent(Object title);

  /// No description provided for @bookAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A book named \"{title}\" already exists'**
  String bookAlreadyExists(Object title);

  /// No description provided for @chaptersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chaptersTooltip;

  /// No description provided for @readingSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reading settings'**
  String get readingSettingsTooltip;

  /// No description provided for @pageCounterUnknown.
  ///
  /// In en, this message translates to:
  /// **'- / -'**
  String get pageCounterUnknown;

  /// No description provided for @pageCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String pageCounter(Object current, Object total);

  /// No description provided for @chapterPageLabel.
  ///
  /// In en, this message translates to:
  /// **'p. {page}'**
  String chapterPageLabel(Object page);

  /// No description provided for @cancelSelectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get cancelSelectionTooltip;

  /// No description provided for @wordsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 word selected} other{{count} words selected}}'**
  String wordsSelected(num count);

  /// No description provided for @translateButton.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translateButton;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saveToWordBucket.
  ///
  /// In en, this message translates to:
  /// **'Save to Word Bucket'**
  String get saveToWordBucket;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'(failed)'**
  String get translationFailed;

  /// No description provided for @translationUnsupported.
  ///
  /// In en, this message translates to:
  /// **'(language not supported)'**
  String get translationUnsupported;

  /// No description provided for @offlineTranslationWarning.
  ///
  /// In en, this message translates to:
  /// **'No internet connection - translations may be less accurate.'**
  String get offlineTranslationWarning;

  /// No description provided for @offlineTranslationWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineTranslationWarningTitle;

  /// No description provided for @readingFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingFolderTitle;

  /// No description provided for @readingFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Font, size, night mode, highlight color, page turns'**
  String get readingFolderSubtitle;

  /// No description provided for @languageFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageFolderTitle;

  /// No description provided for @languageFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App language, goal language(s), offline packs'**
  String get languageFolderSubtitle;

  /// No description provided for @settingsRemoveAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get settingsRemoveAdsTitle;

  /// No description provided for @settingsRemoveAdsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase, no more ads'**
  String get settingsRemoveAdsSubtitle;

  /// No description provided for @textSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeLabel;

  /// No description provided for @letterA.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get letterA;

  /// No description provided for @fontLabel.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get fontLabel;

  /// No description provided for @nightModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get nightModeLabel;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @tapHighlightLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap-to-translate highlight'**
  String get tapHighlightLabel;

  /// No description provided for @highlightTappedWordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Highlight tapped words'**
  String get highlightTappedWordsLabel;

  /// No description provided for @translationTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Translation text'**
  String get translationTextLabel;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// No description provided for @pageTurnDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Page turn direction'**
  String get pageTurnDirectionLabel;

  /// No description provided for @leftToRight.
  ///
  /// In en, this message translates to:
  /// **'Left to right'**
  String get leftToRight;

  /// No description provided for @rightToLeft.
  ///
  /// In en, this message translates to:
  /// **'Right to left'**
  String get rightToLeft;

  /// No description provided for @appLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguageLabel;

  /// No description provided for @appLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Translations go into this language.'**
  String get appLanguageDescription;

  /// No description provided for @goalLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal language(s)'**
  String get goalLanguageLabel;

  /// No description provided for @goalLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'The language(s) your books are in.'**
  String get goalLanguageDescription;

  /// No description provided for @addLanguageChip.
  ///
  /// In en, this message translates to:
  /// **'Add language'**
  String get addLanguageChip;

  /// No description provided for @offlinePacksLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline language packs'**
  String get offlinePacksLabel;

  /// No description provided for @offlinePacksDescription.
  ///
  /// In en, this message translates to:
  /// **'Starred languages are your current app/goal languages. Download or delete any pack.'**
  String get offlinePacksDescription;

  /// No description provided for @addLanguageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a language'**
  String get addLanguageSheetTitle;

  /// No description provided for @packsReadySummary.
  ///
  /// In en, this message translates to:
  /// **'{ready} of {total} ready · ~{mb} MB total (estimated)'**
  String packsReadySummary(Object ready, Object total, Object mb);

  /// No description provided for @checkingStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checkingStatus;

  /// No description provided for @downloadingStatus.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {seconds}s'**
  String downloadingStatus(Object seconds);

  /// No description provided for @downloadedStatus.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadedStatus;

  /// No description provided for @downloadFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'Download failed - tap to retry'**
  String get downloadFailedStatus;

  /// No description provided for @notDownloadedStatus.
  ///
  /// In en, this message translates to:
  /// **'~{mb} MB · not downloaded'**
  String notDownloadedStatus(Object mb);

  /// No description provided for @deletePackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete downloaded pack'**
  String get deletePackTooltip;

  /// No description provided for @spokenLanguageStepTitle.
  ///
  /// In en, this message translates to:
  /// **'What language do you speak?'**
  String get spokenLanguageStepTitle;

  /// No description provided for @spokenLanguageStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll translate books into this language.'**
  String get spokenLanguageStepSubtitle;

  /// No description provided for @bookLanguageStepTitle.
  ///
  /// In en, this message translates to:
  /// **'What languages are your books in?'**
  String get bookLanguageStepTitle;

  /// No description provided for @bookLanguageStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick every language you read in - you can change this per book later.'**
  String get bookLanguageStepSubtitle;

  /// No description provided for @downloadStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Download offline translation'**
  String get downloadStepTitle;

  /// No description provided for @downloadStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download these language packs so translation works fully offline afterward. You can skip this and do it later in Settings.'**
  String get downloadStepSubtitle;

  /// No description provided for @downloadMinimumRequired.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Download at least 1 language to continue.} other{Download at least {count} languages to continue.}}'**
  String downloadMinimumRequired(num count);

  /// No description provided for @downloadPackScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Language Pack'**
  String get downloadPackScreenTitle;

  /// No description provided for @wordBucketTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Bucket'**
  String get wordBucketTitle;

  /// No description provided for @showAllWords.
  ///
  /// In en, this message translates to:
  /// **'Show all words'**
  String get showAllWords;

  /// No description provided for @groupByBook.
  ///
  /// In en, this message translates to:
  /// **'Group by book'**
  String get groupByBook;

  /// No description provided for @wordBucketEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Tap words while reading to save their translations here.'**
  String get wordBucketEmptyState;

  /// No description provided for @bookInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Info'**
  String get bookInfoTitle;

  /// No description provided for @languageNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set - tap to choose'**
  String get languageNotSet;

  /// No description provided for @languageNotSupported.
  ///
  /// In en, this message translates to:
  /// **'{flag} {code} (not supported for translation)'**
  String languageNotSupported(Object flag, Object code);

  /// No description provided for @languageOfBookLabel.
  ///
  /// In en, this message translates to:
  /// **'Language of the book'**
  String get languageOfBookLabel;

  /// No description provided for @removeAdsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get removeAdsScreenTitle;

  /// No description provided for @removeAdsDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove all ads from AnyRead with a one-time purchase. Read without interruptions, forever.'**
  String get removeAdsDescription;

  /// No description provided for @removeAdsButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get removeAdsButtonLabel;

  /// No description provided for @removeAdsRestoreButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get removeAdsRestoreButtonLabel;

  /// No description provided for @removeAdsRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Ads removed. Thank you for your support!'**
  String get removeAdsRemovedMessage;

  /// No description provided for @removeAdsPurchaseSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Purchase successful. Ads removed!'**
  String get removeAdsPurchaseSuccessMessage;

  /// No description provided for @removeAdsPurchaseCanceledMessage.
  ///
  /// In en, this message translates to:
  /// **'Purchase canceled.'**
  String get removeAdsPurchaseCanceledMessage;

  /// No description provided for @removeAdsPurchaseFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get removeAdsPurchaseFailedMessage;

  /// No description provided for @removeAdsNothingToRestoreMessage.
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found.'**
  String get removeAdsNothingToRestoreMessage;

  /// No description provided for @removeAdsUpsellTitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoying AnyRead?'**
  String get removeAdsUpsellTitle;

  /// No description provided for @removeAdsUpsellContent.
  ///
  /// In en, this message translates to:
  /// **'Remove all ads permanently for just {price}.'**
  String removeAdsUpsellContent(Object price);

  /// No description provided for @removeAdsUpsellContentGeneric.
  ///
  /// In en, this message translates to:
  /// **'Remove all ads permanently with a one-time purchase.'**
  String get removeAdsUpsellContentGeneric;

  /// No description provided for @yandexActiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Translated via Yandex (cloud)'**
  String get yandexActiveTooltip;

  /// No description provided for @yandexInactiveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Translated on-device'**
  String get yandexInactiveTooltip;

  /// No description provided for @yandexOfflineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Offline - cloud translation unavailable'**
  String get yandexOfflineTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
