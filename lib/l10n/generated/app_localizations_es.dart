// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get back => 'Atrás';

  @override
  String get continueButton => 'Continuar';

  @override
  String get download => 'Descargar';

  @override
  String get downloading => 'Descargando...';

  @override
  String get close => 'Cerrar';

  @override
  String get title => 'Título';

  @override
  String get searchLanguages => 'Buscar idiomas';

  @override
  String get showMoreLanguages => 'Mostrar más';

  @override
  String get chapters => 'Capítulos';

  @override
  String get format => 'Formato';

  @override
  String get fileSize => 'Tamaño del archivo';

  @override
  String get progress => 'Progreso';

  @override
  String get description => 'Descripción';

  @override
  String get author => 'Autor';

  @override
  String get later => 'Más tarde';

  @override
  String get libraryTitle => 'Biblioteca';

  @override
  String get wordBucketTooltip => 'Cesta de palabras';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get libraryEmptyState =>
      'Añade tu primer documento para empezar a leer.';

  @override
  String get downloadLanguagePackTitle => '¿Descargar paquete de idioma?';

  @override
  String downloadLanguagePackContent(Object title, Object language) {
    return '\"$title\" está en $language. ¿Descargar ahora el paquete de traducción sin conexión para que la traducción al tocar funcione sin internet?';
  }

  @override
  String get infoMenuItem => 'Información';

  @override
  String get renameMenuItem => 'Renombrar';

  @override
  String get renameBookTitle => 'Renombrar libro';

  @override
  String get deleteDocumentTitle => '¿Eliminar documento?';

  @override
  String deleteDocumentContent(Object title) {
    return '\"$title\" se eliminará de tu biblioteca.';
  }

  @override
  String bookAlreadyExists(Object title) {
    return 'Ya existe un libro llamado \"$title\"';
  }

  @override
  String get chaptersTooltip => 'Capítulos';

  @override
  String get readingSettingsTooltip => 'Ajustes de lectura';

  @override
  String get pageCounterUnknown => '- / -';

  @override
  String pageCounter(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String chapterPageLabel(Object page) {
    return 'pág. $page';
  }

  @override
  String get cancelSelectionTooltip => 'Cancelar selección';

  @override
  String wordsSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palabras seleccionadas',
      one: '1 palabra seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get translateButton => 'Traducir';

  @override
  String get saved => 'Guardado';

  @override
  String get saveToWordBucket => 'Guardar en la cesta de palabras';

  @override
  String get translationFailed => '(fallo)';

  @override
  String get translationUnsupported => '(idioma no compatible)';

  @override
  String get readingFolderTitle => 'Lectura';

  @override
  String get readingFolderSubtitle =>
      'Fuente, tamaño, modo nocturno, color de resaltado, cambio de página';

  @override
  String get languageFolderTitle => 'Idioma';

  @override
  String get languageFolderSubtitle =>
      'Idioma de la app, idioma(s) objetivo, paquetes sin conexión';

  @override
  String get textSizeLabel => 'Tamaño del texto';

  @override
  String get letterA => 'A';

  @override
  String get fontLabel => 'Fuente';

  @override
  String get nightModeLabel => 'Modo nocturno';

  @override
  String get darkThemeLabel => 'Tema oscuro';

  @override
  String get tapHighlightLabel => 'Resaltado al tocar para traducir';

  @override
  String get highlightTappedWordsLabel => 'Resaltar palabras tocadas';

  @override
  String get translationTextLabel => 'Texto de traducción';

  @override
  String get sizeLabel => 'Tamaño';

  @override
  String get pageTurnDirectionLabel => 'Dirección de cambio de página';

  @override
  String get leftToRight => 'Izquierda a derecha';

  @override
  String get rightToLeft => 'Derecha a izquierda';

  @override
  String get appLanguageLabel => 'Idioma de la app';

  @override
  String get appLanguageDescription =>
      'Las traducciones se harán a este idioma.';

  @override
  String get goalLanguageLabel => 'Idioma(s) objetivo';

  @override
  String get goalLanguageDescription =>
      'El/los idioma(s) en que están tus libros.';

  @override
  String get addLanguageChip => 'Añadir idioma';

  @override
  String get offlinePacksLabel => 'Paquetes de idiomas sin conexión';

  @override
  String get offlinePacksDescription =>
      'Los idiomas destacados son tus idiomas actuales de app/objetivo. Descarga o elimina cualquier paquete.';

  @override
  String get addLanguageSheetTitle => 'Añadir un idioma';

  @override
  String packsReadySummary(Object ready, Object total, Object mb) {
    return '$ready de $total listos · ~$mb MB en total (estimado)';
  }

  @override
  String get checkingStatus => 'Comprobando...';

  @override
  String downloadingStatus(Object seconds) {
    return 'Descargando... ${seconds}s';
  }

  @override
  String get downloadedStatus => 'Descargado';

  @override
  String get downloadFailedStatus =>
      'Error al descargar - toca para reintentar';

  @override
  String notDownloadedStatus(Object mb) {
    return '~$mb MB · no descargado';
  }

  @override
  String get deletePackTooltip => 'Eliminar paquete descargado';

  @override
  String get spokenLanguageStepTitle => '¿Qué idioma hablas?';

  @override
  String get spokenLanguageStepSubtitle =>
      'Traduciremos los libros a este idioma.';

  @override
  String get bookLanguageStepTitle => '¿En qué idiomas están tus libros?';

  @override
  String get bookLanguageStepSubtitle =>
      'Elige todos los idiomas en los que lees; puedes cambiarlo por libro más tarde.';

  @override
  String get downloadStepTitle => 'Descargar traducción sin conexión';

  @override
  String get downloadStepSubtitle =>
      'Descarga estos paquetes de idioma para que la traducción funcione completamente sin conexión. Puedes omitir esto y hacerlo más tarde en Ajustes.';

  @override
  String get skipForNow => 'Omitir por ahora';

  @override
  String get downloadPackScreenTitle => 'Descargar paquete de idioma';

  @override
  String get wordBucketTitle => 'Cesta de palabras';

  @override
  String get showAllWords => 'Mostrar todas las palabras';

  @override
  String get groupByBook => 'Agrupar por libro';

  @override
  String get wordBucketEmptyState =>
      'Toca palabras mientras lees para guardar sus traducciones aquí.';

  @override
  String get bookInfoTitle => 'Información del libro';

  @override
  String get languageNotSet => 'No establecido - toca para elegir';

  @override
  String languageNotSupported(Object flag, Object code) {
    return '$flag $code (no compatible con traducción)';
  }

  @override
  String get languageOfBookLabel => 'Idioma del libro';
}
