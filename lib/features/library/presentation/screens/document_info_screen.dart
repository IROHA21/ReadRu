import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/core/di/injection_container.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';
import 'package:read_ru/features/library/domain/repositories/library_repository.dart';
import 'package:read_ru/features/onboarding/domain/supported_languages.dart';
import 'package:read_ru/l10n/generated/app_localizations.dart';

// Best-effort ISO 639-1 (or the first two letters of whatever the format
// gave us) -> flag emoji. Falls back to a globe when the code isn't one we
// recognize - the raw code is still shown next to it either way.
const Map<String, String> _languageFlags = {
  'ru': '🇷🇺', 'en': '🇬🇧', 'fr': '🇫🇷', 'de': '🇩🇪', 'es': '🇪🇸',
  'it': '🇮🇹', 'pt': '🇵🇹', 'pl': '🇵🇱', 'uk': '🇺🇦', 'be': '🇧🇾',
  'zh': '🇨🇳', 'ja': '🇯🇵', 'ko': '🇰🇷', 'ar': '🇸🇦', 'nl': '🇳🇱',
  'sv': '🇸🇪', 'tr': '🇹🇷', 'cs': '🇨🇿', 'fi': '🇫🇮', 'el': '🇬🇷',
  'he': '🇮🇱', 'hi': '🇮🇳', 'ro': '🇷🇴', 'hu': '🇭🇺', 'bg': '🇧🇬',
  'da': '🇩🇰', 'no': '🇳🇴', 'sk': '🇸🇰', 'sr': '🇷🇸', 'hr': '🇭🇷',
  'lt': '🇱🇹', 'lv': '🇱🇻', 'et': '🇪🇪', 'vi': '🇻🇳', 'th': '🇹🇭',
  'id': '🇮🇩',
};

String _flagFor(String languageCode) {
  final key = languageCode.trim().toLowerCase().split(RegExp(r'[-_]')).first;
  return _languageFlags[key] ?? '🌐';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}

class DocumentInfoScreen extends StatefulWidget {
  final Document document;

  const DocumentInfoScreen({super.key, required this.document});

  @override
  State<DocumentInfoScreen> createState() => _DocumentInfoScreenState();
}

class _DocumentInfoScreenState extends State<DocumentInfoScreen> {
  late Document _document;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
  }

  Future<void> _pickLanguage() async {
    final selected = await showModalBottomSheet<TranslateLanguage>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _LanguagePickerSheet(),
    );
    if (selected == null) return;

    await getIt<LibraryRepository>().setDocumentLanguage(_document, selected.bcpCode);
    if (!mounted) return;
    setState(() => _document = _document.copyWith(language: selected.bcpCode));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final document = _document;
    final language = document.language;
    final supported = translateLanguageFromCode(language);

    final String languageValue;
    if (language == null) {
      languageValue = l10n.languageNotSet;
    } else if (supported != null) {
      languageValue = '${_flagFor(language)} ${translateLanguageName(supported)}';
    } else {
      languageValue = l10n.languageNotSupported(_flagFor(language), language);
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text(l10n.bookInfoTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: document.coverImageBase64 != null
                  ? Image.memory(
                      base64Decode(document.coverImageBase64!),
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _CoverPlaceholder(colors: colors),
                    )
                  : _CoverPlaceholder(colors: colors),
            ),
          ),
          const SizedBox(height: 24),
          _InfoRow(label: l10n.title, value: document.title, colors: colors),
          if (document.author != null) _InfoRow(label: l10n.author, value: document.author!, colors: colors),
          InkWell(
            onTap: _pickLanguage,
            child: _InfoRow(
              label: l10n.languageOfBookLabel,
              value: languageValue,
              colors: colors,
              trailing: Icon(
                Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                color: colors.textSecondary,
              ),
            ),
          ),
          _InfoRow(label: l10n.format, value: document.format.name.toUpperCase(), colors: colors),
          FutureBuilder<int>(
            future: File(document.filepath).length(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return _InfoRow(label: l10n.fileSize, value: _formatBytes(snapshot.data!), colors: colors);
            },
          ),
          _InfoRow(
            label: l10n.progress,
            value: '${(document.progress * 100).round()}%',
            colors: colors,
          ),
          if (document.chapters.isNotEmpty)
            _InfoRow(label: l10n.chapters, value: '${document.chapters.length}', colors: colors),
          if (document.description != null) ...[
            const SizedBox(height: 20),
            Text(
              l10n.description,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(document.description!, style: TextStyle(color: colors.textPrimary, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  const _LanguagePickerSheet();

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  String _query = '';
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final languages = visibleLanguages(all: allSupportedLanguages, query: _query, expanded: _expanded);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                l10n.languageOfBookLabel,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.searchLanguages,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  for (final language in languages)
                    ListTile(
                      title: Text(translateLanguageName(language), style: TextStyle(color: colors.textPrimary)),
                      onTap: () => Navigator.of(context).pop(language),
                    ),
                  if (_query.isEmpty && !_expanded && languages.length < allSupportedLanguages.length)
                    ListTile(
                      leading: Icon(Icons.expand_more, color: colors.accent),
                      title: Text(l10n.showMoreLanguages, style: TextStyle(color: colors.accent)),
                      onTap: () => setState(() => _expanded = true),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final AppColors colors;
  const _CoverPlaceholder({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(width: 140, height: 140, color: colors.thumbnailPlaceholder);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final Widget? trailing;

  const _InfoRow({required this.label, required this.value, required this.colors, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textPrimary)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
