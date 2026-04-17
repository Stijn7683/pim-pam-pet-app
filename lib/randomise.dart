import 'dart:math';

final List<String> onderwerpen = ['natuurproduct', 'bloem', 'vis', 'deel van het menselijk lichaam', 'keuken gereedschap', 'jongensnaam', 'meisjesnaam', 'stad in Europa', '.iets in een boerderij', 'dier', 'schilder / beeldhouwer', 'groente', 'schrijver / dichter', 'berg / bergketen', 'kanaal / rivier', 'muziekinstrument', 'kledingstuk', 'boom', '.voedsel voor mensen', 'gereedschap', 'huiskamer voorwerp', 'vogel', 'schoolvak', '.iets voor op brood', 'beroep'];
final List<String> letters = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','R','S','T','U','V','W',];
final _random = Random();

(String, String, bool) randomise() {
  String randomLetter = letters[_random.nextInt(letters.length)];
  String subject = onderwerpen[_random.nextInt(onderwerpen.length)];
  bool noArticle = false;
  if (subject.startsWith('.')) {
    subject = subject.substring(1);
    noArticle = true;
  }
  if (subject.contains('/')) {
    final List<String> options = subject.split('/');
    options.shuffle();
    subject = options.join(' of ');
  }
  return (randomLetter, subject, noArticle);
}