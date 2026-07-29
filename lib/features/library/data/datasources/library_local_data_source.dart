

import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import 'package:epubx/epubx.dart';
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:kindle_unpack/kindle_unpack.dart';
import 'package:image/image.dart' as img;
import 'package:read_ru/features/library/data/utils/html_to_plain_text.dart';
import 'package:read_ru/features/library/domain/entities/chapter.dart';

typedef BookMetadata = ({
  String? title,
  String? author,
  String? description,
  String? language,
  String? coverImageBase64,
  List<Chapter> chapters,
});

int _countWords(String text) => text.trim().isEmpty
    ? 0
    : text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

// splitIntoWords inserts one paragraphBreak "word" between every pair of
// consecutive paragraphs (split on blank lines) - so to land a chapter's
// wordIndex on the right spot in that final word list, we need to count
// not just real words but these break tokens too, or the estimate drifts
// further off the deeper into the book a chapter is (dialogue-heavy text
// splits into many short paragraphs, so this isn't a rare edge case here).
int _countParagraphs(String text) =>
    text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;

T? _firstOrNull<T>(Iterable<T> iterable) => iterable.isEmpty ? null : iterable.first;

// FB2 paragraph-level text isn't only <p> - poetry lines live in <v>
// (never <p>), plus <subtitle>, <text-author> (spoken/sung attribution),
// and <code>. Missing these used to mean e.g. a poem embedded in a novel
// silently vanished from the extracted text. Walks [root] in document
// order, not descending into a matched element's own children since none
// of these tags nest further in FB2.
const _fb2ParagraphTags = {'p', 'v', 'subtitle', 'text-author', 'code'};

List<XmlElement> _fb2ParagraphElements(XmlElement root) {
  final result = <XmlElement>[];
  void visit(XmlElement element) {
    if (_fb2ParagraphTags.contains(element.name.local)) {
      result.add(element);
      return;
    }
    for (final child in element.childElements) {
      visit(child);
    }
  }
  visit(root);
  return result;
}

