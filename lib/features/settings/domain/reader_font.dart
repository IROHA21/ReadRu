import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// All ten have solid Cyrillic glyph coverage via google_fonts - required
// since this app reads Russian text, and not every Google Font ships one.
// Picked to actually look distinct from one another, not just be different
// names for similar-looking sans faces.
enum ReaderFont {
  roboto,
  ptSerif,
  openSans,
  lora,
  ubuntu,
  ptSans,
  ptMono,
  comfortaa,
  caveat,
  oswald;

  String get label => switch (this) {
        ReaderFont.roboto => 'Roboto',
        ReaderFont.ptSerif => 'PT Serif',
        ReaderFont.openSans => 'Open Sans',
        ReaderFont.lora => 'Lora',
        ReaderFont.ubuntu => 'Ubuntu',
        ReaderFont.ptSans => 'PT Sans',
        ReaderFont.ptMono => 'PT Mono',
        ReaderFont.comfortaa => 'Comfortaa',
        ReaderFont.caveat => 'Caveat',
        ReaderFont.oswald => 'Oswald',
      };

  // Builds a TextStyle through google_fonts for this family, merged onto
  // [textStyle] - callers pass the same base style (size/height/spacing/color)
  // they'd use for a plain TextStyle so measurer and widget stay in sync.
  TextStyle apply(TextStyle textStyle) => switch (this) {
        ReaderFont.roboto => GoogleFonts.roboto(textStyle: textStyle),
        ReaderFont.ptSerif => GoogleFonts.ptSerif(textStyle: textStyle),
        ReaderFont.openSans => GoogleFonts.openSans(textStyle: textStyle),
        ReaderFont.lora => GoogleFonts.lora(textStyle: textStyle),
        ReaderFont.ubuntu => GoogleFonts.ubuntu(textStyle: textStyle),
        ReaderFont.ptSans => GoogleFonts.ptSans(textStyle: textStyle),
        ReaderFont.ptMono => GoogleFonts.ptMono(textStyle: textStyle),
        ReaderFont.comfortaa => GoogleFonts.comfortaa(textStyle: textStyle),
        ReaderFont.caveat => GoogleFonts.caveat(textStyle: textStyle),
        ReaderFont.oswald => GoogleFonts.oswald(textStyle: textStyle),
      };
}
