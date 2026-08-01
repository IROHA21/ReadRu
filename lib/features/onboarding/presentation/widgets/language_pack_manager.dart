import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/features/onboarding/domain/supported_languages.dart';
import 'package:read_ru/l10n/generated/app_localizations.dart';

// Google's own published ballpark for an on-device translation language
// model - the plugin exposes no real size or byte-level download progress
// per language, so this is shown everywhere as an estimate, never as a
// measured figure. https://developers.google.com/ml-kit/language/translation
const int estimatedModelSizeMb = 30;

enum _PackStatus { checking, notDownloaded, downloading, ready, failed }

/// Shared "what's downloaded, what isn't, download/delete it" UI - used
/// both by onboarding (a focused list of just the chosen languages, no
/// delete) and by Settings' language pack manager (every supported
/// language, searchable, deletable).
///
/// There's no way to ask ML Kit for real download percentage, so progress
/// here is honest about what it actually knows: whether a pack is present
/// (isModelDownloaded), and - while a download is running - how long it's
/// been running, not how far along it is.
class LanguagePackManager extends StatefulWidget {
  final List<TranslateLanguage> languages;
  final Set<TranslateLanguage> highlighted;
  final bool showSearch;
  final bool showDelete;
  final bool showSummary;
  // Fired every time a language's status changes (check complete, download
  // finished/failed, delete) - lets a parent that gates its own UI on
  // readyCount (e.g. onboarding's Continue button) rebuild and re-evaluate,
  // including after a per-row retry that this widget handles internally
  // without the parent otherwise knowing anything changed.
  final VoidCallback? onChanged;

  const LanguagePackManager({
    super.key,
    required this.languages,
    this.highlighted = const {},
    this.showSearch = false,
    this.showDelete = false,
    this.showSummary = true,
    this.onChanged,
  });

  @override
  State<LanguagePackManager> createState() => LanguagePackManagerState();
}

class LanguagePackManagerState extends State<LanguagePackManager> {
  final _modelManager = OnDeviceTranslatorModelManager();
  final Map<TranslateLanguage, _PackStatus> _status = {};
  final Map<TranslateLanguage, int> _elapsedSeconds = {};
  // Shown directly under a failed row - there's no device-log access when
  // this happens on a real user's phone, so the actual native error (not
  // just "failed") needs to be visible right here to ever be diagnosable.
  final Map<TranslateLanguage, String> _errorDetail = {};
  Timer? _ticker;
  String _query = '';
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  @override
  void didUpdateWidget(covariant LanguagePackManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.languages != widget.languages) _checkAll();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // Every status mutation goes through here so widget.onChanged always
  // fires alongside setState - callers gating their own UI on readyCount
  // (onboarding's Continue button) need to hear about every change,
  // including a per-row retry that happens entirely inside this widget.
  void _setStatus(TranslateLanguage language, _PackStatus status) {
    if (!mounted) return;
    setState(() => _status[language] = status);
    widget.onChanged?.call();
  }

  Future<void> _checkAll() async {
    for (final language in widget.languages) {
      if (_status.containsKey(language)) continue;
      _setStatus(language, _PackStatus.checking);
      // One language's check throwing shouldn't stop every language after
      // it in this loop from ever being checked - treat it as "not
      // downloaded" (safe default: offers a download instead of getting
      // stuck on "Checking...") and keep going.
      bool downloaded;
      try {
        downloaded = await _modelManager.isModelDownloaded(language.bcpCode);
      } catch (e) {
        debugPrint('LanguagePackManager: isModelDownloaded(${language.bcpCode}) threw: $e');
        downloaded = false;
      }
      if (!mounted) return;
      _setStatus(language, downloaded ? _PackStatus.ready : _PackStatus.notDownloaded);
    }
  }

  Future<void> downloadMissing() async {
    for (final language in widget.languages) {
      if (_status[language] != _PackStatus.ready) {
        await _download(language);
      }
    }
  }

  /// Whether every language this panel was given is confirmed downloaded -
  /// callers (onboarding) can poll this after downloadMissing() finishes.
  bool get allReady => widget.languages.every((l) => _status[l] == _PackStatus.ready);

  /// How many of this panel's languages are confirmed downloaded - callers
  /// that only require a minimum count (rather than every language) poll
  /// this, and should also pass onChanged so they hear about updates from a
  /// per-row retry, which happens without the caller otherwise knowing.
  int get readyCount => widget.languages.where((l) => _status[l] == _PackStatus.ready).length;