// Treats a blank/whitespace-only string the same as absent - metadata
// fields are often present in the file but empty.
String? _orNull(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

const _emptyMetadata = (
  title: null,
  author: null,
  description: null,
  language: null,
  coverImageBase64: null,
  chapters: <Chapter>[],
);

class LibraryLocalDataSource {

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) {
      return null;
    }
    return result.files.single;
  }

  //pdf
  Future<String> extractPdfText(String filePath) async
  {
    final bytes = await File(filePath).readAsBytes(); // opens the file as bites and reads raw conetent

    final document = PdfDocument(inputBytes: bytes); //hand those bytes to Syncfusion so it can open the PDF

    final text = PdfTextExtractor(document).extractText(); //extract the text from that document

    document.dispose();
    return text;

  }

  // txt
  Future<String> extractTxtText(String filePath) async {
    return File(filePath).readAsString();
  }

  //epub
  Future<String> extractEpubText(String filePath) async{
    final bytes = await File(filePath).readAsBytes();
    final book = await EpubReader.readBook(bytes);

    final chapterHtml = _epubChapterHtml(book);

    // Self-calibrating fallback: the chapter walk has better fidelity and
    // ordering when it works, but if it captured less than half of what's
    // actually sitting in the epub's HTML resources - some TOC/spine shape
    // epubx's chapter builder doesn't handle, the same family of bug as
    // the SubChapters case above but for whatever we haven't seen yet -
    // fall back to every HTML file in the epub instead of silently
    // returning a near-empty book. Order isn't guaranteed to match spine
    // order here, but a complete book in a slightly odd order beats a
    // 3-page book.
    final allHtml = book.Content?.Html?.values.map((f) => f.Content ?? '').join('\n') ?? '';
    final raw = chapterHtml.length < allHtml.length * 0.5 ? allHtml : chapterHtml;

    return htmlToPlainText(raw);
  }

  // Recurses into SubChapters - epubx mirrors the TOC's nesting, so a book
  // with a "Part I / Chapter 1..6" structure has the actual prose sitting
  // under SubChapters, not in book.Chapters directly.
  String _epubChapterHtml(EpubBook book) {
    final buffer = StringBuffer();
    void visit(EpubChapter chapter) {
      buffer.writeln(chapter.HtmlContent ?? '');
      for (final sub in chapter.SubChapters ?? const <EpubChapter>[]) {
        visit(sub);
      }
    }
    for (final chapter in book.Chapters ?? const <EpubChapter>[]) {
      visit(chapter);
    }
    return buffer.toString();
  }

  // epub metadata: title/author/description/language (Dublin Core), cover
  // (epubx decodes it to raw pixels - no way to get the original file
  // bytes back, so it's re-encoded to JPEG), and chapter headings with an
  // approximate word index each. Reuses the one parsed EpubBook for all of
  // it instead of parsing the file separately per field.
  Future<BookMetadata> extractEpubMetadata(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final book = await EpubReader.readBook(bytes);
      final metadata = book.Schema?.Package?.Metadata;

      final cover = book.CoverImage;
      final coverImageBase64 = cover == null ? null : base64Encode(img.encodeJpg(cover, quality: 85));

      // Word index is counted from each chapter's own plain text in the
      // same document order splitIntoWords will eventually see them in -
      // not exact once normalizeExtractedText reflows things, but close
      // enough to force a page break at.
      final chapters = <Chapter>[];
      var wordCount = 0;
      var paragraphCount = 0;
      void visit(EpubChapter chapter) {
        final chapterTitle = _orNull(chapter.Title);
        if (chapterTitle != null) {
          chapters.add(Chapter(title: chapterTitle, wordIndex: wordCount + paragraphCount));
        }
        final plainText = htmlToPlainText(chapter.HtmlContent ?? '');
        wordCount += _countWords(plainText);
        paragraphCount += _countParagraphs(plainText);
        for (final sub in chapter.SubChapters ?? const <EpubChapter>[]) {
          visit(sub);
        }
      }
      for (final chapter in book.Chapters ?? const <EpubChapter>[]) {
        visit(chapter);
      }

      return (
        title: _orNull(book.Title),
        author: _orNull(book.Author),
        description: _orNull(metadata?.Description),
        language: _orNull(_firstOrNull(metadata?.Languages ?? const <String>[])),
        coverImageBase64: coverImageBase64,
        chapters: chapters,
      );
    } catch (_) {
      return _emptyMetadata;
    }
  }

  //mobi
  Future<String> extractMobiText(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final book = KindleBook.fromBytes(bytes);
    final buffer = StringBuffer();
    for (final part in book.parts) {
      buffer.writeln(utf8.decode(part.bytes, allowMalformed: true));
    }

    return htmlToPlainText(buffer.toString());
  }

  // mobi metadata: title (EXTH 503, falling back to the MOBI header's
  // fullName - see KindleBook.title), author/description/language (EXTH),
  // and cover - kindle_unpack already hands back the original image bytes
  // (whatever format the file used), so no re-encoding needed. SVG covers
  // aren't renderable by Image.memory, so those are treated as no cover.
  // kindle_unpack doesn't expose a clean chapter/TOC structure (its
  // parts/flows are raw content segments, not headings), so chapters is
  // always empty here.
  Future<BookMetadata> extractMobiMetadata(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final book = KindleBook.fromBytes(bytes);
      final exth = book.exth;

      final cover = book.images.cover;
      final coverImageBase64 =
          (cover == null || cover.format == ImageFormat.svg) ? null : base64Encode(cover.data);

      return (
        title: _orNull(book.title),
        author: _orNull(_firstOrNull(exth?.authors ?? const <String>[])),
        description: _orNull(exth?.description),
        language: _orNull(exth?.language),
        coverImageBase64: coverImageBase64,
        chapters: const <Chapter>[],
      );
    } catch (_) {
      return _emptyMetadata;
    }
  }

  //fb2
  Future<String> extractFb2Text(String filePath) async {
    final content = await File(filePath).readAsString();
    final document = XmlDocument.parse(content);

    final paragraphs = _fb2ParagraphElements(document.rootElement)
        .map((p) => p.innerText.trim())
        .where((p) => p.isNotEmpty);

    return paragraphs.join('\n\n');
  }

  // fb2 metadata: everything lives in <description><title-info> as plain
  // structured XML - book-title, author name, lang, and an annotation
  // (description) made of its own <p>s. Cover is <coverpage><image
  // href="#id"/> pointing at a <binary id="id"> that already holds the
  // image base64-encoded right in the XML, so it's just copied through.
  // Chapters walk <section><title> under every non-notes <body>, counting
  // words the same way extractFb2Text's flat <p> search does so the
  // indices land in roughly the same place.
  Future<BookMetadata> extractFb2Metadata(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      final document = XmlDocument.parse(content);

      final titleInfo = _firstOrNull(document.findAllElements('title-info'));

      final title =
          _orNull(_firstOrNull(titleInfo?.findElements('book-title') ?? const <XmlElement>[])?.innerText);

      final language =
          _orNull(_firstOrNull(titleInfo?.findElements('lang') ?? const <XmlElement>[])?.innerText);

      final authorEl = _firstOrNull(titleInfo?.findElements('author') ?? const <XmlElement>[]);
      final authorName = authorEl == null
          ? null
          : [
              _orNull(_firstOrNull(authorEl.findElements('first-name'))?.innerText),
              _orNull(_firstOrNull(authorEl.findElements('last-name'))?.innerText),
            ].whereType<String>().join(' ');

      final annotationParagraphs =
          _firstOrNull(titleInfo?.findElements('annotation') ?? const <XmlElement>[])
              ?.findElements('p')
              .map((p) => p.innerText.trim())
              .where((p) => p.isNotEmpty)
              .join(' ') ??
          '';

      String? coverImageBase64;
      final coverImages =
          document.findAllElements('coverpage').expand((coverpage) => coverpage.findElements('image'));
      if (coverImages.isNotEmpty) {
        final hrefAttrs = coverImages.first.attributes.where((a) => a.name.local == 'href');
        if (hrefAttrs.isNotEmpty) {
          final href = hrefAttrs.first.value;
          final id = href.startsWith('#') ? href.substring(1) : href;
          final binaries = document.findAllElements('binary').where((b) => b.getAttribute('id') == id);
          coverImageBase64 = _orNull(_firstOrNull(binaries)?.innerText);
        }
      }

      final chapters = <Chapter>[];
      var wordCount = 0;
      var paragraphCount = 0;

      // Every paragraph-bearing element here (whatever it's nested under -
      // title, epigraph, subtitle, verse, a section's own body text)
      // becomes its own paragraph in extractFb2Text's flat join, each
      // preceded by one paragraphBreak token once split into words - so
      // word/paragraph counts have to treat them all uniformly to land on
      // the right index.
      void countParagraphsIn(XmlElement element) {
        for (final p in _fb2ParagraphElements(element)) {
          wordCount += _countWords(p.innerText);
          paragraphCount += 1;
        }
      }

      void visitSection(XmlElement section) {
        final titleEl = _firstOrNull(section.findElements('title'));
        if (titleEl != null) {
          final sectionTitle = titleEl
              .findElements('p')
              .map((p) => p.innerText.trim())
              .where((t) => t.isNotEmpty)
              .join(' ');
          if (sectionTitle.isNotEmpty) {
            chapters.add(Chapter(title: sectionTitle, wordIndex: wordCount + paragraphCount));
          }
        }

        for (final child in section.childElements) {
          if (child.name.local == 'section') {
            visitSection(child);
          } else {
            countParagraphsIn(child);
          }
        }
      }

      final bodies = document.findAllElements('body').where((b) => b.getAttribute('name') != 'notes');
      for (final body in bodies) {
        for (final section in body.findElements('section')) {
          visitSection(section);
        }
      }

      return (
        title: title,
        author: _orNull(authorName),
        description: _orNull(annotationParagraphs),
        language: language,
        coverImageBase64: coverImageBase64,
        chapters: chapters,
      );
    } catch (_) {
      return _emptyMetadata;
    }
  }
}
