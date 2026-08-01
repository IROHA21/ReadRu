import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/features/onboarding/presentation/widgets/language_pack_manager.dart';
import 'package:read_ru/l10n/generated/app_localizations.dart';

// Standalone download screen for a specific set of languages - used when
// adding a book surfaces a language whose model isn't downloaded yet, so
// the user doesn't have to go find Settings > Language on their own.
class LanguagePackDownloadScreen extends StatefulWidget {
  final List<TranslateLanguage> languages;

  const LanguagePackDownloadScreen({super.key, required this.languages});

  @override
  State<LanguagePackDownloadScreen> createState() => _LanguagePackDownloadScreenState();
}

class _LanguagePackDownloadScreenState extends State<LanguagePackDownloadScreen> {
  final _managerKey = GlobalKey<LanguagePackManagerState>();
  bool _downloading = false;
  // Set once a download attempt has finished (regardless of per-language
  // success/failure) - the button then reads "Continue" instead of
  // auto-popping, so the user actually sees the result (including any
  // "failed - tap to retry" rows) before moving on rather than being
  // whisked straight into the book.
  bool _downloaded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: Text(l10n.downloadPackScreenTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: LanguagePackManager(key: _managerKey, languages: widget.languages),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: _downloading
                ? null
                : _downloaded
                    ? () => Navigator.of(context).pop()
                    : () async {
                        setState(() => _downloading = true);
                        await _managerKey.currentState?.downloadMissing();
                        if (!context.mounted) return;
                        setState(() {
                          _downloading = false;
                          _downloaded = true;
                        });
                      },
            child: Text(
              _downloading
                  ? l10n.downloading
                  : _downloaded
                      ? l10n.continueButton
                      : l10n.download,
            ),
          ),
        ),
      ),
    );
  }
}
