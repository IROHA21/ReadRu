// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Excluir';

  @override
  String get back => 'Voltar';

  @override
  String get continueButton => 'Continuar';

  @override
  String get download => 'Baixar';

  @override
  String get downloading => 'Baixando...';

  @override
  String get close => 'Fechar';

  @override
  String get title => 'Título';

  @override
  String get searchLanguages => 'Buscar idiomas';

  @override
  String get showMoreLanguages => 'Mostrar mais';

  @override
  String get chapters => 'Capítulos';

  @override
  String get format => 'Formato';

  @override
  String get fileSize => 'Tamanho do arquivo';

  @override
  String get progress => 'Progresso';

  @override
  String get description => 'Descrição';

  @override
  String get author => 'Autor';

  @override
  String get later => 'Mais tarde';

  @override
  String get libraryTitle => 'Biblioteca';

  @override
  String get wordBucketTooltip => 'Cesta de palavras';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get libraryEmptyState =>
      'Adicione seu primeiro documento para começar a ler.';

  @override
  String get downloadLanguagePackTitle => 'Baixar pacote de idioma?';

  @override
  String downloadLanguagePackContent(Object title, Object language) {
    return '\"$title\" está em $language. Baixar agora o pacote de tradução offline para que a tradução ao tocar funcione sem internet?';
  }

  @override
  String get infoMenuItem => 'Informações';

  @override
  String get renameMenuItem => 'Renomear';

  @override
  String get renameBookTitle => 'Renomear livro';

  @override
  String get deleteDocumentTitle => 'Excluir documento?';

  @override
  String deleteDocumentContent(Object title) {
    return '\"$title\" será removido da sua biblioteca.';
  }

  @override
  String bookAlreadyExists(Object title) {
    return 'Já existe um livro chamado \"$title\"';
  }

  @override
  String get chaptersTooltip => 'Capítulos';

  @override
  String get readingSettingsTooltip => 'Configurações de leitura';

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
  String get cancelSelectionTooltip => 'Cancelar seleção';

  @override
  String wordsSelected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras selecionadas',
      one: '1 palavra selecionada',
    );
    return '$_temp0';
  }

  @override
  String get translateButton => 'Traduzir';

  @override
  String get saved => 'Salvo';

  @override
  String get saveToWordBucket => 'Salvar na cesta de palavras';

  @override
  String get translationFailed => '(falhou)';

  @override
  String get translationUnsupported => '(idioma não suportado)';

  @override
  String get readingFolderTitle => 'Leitura';

  @override
  String get readingFolderSubtitle =>
      'Fonte, tamanho, modo noturno, cor de destaque, virada de página';

  @override
  String get languageFolderTitle => 'Idioma';

  @override
  String get languageFolderSubtitle =>
      'Idioma do app, idioma(s) de destino, pacotes offline';

  @override
  String get textSizeLabel => 'Tamanho do texto';

  @override
  String get letterA => 'A';

  @override
  String get fontLabel => 'Fonte';

  @override
  String get nightModeLabel => 'Modo noturno';

  @override
  String get darkThemeLabel => 'Tema escuro';

  @override
  String get tapHighlightLabel => 'Destaque ao tocar para traduzir';

  @override
  String get highlightTappedWordsLabel => 'Destacar palavras tocadas';

  @override
  String get translationTextLabel => 'Texto de tradução';

  @override
  String get sizeLabel => 'Tamanho';

  @override
  String get pageTurnDirectionLabel => 'Direção de virada de página';

  @override
  String get leftToRight => 'Esquerda para direita';

  @override
  String get rightToLeft => 'Direita para esquerda';

  @override
  String get appLanguageLabel => 'Idioma do app';

  @override
  String get appLanguageDescription =>
      'As traduções serão feitas para este idioma.';

  @override
  String get goalLanguageLabel => 'Idioma(s) de destino';

  @override
  String get goalLanguageDescription => 'O(s) idioma(s) dos seus livros.';

  @override
  String get addLanguageChip => 'Adicionar idioma';

  @override
  String get offlinePacksLabel => 'Pacotes de idiomas offline';

  @override
  String get offlinePacksDescription =>
      'Idiomas destacados são seus idiomas atuais de app/destino. Baixe ou exclua qualquer pacote.';

  @override
  String get addLanguageSheetTitle => 'Adicionar um idioma';

  @override
  String packsReadySummary(Object ready, Object total, Object mb) {
    return '$ready de $total prontos · ~$mb MB no total (estimado)';
  }

  @override
  String get checkingStatus => 'Verificando...';

  @override
  String downloadingStatus(Object seconds) {
    return 'Baixando... ${seconds}s';
  }

  @override
  String get downloadedStatus => 'Baixado';

  @override
  String get downloadFailedStatus =>
      'Falha no download - toque para tentar novamente';

  @override
  String notDownloadedStatus(Object mb) {
    return '~$mb MB · não baixado';
  }

  @override
  String get deletePackTooltip => 'Excluir pacote baixado';

  @override
  String get spokenLanguageStepTitle => 'Que idioma você fala?';

  @override
  String get spokenLanguageStepSubtitle =>
      'Traduziremos os livros para este idioma.';

  @override
  String get bookLanguageStepTitle => 'Em quais idiomas estão seus livros?';

  @override
  String get bookLanguageStepSubtitle =>
      'Escolha todos os idiomas que você lê - você pode mudar isso por livro depois.';

  @override
  String get downloadStepTitle => 'Baixar tradução offline';

  @override
  String get downloadStepSubtitle =>
      'Baixe esses pacotes de idioma para que a tradução funcione totalmente offline depois. Você pode pular isso e fazer depois em Configurações.';

  @override
  String get skipForNow => 'Pular por enquanto';

  @override
  String get downloadPackScreenTitle => 'Baixar pacote de idioma';

  @override
  String get wordBucketTitle => 'Cesta de palavras';

  @override
  String get showAllWords => 'Mostrar todas as palavras';

  @override
  String get groupByBook => 'Agrupar por livro';

  @override
  String get wordBucketEmptyState =>
      'Toque em palavras enquanto lê para salvar suas traduções aqui.';

  @override
  String get bookInfoTitle => 'Informações do livro';

  @override
  String get languageNotSet => 'Não definido - toque para escolher';

  @override
  String languageNotSupported(Object flag, Object code) {
    return '$flag $code (tradução não suportada)';
  }

  @override
  String get languageOfBookLabel => 'Idioma do livro';
}
