

List<List<String>> pageingWords(List<String> words, int characterBudget){

  final pages = <List<String>>[]; // a list of strings with our words currently empty
  var currentPage = <String>[];   // one page the current one
  var currentLength = 0;


  for (final word in words){
    if (currentPage.isNotEmpty && currentLength + word.length + 1 > characterBudget ){

      pages.add(currentPage);
      currentPage = <String>[];
      currentLength = 0;
    }

    currentPage.add(word);
    currentLength += word.length + 1;


  }

  if (currentPage.isNotEmpty){

    pages.add(currentPage);
  }

  return pages;


}