  Future<void> _download(TranslateLanguage language) async {
    setState(() {
      _status[language] = _PackStatus.downloading;
      _elapsedSeconds[language] = 0;
    });
    widget.onChanged?.call();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        for (final l in _elapsedSeconds.keys) {
          if (_status[l] == _PackStatus.downloading) _elapsedSeconds[l] = _elapsedSeconds[l]! + 1;
        }
      });
    });
    try {
      // downloadModel() can resolve to false (not "success") without
      // throwing - trusting a clean await here previously marked packs
      // ready that were never actually usable. Verify against the model
      // manager's own record instead of trusting the call's completion.
      await _modelManager.downloadModel(language.bcpCode, isWifiRequired: false);
      final confirmed = await _modelManager.isModelDownloaded(language.bcpCode);
      if (!confirmed) {
        const detail = 'downloadModel() completed but isModelDownloaded still reports false';
        debugPrint('LanguagePackManager: downloadModel(${language.bcpCode}) - $detail');
        _errorDetail[language] = detail;
      }
      if (!mounted) return;
      _setStatus(language, confirmed ? _PackStatus.ready : _PackStatus.failed);
    } catch (e) {
      debugPrint('LanguagePackManager: downloadModel(${language.bcpCode}) threw: $e');
      _errorDetail[language] = e.toString();
      if (!mounted) return;
      _setStatus(language, _PackStatus.failed);
    }
  }

  Future<void> _delete(TranslateLanguage language) async {
    try {
      await _modelManager.deleteModel(language.bcpCode);
      if (!mounted) return;
      _setStatus(language, _PackStatus.notDownloaded);
    } catch (_) {
      // Leave it marked ready - if delete silently failed, that's still
      // the true state on disk.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Status-checking (_checkAll) still covers every language passed in, so
    // the ready count/progress bar stay accurate - only how many rows get
    // built is capped, since rendering (and rebuilding, once per language
    // as _checkAll's status updates land) all 59 rows at once is what
    // actually made this list janky.
    final visible = widget.showSearch
        ? visibleLanguages(all: widget.languages, query: _query, expanded: _expanded)
        : widget.languages;
    final readyCount = widget.languages.where((l) => _status[l] == _PackStatus.ready).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSummary) ...[
          Text(
            l10n.packsReadySummary(
              readyCount,
              widget.languages.length,
              widget.languages.length * estimatedModelSizeMb,
            ),
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.languages.isEmpty ? 0 : readyCount / widget.languages.length,
              minHeight: 6,
              backgroundColor: colors.progressTrack,
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.showSearch)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.searchLanguages,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        for (final language in visible)
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: _status[language] == _PackStatus.failed ? () => _download(language) : null,
            title: Row(
              children: [
                Flexible(
                  child: Text(translateLanguageName(language), style: TextStyle(color: colors.textPrimary)),
                ),
                if (widget.highlighted.contains(language)) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.star, size: 14, color: colors.accent),
                ],
              ],
            ),
            subtitle: switch (_status[language]) {
              _PackStatus.checking => Text(l10n.checkingStatus, style: TextStyle(color: colors.textSecondary)),
              _PackStatus.downloading => Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: colors.progressTrack,
                          valueColor: AlwaysStoppedAnimation(colors.accent),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.downloadingStatus(_elapsedSeconds[language] ?? 0),
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              _PackStatus.ready => Text(l10n.downloadedStatus, style: TextStyle(color: colors.textSecondary)),
              _PackStatus.failed => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.downloadFailedStatus, style: TextStyle(color: Colors.red.shade400)),
                    if (_errorDetail[language] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _errorDetail[language]!,
                          style: TextStyle(fontSize: 11, color: Colors.red.shade300),
                        ),
                      ),
                  ],
                ),
              _PackStatus.notDownloaded || null =>
                Text(l10n.notDownloadedStatus(estimatedModelSizeMb), style: TextStyle(color: colors.textSecondary)),
            },
            trailing: switch (_status[language]) {
              _PackStatus.ready => widget.showDelete
                  ? IconButton(
                      icon: Icon(Icons.delete_outline, color: colors.textSecondary),
                      tooltip: l10n.deletePackTooltip,
                      onPressed: () => _delete(language),
                    )
                  : Icon(Icons.check_circle, color: colors.accent),
              _PackStatus.notDownloaded => IconButton(
                  icon: Icon(Icons.download, color: colors.accent),
                  tooltip: l10n.download,
                  onPressed: () => _download(language),
                ),
              _PackStatus.failed => const Icon(Icons.error_outline, color: Colors.red),
              _ => null,
            },
          ),
        if (widget.showSearch && _query.isEmpty && !_expanded && visible.length < widget.languages.length)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.expand_more, color: colors.accent),
            title: Text(l10n.showMoreLanguages, style: TextStyle(color: colors.accent)),
            onTap: () => setState(() => _expanded = true),
          ),
      ],
    );
  }
}
