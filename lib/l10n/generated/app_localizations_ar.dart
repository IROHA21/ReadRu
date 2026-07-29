// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get back => 'رجوع';

  @override
  String get continueButton => 'متابعة';

  @override
  String get download => 'تنزيل';

  @override
  String get downloading => 'جارٍ التنزيل...';

  @override
  String get close => 'إغلاق';

  @override
  String get title => 'العنوان';

  @override
  String get searchLanguages => 'البحث عن لغات';

  @override
  String get showMoreLanguages => 'عرض المزيد';

  @override
  String get chapters => 'الفصول';

  @override
  String get format => 'الصيغة';

  @override
  String get fileSize => 'حجم الملف';

  @override
  String get progress => 'التقدّم';

  @override
  String get description => 'الوصف';

  @override
  String get author => 'المؤلف';

  @override
  String get later => 'لاحقًا';

  @override
  String get libraryTitle => 'المكتبة';

  @override
  String get wordBucketTooltip => 'سلة الكلمات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get libraryEmptyState => 'أضف مستندك الأول لبدء القراءة.';

  @override
  String get downloadLanguagePackTitle => 'تنزيل حزمة اللغة؟';

  @override
  String downloadLanguagePackContent(Object title, Object language) {
    return '\"$title\" مكتوب بلغة $language. هل تريد تنزيل حزمة الترجمة غير المتصلة الآن حتى تعمل الترجمة بالنقر دون إنترنت؟';
  }

  @override
  String get infoMenuItem => 'معلومات';

  @override
  String get renameMenuItem => 'إعادة تسمية';

  @override
  String get renameBookTitle => 'إعادة تسمية الكتاب';

  @override
  String get deleteDocumentTitle => 'حذف المستند؟';

  @override
  String deleteDocumentContent(Object title) {
    return 'ستتم إزالة \"$title\" من مكتبتك.';
  }

  @override
  String bookAlreadyExists(Object title) {
    return 'يوجد بالفعل كتاب باسم \"$title\"';
  }

  @override
  String get chaptersTooltip => 'الفصول';

  @override
  String get readingSettingsTooltip => 'إعدادات القراءة';

  @override
  String get pageCounterUnknown => '- / -';

  @override
  String pageCounter(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String chapterPageLabel(Object page) {
    return 'ص. $page';
  }

  @override
  String get cancelSelectionTooltip => 'إلغاء التحديد';

  @override
  String wordsSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديد $count كلمة',
      many: 'تم تحديد $count كلمة',
      few: 'تم تحديد $count كلمات',
      two: 'تم تحديد كلمتين',
      one: 'تم تحديد كلمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get translateButton => 'ترجمة';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get saveToWordBucket => 'حفظ في سلة الكلمات';

  @override
  String get translationFailed => '(فشلت الترجمة)';

  @override
  String get translationUnsupported => '(اللغة غير مدعومة)';

  @override
  String get offlineTranslationWarning =>
      'لا يوجد اتصال بالإنترنت - قد تكون الترجمات أقل دقة.';

  @override
  String get readingFolderTitle => 'القراءة';

  @override
  String get readingFolderSubtitle =>
      'الخط، الحجم، الوضع الليلي، لون التمييز، اتجاه تقليب الصفحات';

  @override
  String get languageFolderTitle => 'اللغة';

  @override
  String get languageFolderSubtitle =>
      'لغة التطبيق، لغة (لغات) الهدف، الحزم غير المتصلة';

  @override
  String get textSizeLabel => 'حجم النص';

  @override
  String get letterA => 'A';

  @override
  String get fontLabel => 'الخط';

  @override
  String get nightModeLabel => 'الوضع الليلي';

  @override
  String get darkThemeLabel => 'المظهر الداكن';

  @override
  String get tapHighlightLabel => 'تمييز النقر للترجمة';

  @override
  String get highlightTappedWordsLabel => 'تمييز الكلمات التي تم النقر عليها';

  @override
  String get translationTextLabel => 'نص الترجمة';

  @override
  String get sizeLabel => 'الحجم';

  @override
  String get pageTurnDirectionLabel => 'اتجاه تقليب الصفحات';

  @override
  String get leftToRight => 'من اليسار إلى اليمين';

  @override
  String get rightToLeft => 'من اليمين إلى اليسار';

  @override
  String get appLanguageLabel => 'لغة التطبيق';

  @override
  String get appLanguageDescription => 'ستكون الترجمات إلى هذه اللغة.';

  @override
  String get goalLanguageLabel => 'لغة (لغات) الهدف';

  @override
  String get goalLanguageDescription => 'اللغة (اللغات) التي كتبت بها كتبك.';

  @override
  String get addLanguageChip => 'إضافة لغة';

  @override
  String get offlinePacksLabel => 'حزم اللغات غير المتصلة';

  @override
  String get offlinePacksDescription =>
      'اللغات المميزة بنجمة هي لغات التطبيق/الهدف الحالية لديك. يمكنك تنزيل أو حذف أي حزمة.';

  @override
  String get addLanguageSheetTitle => 'إضافة لغة';

  @override
  String packsReadySummary(Object ready, Object total, Object mb) {
    return '$ready من $total جاهزة · ~$mb ميجابايت إجمالاً (تقديري)';
  }

  @override
  String get checkingStatus => 'جارٍ التحقق...';

  @override
  String downloadingStatus(Object seconds) {
    return 'جارٍ التنزيل... $seconds ث';
  }

  @override
  String get downloadedStatus => 'تم التنزيل';

  @override
  String get downloadFailedStatus => 'فشل التنزيل - انقر لإعادة المحاولة';

  @override
  String notDownloadedStatus(Object mb) {
    return '~$mb ميجابايت · لم يتم التنزيل';
  }

  @override
  String get deletePackTooltip => 'حذف الحزمة المُنزَّلة';

  @override
  String get spokenLanguageStepTitle => 'ما هي اللغة التي تتحدثها؟';

  @override
  String get spokenLanguageStepSubtitle => 'سنترجم الكتب إلى هذه اللغة.';

  @override
  String get bookLanguageStepTitle => 'بأي لغات كتبك؟';

  @override
  String get bookLanguageStepSubtitle =>
      'اختر كل لغة تقرأ بها - يمكنك تغيير ذلك لكل كتاب لاحقًا.';

  @override
  String get downloadStepTitle => 'تنزيل الترجمة غير المتصلة';

  @override
  String get downloadStepSubtitle =>
      'نزّل حزم اللغات هذه حتى تعمل الترجمة دون اتصال بالكامل لاحقًا. يمكنك تخطي هذه الخطوة والقيام بها لاحقًا من الإعدادات.';

  @override
  String get skipForNow => 'تخطي الآن';

  @override
  String get downloadPackScreenTitle => 'تنزيل حزمة اللغة';

  @override
  String get wordBucketTitle => 'سلة الكلمات';

  @override
  String get showAllWords => 'عرض جميع الكلمات';

  @override
  String get groupByBook => 'تجميع حسب الكتاب';

  @override
  String get wordBucketEmptyState =>
      'انقر على الكلمات أثناء القراءة لحفظ ترجماتها هنا.';

  @override
  String get bookInfoTitle => 'معلومات الكتاب';

  @override
  String get languageNotSet => 'غير محدد - انقر للاختيار';

  @override
  String languageNotSupported(Object flag, Object code) {
    return '$flag $code (الترجمة غير مدعومة)';
  }

  @override
  String get languageOfBookLabel => 'لغة الكتاب';
}
