

int estimateCharacterBudget({
  required double containerWidth,
  required double containerHeight,
  required double fontSize,
  double runSpacing = 12, // must match the Wrap's runSpacing in reader_view.dart
  double wordSpacing = 8, // must match the Wrap's spacing in reader_view.dart
  TextScript script = TextScript.latin,

}){

  final avgCharaWidth = switch(script){
    TextScript.latin => fontSize * 0.5,
    TextScript.cyrillic => fontSize * 0.58,
  };

  final wordLineHeight = fontSize * 1.2;
  final translationLineHeight = fontSize * 0.7 * 1.2;
  final worstCaseRowHeight = wordLineHeight + translationLineHeight;
  final rowPitch = worstCaseRowHeight + runSpacing; // each row also pays the gap below it

  // pageingWords charges each word (length + 1) budget-chars. Price that unit in
  // real pixels: an average word costs avgWordLength chars of glyphs plus the
  // Wrap's fixed pixel gap - not one glyph-width, which only matches at fontSize 16.
  const avgWordLength = 5;
  final pxPerBudgetChar =
      (avgWordLength * avgCharaWidth + wordSpacing) / (avgWordLength + 1);

  final charsPerLine = containerWidth / pxPerBudgetChar;
  // Whole rows only: budgeting a fractional row spends characters that wrap
  // onto a real extra row the height math never reserved.
  final linesPerPage =
      ((containerHeight - worstCaseRowHeight) / rowPitch).floor();

  return (charsPerLine * linesPerPage).floor();


}

enum TextScript
{
  latin,
  cyrillic

}