// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get back => 'Назад';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get download => 'Скачать';

  @override
  String get downloading => 'Загрузка...';

  @override
  String get close => 'Закрыть';

  @override
  String get title => 'Название';

  @override
  String get searchLanguages => 'Поиск языков';

  @override
  String get showMoreLanguages => 'Показать больше';

  @override
  String get chapters => 'Главы';

  @override
  String get format => 'Формат';

  @override
  String get fileSize => 'Размер файла';

  @override
  String get progress => 'Прогресс';

  @override
  String get description => 'Описание';

  @override
  String get author => 'Автор';

  @override
  String get later => 'Позже';

  @override
  String get libraryTitle => 'Библиотека';

  @override
  String get wordBucketTooltip => 'Корзина слов';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get libraryEmptyState =>
      'Добавьте свой первый документ, чтобы начать чтение.';

  @override
  String get downloadLanguagePackTitle => 'Скачать языковой пакет?';

  @override
  String downloadLanguagePackContent(Object title, Object language) {
    return '«$title» на языке $language. Скачать офлайн-пакет перевода сейчас, чтобы перевод по нажатию работал без интернета?';
  }

  @override
  String get infoMenuItem => 'Информация';

  @override
  String get renameMenuItem => 'Переименовать';

  @override
  String get renameBookTitle => 'Переименовать книгу';

  @override
  String get deleteDocumentTitle => 'Удалить документ?';

  @override
  String deleteDocumentContent(Object title) {
    return '«$title» будет удалена из вашей библиотеки.';
  }

  @override
  String bookAlreadyExists(Object title) {
    return 'Книга с названием «$title» уже существует';
  }

  @override
  String get chaptersTooltip => 'Главы';

  @override
  String get readingSettingsTooltip => 'Настройки чтения';

  @override
  String get pageCounterUnknown => '- / -';

  @override
  String pageCounter(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String chapterPageLabel(Object page) {
    return 'стр. $page';
  }

  @override
  String get cancelSelectionTooltip => 'Отменить выбор';

  @override
  String wordsSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбрано $count слова',
      many: 'Выбрано $count слов',
      few: 'Выбрано $count слова',
      one: 'Выбрано 1 слово',
    );
    return '$_temp0';
  }

  @override
  String get translateButton => 'Перевести';

  @override
  String get saved => 'Сохранено';

  @override
  String get saveToWordBucket => 'Сохранить в корзину слов';

  @override
  String get translationFailed => '(не удалось)';

  @override
  String get translationUnsupported => '(язык не поддерживается)';

  @override
  String get offlineTranslationWarning =>
      'Нет подключения к интернету — перевод может быть менее точным.';

  @override
  String get readingFolderTitle => 'Чтение';

  @override
  String get readingFolderSubtitle =>
      'Шрифт, размер, ночной режим, цвет выделения, перелистывание страниц';

  @override
  String get languageFolderTitle => 'Язык';

  @override
  String get languageFolderSubtitle =>
      'Язык приложения, целевой(ые) язык(и), офлайн-пакеты';

  @override
  String get textSizeLabel => 'Размер текста';

  @override
  String get letterA => 'A';

  @override
  String get fontLabel => 'Шрифт';

  @override
  String get nightModeLabel => 'Ночной режим';

  @override
  String get darkThemeLabel => 'Тёмная тема';

  @override
  String get tapHighlightLabel => 'Выделение при переводе по нажатию';

  @override
  String get highlightTappedWordsLabel => 'Выделять нажатые слова';

  @override
  String get translationTextLabel => 'Текст перевода';

  @override
  String get sizeLabel => 'Размер';

  @override
  String get pageTurnDirectionLabel => 'Направление перелистывания страниц';

  @override
  String get leftToRight => 'Слева направо';

  @override
  String get rightToLeft => 'Справа налево';

  @override
  String get appLanguageLabel => 'Язык приложения';

  @override
  String get appLanguageDescription =>
      'Переводы будут выполняться на этот язык.';

  @override
  String get goalLanguageLabel => 'Целевой(ые) язык(и)';

  @override
  String get goalLanguageDescription => 'Язык(и) ваших книг.';

  @override
  String get addLanguageChip => 'Добавить язык';

  @override
  String get offlinePacksLabel => 'Офлайн языковые пакеты';

  @override
  String get offlinePacksDescription =>
      'Отмеченные звёздочкой языки — ваши текущие языки приложения/цели. Скачивайте или удаляйте любой пакет.';

  @override
  String get addLanguageSheetTitle => 'Добавить язык';

  @override
  String packsReadySummary(Object ready, Object total, Object mb) {
    return 'Готово $ready из $total · ~$mb МБ всего (примерно)';
  }

  @override
  String get checkingStatus => 'Проверка...';

  @override
  String downloadingStatus(Object seconds) {
    return 'Загрузка... $seconds с';
  }

  @override
  String get downloadedStatus => 'Скачано';

  @override
  String get downloadFailedStatus => 'Ошибка загрузки — нажмите для повтора';

  @override
  String notDownloadedStatus(Object mb) {
    return '~$mb МБ · не скачано';
  }

  @override
  String get deletePackTooltip => 'Удалить скачанный пакет';

  @override
  String get spokenLanguageStepTitle => 'На каком языке вы говорите?';

  @override
  String get spokenLanguageStepSubtitle =>
      'Мы будем переводить книги на этот язык.';

  @override
  String get bookLanguageStepTitle => 'На каких языках ваши книги?';

  @override
  String get bookLanguageStepSubtitle =>
      'Выберите все языки, на которых вы читаете — позже это можно изменить для каждой книги отдельно.';

  @override
  String get downloadStepTitle => 'Скачать офлайн-перевод';

  @override
  String get downloadStepSubtitle =>
      'Скачайте эти языковые пакеты, чтобы перевод в дальнейшем работал полностью офлайн. Вы можете пропустить это и сделать позже в настройках.';

  @override
  String get skipForNow => 'Пропустить пока';

  @override
  String get downloadPackScreenTitle => 'Скачать языковой пакет';

  @override
  String get wordBucketTitle => 'Корзина слов';

  @override
  String get showAllWords => 'Показать все слова';

  @override
  String get groupByBook => 'Группировать по книге';

  @override
  String get wordBucketEmptyState =>
      'Нажимайте на слова во время чтения, чтобы сохранить их перевод здесь.';

  @override
  String get bookInfoTitle => 'Информация о книге';

  @override
  String get languageNotSet => 'Не задано — нажмите, чтобы выбрать';

  @override
  String languageNotSupported(Object flag, Object code) {
    return '$flag $code (перевод не поддерживается)';
  }

  @override
  String get languageOfBookLabel => 'Язык книги';
}
