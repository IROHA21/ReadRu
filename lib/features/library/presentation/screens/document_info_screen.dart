import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:read_ru/core/config/app_colors.dart';
import 'package:read_ru/features/library/domain/entities/document.dart';

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

class DocumentInfoScreen extends StatelessWidget {
  final Document document;

  const DocumentInfoScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        title: const Text('Book Info'),
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
          _InfoRow(label: 'Title', value: document.title, colors: colors),
          if (document.author != null) _InfoRow(label: 'Author', value: document.author!, colors: colors),
          if (document.language != null)
            _InfoRow(
              label: 'Language',
              value: '${_flagFor(document.language!)} ${document.language}',
              colors: colors,
            ),
          _InfoRow(label: 'Format', value: document.format.name.toUpperCase(), colors: colors),
          FutureBuilder<int>(
            future: File(document.filepath).length(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return _InfoRow(label: 'File size', value: _formatBytes(snapshot.data!), colors: colors);
            },
          ),
          _InfoRow(
            label: 'Progress',
            value: '${(document.progress * 100).round()}%',
            colors: colors,
          ),
          if (document.chapters.isNotEmpty)
            _InfoRow(label: 'Chapters', value: '${document.chapters.length}', colors: colors),
          if (document.description != null) ...[
            const SizedBox(height: 20),
            Text(
              'Description',
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

  const _InfoRow({required this.label, required this.value, required this.colors});

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
        ],
      ),
    );
  }
}
