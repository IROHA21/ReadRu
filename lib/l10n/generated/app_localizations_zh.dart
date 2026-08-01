// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get back => '返回';

  @override
  String get continueButton => '继续';

  @override
  String get download => '下载';

  @override
  String get downloading => '正在下载…';

  @override
  String get close => '关闭';

  @override
  String get title => '标题';

  @override
  String get searchLanguages => '搜索语言';

  @override
  String get showMoreLanguages => '显示更多';

  @override
  String get chapters => '章节';

  @override
  String get format => '格式';

  @override
  String get fileSize => '文件大小';

  @override
  String get progress => '进度';

  @override
  String get description => '简介';

  @override
  String get author => '作者';

  @override
  String get later => '稍后';

  @override
  String get libraryTitle => '书库';

  @override
  String get wordBucketTooltip => '生词本';

  @override
  String get settingsTitle => '设置';

  @override
  String get libraryEmptyState => '添加你的第一本书即可开始阅读。';

  @override
  String get downloadLanguagePackTitle => '下载语言包？';

  @override
  String downloadLanguagePackContent(Object title, Object language) {
    return '《$title》是$language语。现在下载离线翻译包，以便点按翻译无需联网即可使用？';
  }

  @override
  String get infoMenuItem => '信息';

  @override
  String get renameMenuItem => '重命名';

  @override
  String get renameBookTitle => '重命名书籍';

  @override
  String get deleteDocumentTitle => '删除文档？';

  @override
  String deleteDocumentContent(Object title) {
    return '《$title》将从你的书库中移除。';
  }

  @override
  String bookAlreadyExists(Object title) {
    return '已存在名为《$title》的书籍';
  }

  @override
  String get chaptersTooltip => '章节';

  @override
  String get readingSettingsTooltip => '阅读设置';

  @override
  String get pageCounterUnknown => '- / -';

  @override
  String pageCounter(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String chapterPageLabel(Object page) {
    return '第 $page 页';
  }

  @override
  String get cancelSelectionTooltip => '取消选择';

  @override
  String wordsSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已选择 $count 个单词',
    );
    return '$_temp0';
  }

  @override
  String get translateButton => '翻译';

  @override
  String get saved => '已保存';

  @override
  String get saveToWordBucket => '保存到生词本';

  @override
  String get translationFailed => '(失败)';

  @override
  String get translationUnsupported => '(不支持该语言)';

  @override
  String get offlineTranslationWarning => '无网络连接——翻译准确度可能会降低。';

  @override
  String get offlineTranslationWarningTitle => '无网络连接';

  @override
  String get readingFolderTitle => '阅读';

  @override
  String get readingFolderSubtitle => '字体、大小、夜间模式、高亮颜色、翻页方式';

  @override
  String get languageFolderTitle => '语言';

  @override
  String get languageFolderSubtitle => '应用语言、目标语言、离线语言包';

  @override
  String get settingsRemoveAdsTitle => '移除广告';

  @override
  String get settingsRemoveAdsSubtitle => '一次性购买,从此无广告';

  @override
  String get textSizeLabel => '文字大小';

  @override
  String get letterA => 'A';

  @override
  String get fontLabel => '字体';

  @override
  String get nightModeLabel => '夜间模式';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get tapHighlightLabel => '点按翻译高亮';

  @override
  String get highlightTappedWordsLabel => '高亮已点按的单词';

  @override
  String get translationTextLabel => '翻译文字';

  @override
  String get sizeLabel => '大小';

  @override
  String get pageTurnDirectionLabel => '翻页方向';

  @override
  String get leftToRight => '从左到右';

  @override
  String get rightToLeft => '从右到左';

  @override
  String get appLanguageLabel => '应用语言';

  @override
  String get appLanguageDescription => '翻译结果将以该语言显示。';

  @override
  String get goalLanguageLabel => '目标语言';

  @override
  String get goalLanguageDescription => '你的书籍所使用的语言。';

  @override
  String get addLanguageChip => '添加语言';

  @override
  String get offlinePacksLabel => '离线语言包';

  @override
  String get offlinePacksDescription => '带星标的语言是你当前的应用/目标语言。可下载或删除任意语言包。';

  @override
  String get addLanguageSheetTitle => '添加语言';

  @override
  String packsReadySummary(Object ready, Object total, Object mb) {
    return '已就绪 $ready/$total · 共约 $mb MB（估计）';
  }

  @override
  String get checkingStatus => '检查中…';

  @override
  String downloadingStatus(Object seconds) {
    return '正在下载…$seconds 秒';
  }

  @override
  String get downloadedStatus => '已下载';

  @override
  String get downloadFailedStatus => '下载失败——点按重试';

  @override
  String notDownloadedStatus(Object mb) {
    return '约 $mb MB · 尚未下载';
  }

  @override
  String get deletePackTooltip => '删除已下载的语言包';

  @override
  String get spokenLanguageStepTitle => '你说什么语言？';

  @override
  String get spokenLanguageStepSubtitle => '我们会将书籍翻译成该语言。';

  @override
  String get bookLanguageStepTitle => '你的书籍是什么语言？';

  @override
  String get bookLanguageStepSubtitle => '选择你阅读的所有语言——之后可为每本书单独更改。';

  @override
  String get downloadStepTitle => '下载离线翻译';

  @override
  String get downloadStepSubtitle => '下载这些语言包，之后翻译即可完全离线使用。你也可以跳过此步骤，稍后在设置中完成。';

  @override
  String downloadMinimumRequired(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '请至少下载 $count 种语言以继续。',
      one: '请至少下载 1 种语言以继续。',
    );
    return '$_temp0';
  }

  @override
  String get downloadPackScreenTitle => '下载语言包';

  @override
  String get wordBucketTitle => '生词本';

  @override
  String get showAllWords => '显示所有单词';

  @override
  String get groupByBook => '按书籍分组';

  @override
  String get wordBucketEmptyState => '阅读时点按单词即可将其翻译保存到这里。';

  @override
  String get bookInfoTitle => '书籍信息';

  @override
  String get languageNotSet => '未设置——点按选择';

  @override
  String languageNotSupported(Object flag, Object code) {
    return '$flag $code（不支持翻译）';
  }

  @override
  String get languageOfBookLabel => '书籍语言';

  @override
  String get removeAdsScreenTitle => '移除广告';

  @override
  String get removeAdsDescription => '通过一次性购买移除 AnyRead 中的所有广告,从此畅读无干扰。';

  @override
  String get removeAdsButtonLabel => '移除广告';

  @override
  String get removeAdsRestoreButtonLabel => '恢复购买';

  @override
  String get removeAdsRemovedMessage => '广告已移除。感谢您的支持!';

  @override
  String get removeAdsPurchaseSuccessMessage => '购买成功,广告已移除!';

  @override
  String get removeAdsPurchaseCanceledMessage => '购买已取消。';

  @override
  String get removeAdsPurchaseFailedMessage => '出了点问题,请重试。';

  @override
  String get removeAdsNothingToRestoreMessage => '未找到以前的购买记录。';

  @override
  String get removeAdsUpsellTitle => '喜欢 AnyRead 吗?';

  @override
  String removeAdsUpsellContent(Object price) {
    return '仅需 $price 即可永久移除所有广告。';
  }

  @override
  String get removeAdsUpsellContentGeneric => '通过一次性购买永久移除所有广告。';

  @override
  String get yandexActiveTooltip => '通过 Yandex(云端)翻译';

  @override
  String get yandexInactiveTooltip => '设备本地翻译';

  @override
  String get yandexOfflineTooltip => '离线 - 云端翻译不可用';
}
