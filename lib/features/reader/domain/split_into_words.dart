


List <String> splitIntoWords(String text){

  return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  //RegExp(r'\s+') for white spaces
  // .where((word) => word.isNotEmpty) for safety

}