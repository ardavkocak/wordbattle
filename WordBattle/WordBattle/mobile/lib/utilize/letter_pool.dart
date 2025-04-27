import 'dart:math';

class LetterPool {
  static final List<String> _pool = _createPool();

  static List<String> _createPool() {
    List<String> letters = [];

    void addLetters(String letter, int count) {
      for (int i = 0; i < count; i++) {
        letters.add(letter);
      }
    }

    addLetters('A', 12);
    addLetters('B', 2);
    addLetters('C', 2);
    addLetters('Ç', 2);
    addLetters('D', 3);
    addLetters('E', 8);
    addLetters('F', 2);
    addLetters('G', 3);
    addLetters('Ğ', 1);
    addLetters('H', 1);
    addLetters('I', 6);
    addLetters('İ', 4);
    addLetters('J', 1);
    addLetters('K', 7);
    addLetters('L', 5);
    addLetters('M', 4);
    addLetters('N', 7);
    addLetters('O', 3);
    addLetters('Ö', 1);
    addLetters('P', 2);
    addLetters('R', 6);
    addLetters('S', 5);
    addLetters('Ş', 2);
    addLetters('T', 5);
    addLetters('U', 3);
    addLetters('Ü', 2);
    addLetters('V', 2);
    addLetters('Y', 3);
    addLetters('Z', 2);

    return letters;
  }

  static List<String> drawLetters(int count) {
    final random = Random();
    List<String> copyPool = List.from(_pool);
    List<String> drawn = [];

    for (int i = 0; i < count; i++) {
      if (copyPool.isEmpty) break;
      int index = random.nextInt(copyPool.length);
      drawn.add(copyPool.removeAt(index));
    }

    return drawn;
  }
}
